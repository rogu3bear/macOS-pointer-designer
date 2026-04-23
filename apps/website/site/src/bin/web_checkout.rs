use std::{
    collections::{hash_map::DefaultHasher, HashMap},
    error::Error as StdError,
    fs,
    hash::{Hash, Hasher},
    net::{IpAddr, SocketAddr, ToSocketAddrs},
    path::{Path, PathBuf},
    process::Stdio,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use axum::{
    extract::{ConnectInfo, Query, State},
    http::{HeaderMap, StatusCode},
    response::{IntoResponse, Redirect, Response},
    Json,
};
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use chrono::Utc;
use p256::{
    ecdsa::{signature::Signer, signature::Verifier, Signature, SigningKey, VerifyingKey},
    pkcs8::DecodePrivateKey,
};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use tokio::{io::AsyncWriteExt, process::Command};

use super::email::EmailService;
use super::web_license::{
    ApiErrorResponse, WebLicenseActivationRequest, WebLicensePayload, WebLicenseRecoveryRequest,
    WebLicenseRecoveryResponse, WebLicenseResponse, WEB_LICENSE_KIND, WEB_LICENSE_PLAN_LIFETIME,
    WEB_LICENSE_PRICE_CENTS, WEB_LICENSE_PRICE_LABEL,
};

const RECOVERY_EMAIL_COOLDOWN: Duration = Duration::from_secs(10 * 60);
const RECOVERY_CLIENT_COOLDOWN: Duration = Duration::from_secs(60);
const RECOVERY_LEDGER_TTL: Duration = Duration::from_secs(60 * 60);
const LICENSE_LEASE_DURATION: Duration = Duration::from_secs(30 * 24 * 60 * 60);
const RECOVERY_GENERIC_MESSAGE: &str =
    "If we found a completed WindowDrop purchase for that address, we sent a recovery email with the activation link and code.";

#[derive(Clone)]
pub struct WebCheckoutState {
    inner: Arc<Result<WebCheckoutService, String>>,
    email: Option<EmailService>,
    recovery_guard: Arc<RecoveryAbuseGuard>,
    activation_registry: Arc<ActivationRegistry>,
}

impl WebCheckoutState {
    pub fn from_env() -> Self {
        let inner = WebCheckoutService::from_env()
            .map_err(|error| format!("Web checkout unavailable: {error}"));
        let email = EmailService::from_env();
        if email.is_none() {
            tracing::warn!("RESEND_API_KEY not set — license emails will not be sent");
        }
        Self {
            inner: Arc::new(inner),
            email,
            recovery_guard: Arc::new(RecoveryAbuseGuard::default()),
            activation_registry: Arc::new(ActivationRegistry::from_env()),
        }
    }

    fn service(&self) -> Result<&WebCheckoutService, ApiError> {
        self.inner.as_ref().as_ref().map_err(|message| ApiError {
            status: StatusCode::SERVICE_UNAVAILABLE,
            message: message.clone(),
        })
    }

    fn send_license_email_async(&self, response: &WebLicenseResponse) {
        if let Some(email_service) = &self.email {
            let email_service = email_service.clone();
            let response = response.clone();
            tokio::spawn(async move {
                email_service.send_license_email(&response).await;
            });
        }
    }

    fn email_service(&self) -> Result<&EmailService, ApiError> {
        self.email.as_ref().ok_or_else(|| ApiError {
            status: StatusCode::SERVICE_UNAVAILABLE,
            message: "License recovery email is temporarily unavailable.".to_string(),
        })
    }
}

#[derive(Debug, Clone)]
pub(crate) struct ApiError {
    status: StatusCode,
    message: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (
            self.status,
            Json(ApiErrorResponse {
                error: self.message,
            }),
        )
            .into_response()
    }
}

#[derive(Clone)]
struct WebCheckoutService {
    client: Client,
    stripe_api_key: String,
    site_url: String,
    download_url: String,
    signing_key: SigningKey,
}

#[derive(Default)]
struct ActivationRegistry {
    path: Option<PathBuf>,
    inner: Mutex<ActivationRegistryState>,
}

#[derive(Default, Serialize, Deserialize)]
struct ActivationRegistryState {
    sessions: HashMap<String, ActivationRecord>,
}

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq, Eq)]
struct ActivationRecord {
    device_id: String,
    email: String,
    first_activated_at: i64,
    last_renewed_at: i64,
    revoked_at: Option<i64>,
    revoked_reason: Option<String>,
}

#[derive(Default)]
struct RecoveryAbuseGuard {
    inner: Mutex<RecoveryAbuseLedger>,
}

#[derive(Default)]
struct RecoveryAbuseLedger {
    email_next_allowed_at: HashMap<String, Instant>,
    client_next_allowed_at: HashMap<String, Instant>,
}

struct RecoveryDecision {
    allowed: bool,
    email_fingerprint: String,
    client_fingerprint: String,
}

impl RecoveryAbuseGuard {
    fn check_and_record(&self, email: &str, client_scope: &str, now: Instant) -> RecoveryDecision {
        let mut ledger = self
            .inner
            .lock()
            .expect("recovery abuse guard mutex poisoned");
        ledger.prune(now);

        let normalized_email = normalize_email(email);
        let email_allowed = ledger
            .email_next_allowed_at
            .get(&normalized_email)
            .is_none_or(|deadline| *deadline <= now);
        let client_allowed = ledger
            .client_next_allowed_at
            .get(client_scope)
            .is_none_or(|deadline| *deadline <= now);
        let allowed = email_allowed && client_allowed;

        if allowed {
            ledger
                .email_next_allowed_at
                .insert(normalized_email.clone(), now + RECOVERY_EMAIL_COOLDOWN);
            ledger
                .client_next_allowed_at
                .insert(client_scope.to_string(), now + RECOVERY_CLIENT_COOLDOWN);
        }

        RecoveryDecision {
            allowed,
            email_fingerprint: fingerprint(&normalized_email),
            client_fingerprint: fingerprint(client_scope),
        }
    }
}

impl RecoveryAbuseLedger {
    fn prune(&mut self, now: Instant) {
        self.email_next_allowed_at
            .retain(|_, deadline| now.duration_since(*deadline) <= RECOVERY_LEDGER_TTL);
        self.client_next_allowed_at
            .retain(|_, deadline| now.duration_since(*deadline) <= RECOVERY_LEDGER_TTL);
    }
}

impl ActivationRegistry {
    fn from_env() -> Self {
        let path = std::env::var("WINDOWDROP_WEB_LICENSE_REGISTRY_PATH")
            .ok()
            .map(|value| value.trim().to_string())
            .filter(|value| !value.is_empty())
            .map(PathBuf::from)
            .or_else(|| Some(PathBuf::from("var/web-license-activations.json")));
        let state = match path.as_ref() {
            Some(path) => match load_activation_registry_state(path.as_path()) {
                Ok(state) => state,
                Err(error) => {
                    tracing::warn!(error = %error, "Failed to load activation registry; starting empty");
                    ActivationRegistryState::default()
                }
            },
            None => ActivationRegistryState::default(),
        };

        Self {
            path,
            inner: Mutex::new(state),
        }
    }

    fn bind_or_renew(
        &self,
        session_id: &str,
        email: &str,
        device_id: &str,
        now: i64,
    ) -> Result<(), String> {
        let mut state = self
            .inner
            .lock()
            .expect("activation registry mutex poisoned");
        self.reload_from_disk(&mut state)?;
        match state.sessions.get_mut(session_id) {
            Some(record) if record.revoked_at.is_some() => {
                return Err("This web purchase has been revoked.".to_string());
            }
            Some(record) if record.device_id == device_id => {
                record.last_renewed_at = now;
            }
            Some(_) => {
                return Err("This web purchase is already activated on another Mac.".to_string());
            }
            None => {
                state.sessions.insert(
                    session_id.to_string(),
                    ActivationRecord {
                        device_id: device_id.to_string(),
                        email: email.to_string(),
                        first_activated_at: now,
                        last_renewed_at: now,
                        revoked_at: None,
                        revoked_reason: None,
                    },
                );
            }
        }

        self.persist(&state)?;
        Ok(())
    }

    fn reload_from_disk(&self, state: &mut ActivationRegistryState) -> Result<(), String> {
        let Some(path) = &self.path else {
            return Ok(());
        };
        *state = load_activation_registry_state(path.as_path())?;
        Ok(())
    }

    fn persist(&self, state: &ActivationRegistryState) -> Result<(), String> {
        let Some(path) = &self.path else {
            return Ok(());
        };
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|error| {
                format!("Failed to create activation registry directory: {error}")
            })?;
        }
        let body = serde_json::to_vec_pretty(state)
            .map_err(|_| "Failed to encode activation registry.".to_string())?;
        fs::write(path, body)
            .map_err(|error| format!("Failed to persist activation registry: {error}"))
    }
}

fn load_activation_registry_state(path: &Path) -> Result<ActivationRegistryState, String> {
    if !path.exists() {
        return Ok(ActivationRegistryState::default());
    }
    let body = fs::read(path).map_err(|error| {
        format!(
            "Failed to read activation registry {}: {error}",
            path.display()
        )
    })?;
    serde_json::from_slice(&body).map_err(|_| {
        format!(
            "Activation registry at {} is not valid JSON.",
            path.display()
        )
    })
}

impl WebCheckoutService {
    fn from_env() -> Result<Self, String> {
        let stripe_api_key = std::env::var("STRIPE_API_KEY")
            .map(|value| value.trim().to_string())
            .map_err(|_| "Missing STRIPE_API_KEY.".to_string())?;
        let private_key_path = std::env::var("WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH")
            .map(|value| value.trim().to_string())
            .map_err(|_| "Missing WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH.".to_string())?;
        let private_key_pem = fs::read_to_string(&private_key_path)
            .map_err(|_| format!("Could not read signing key at {private_key_path}."))?;
        let signing_key = SigningKey::from_pkcs8_pem(&private_key_pem)
            .map_err(|_| "Signing key is not a valid P-256 PKCS#8 PEM.".to_string())?;
        let site_url = std::env::var("WINDOWDROP_SITE_URL")
            .unwrap_or_else(|_| "https://windowdrop.pro".to_string())
            .trim()
            .trim_end_matches('/')
            .to_string();
        let download_url = format!("{site_url}/download");
        let stripe_addrs: Vec<_> = ("api.stripe.com", 443)
            .to_socket_addrs()
            .map_err(|_| "Failed to resolve api.stripe.com.".to_string())?
            .collect();
        if stripe_addrs.is_empty() {
            return Err("Failed to resolve api.stripe.com.".to_string());
        }
        let client = Client::builder()
            .connect_timeout(Duration::from_secs(5))
            .http1_only()
            .timeout(Duration::from_secs(20))
            .resolve_to_addrs("api.stripe.com", &stripe_addrs)
            .build()
            .map_err(|_| "Failed to initialize the Stripe client.".to_string())?;

        Ok(Self {
            client,
            stripe_api_key,
            site_url,
            download_url,
            signing_key,
        })
    }

    async fn create_lifetime_checkout(&self) -> Result<String, String> {
        let success_url = format!(
            "{}/checkout/success?session_id={{CHECKOUT_SESSION_ID}}",
            self.site_url
        );
        let cancel_url = format!("{}/pricing?checkout=cancelled", self.site_url);
        let params = vec![
            ("mode", "payment".to_string()),
            ("success_url", success_url),
            ("cancel_url", cancel_url),
            ("customer_creation", "always".to_string()),
            ("allow_promotion_codes", "true".to_string()),
            ("line_items[0][quantity]", "1".to_string()),
            ("line_items[0][price_data][currency]", "usd".to_string()),
            (
                "line_items[0][price_data][unit_amount]",
                WEB_LICENSE_PRICE_CENTS.to_string(),
            ),
            (
                "line_items[0][price_data][product_data][name]",
                "WindowDrop Lifetime Unlock".to_string(),
            ),
            (
                "line_items[0][price_data][product_data][description]",
                "Lifetime unlock for all supported WindowDrop app targets.".to_string(),
            ),
            (
                "metadata[windowdrop_plan]",
                WEB_LICENSE_PLAN_LIFETIME.to_string(),
            ),
        ];

        let session: StripeCreateSessionResponse = match self
            .client
            .post("https://api.stripe.com/v1/checkout/sessions")
            .bearer_auth(&self.stripe_api_key)
            .form(&params)
            .send()
            .await
        {
            Ok(response) => {
                if !response.status().is_success() {
                    return Err(stripe_error_message(response).await);
                }
                response
                    .json()
                    .await
                    .map_err(|_| "Stripe returned an unreadable checkout session.".to_string())?
            }
            Err(error) => {
                let json = self
                    .curl_form_json("https://api.stripe.com/v1/checkout/sessions", &params)
                    .await
                    .map_err(|curl_error| {
                        format!(
                            "{}; curl fallback failed: {curl_error}",
                            format_reqwest_error("Failed to reach Stripe Checkout", &error)
                        )
                    })?;
                serde_json::from_value(json)
                    .map_err(|_| "Stripe returned an unreadable checkout session.".to_string())?
            }
        };

        session
            .url
            .ok_or_else(|| "Stripe did not return a checkout URL.".to_string())
    }

    async fn load_completed_session(
        &self,
        session_id: &str,
    ) -> Result<StripeCheckoutSession, String> {
        let url = format!("https://api.stripe.com/v1/checkout/sessions/{session_id}");
        let session: StripeCheckoutSession = match self
            .client
            .get(&url)
            .bearer_auth(&self.stripe_api_key)
            .send()
            .await
        {
            Ok(response) => {
                if !response.status().is_success() {
                    return Err(stripe_error_message(response).await);
                }
                response
                    .json()
                    .await
                    .map_err(|_| "Stripe returned an unreadable checkout session.".to_string())?
            }
            Err(error) => {
                let json = self
                    .curl_query_json(&url, &[])
                    .await
                    .map_err(|curl_error| {
                        format!(
                            "{}; curl fallback failed: {curl_error}",
                            format_reqwest_error(
                                "Failed to verify the Stripe checkout session",
                                &error
                            )
                        )
                    })?;
                serde_json::from_value(json)
                    .map_err(|_| "Stripe returned an unreadable checkout session.".to_string())?
            }
        };

        if !session.is_completed_lifetime_purchase() {
            return Err(
                "Checkout session is not a completed paid WindowDrop lifetime purchase."
                    .to_string(),
            );
        }

        Ok(session)
    }

    async fn recover_completed_session(
        &self,
        email: &str,
    ) -> Result<StripeCheckoutSession, String> {
        let sessions: StripeCheckoutSessionList = match self
            .client
            .get("https://api.stripe.com/v1/checkout/sessions")
            .bearer_auth(&self.stripe_api_key)
            .query(&[("limit", "20"), ("customer_details[email]", email)])
            .send()
            .await
        {
            Ok(response) => {
                if !response.status().is_success() {
                    return Err(stripe_error_message(response).await);
                }
                response
                    .json()
                    .await
                    .map_err(|_| "Stripe returned an unreadable recovery response.".to_string())?
            }
            Err(error) => {
                let json = self
                    .curl_query_json(
                        "https://api.stripe.com/v1/checkout/sessions",
                        &[("limit", "20"), ("customer_details[email]", email)],
                    )
                    .await
                    .map_err(|curl_error| {
                        format!(
                            "{}; curl fallback failed: {curl_error}",
                            format_reqwest_error(
                                "Failed to query Stripe for previous purchases",
                                &error
                            )
                        )
                    })?;
                serde_json::from_value(json)
                    .map_err(|_| "Stripe returned an unreadable recovery response.".to_string())?
            }
        };

        sessions
            .data
            .into_iter()
            .filter(|session| session.is_completed_lifetime_purchase())
            .max_by_key(|session| session.created.unwrap_or_default())
            .ok_or_else(|| {
                "No completed WindowDrop lifetime purchase was found for that email address."
                    .to_string()
            })
    }

    fn issue_purchase_proof(
        &self,
        session: &StripeCheckoutSession,
    ) -> Result<WebLicenseResponse, String> {
        let email = session
            .customer_details
            .as_ref()
            .and_then(|details| details.email.clone())
            .ok_or_else(|| "Stripe checkout session is missing a customer email.".to_string())?;
        let payload = WebLicensePayload::purchase_proof(
            email.clone(),
            session.id.clone(),
            session.created.unwrap_or_else(|| Utc::now().timestamp()),
        );
        let license_token = self.sign_payload(&payload)?;

        Ok(WebLicenseResponse {
            status: "verified".to_string(),
            email,
            plan: WEB_LICENSE_PLAN_LIFETIME.to_string(),
            price_label: WEB_LICENSE_PRICE_LABEL.to_string(),
            activation_url: format!("windowdrop://activate?license={license_token}"),
            download_url: self.download_url.clone(),
            license_token,
        })
    }

    fn issue_device_license(
        &self,
        session: &StripeCheckoutSession,
        device_id: &str,
        now: i64,
    ) -> Result<WebLicenseResponse, String> {
        let email = session
            .customer_details
            .as_ref()
            .and_then(|details| details.email.clone())
            .ok_or_else(|| "Stripe checkout session is missing a customer email.".to_string())?;
        let expires_at = now + LICENSE_LEASE_DURATION.as_secs() as i64;
        let payload = WebLicensePayload::leased_device_license(
            email.clone(),
            session.id.clone(),
            now,
            expires_at,
            device_id.to_string(),
        );
        let license_token = self.sign_payload(&payload)?;

        Ok(WebLicenseResponse {
            status: "activated".to_string(),
            email,
            plan: WEB_LICENSE_PLAN_LIFETIME.to_string(),
            price_label: WEB_LICENSE_PRICE_LABEL.to_string(),
            activation_url: format!("windowdrop://activate?license={license_token}"),
            download_url: self.download_url.clone(),
            license_token,
        })
    }

    fn sign_payload(&self, payload: &WebLicensePayload) -> Result<String, String> {
        let payload_json = serde_json::to_vec(&payload)
            .map_err(|_| "Failed to encode the activation payload.".to_string())?;
        let signature: Signature = self.signing_key.sign(&payload_json);
        Ok(format!(
            "wdl1.{}.{}",
            URL_SAFE_NO_PAD.encode(payload_json),
            URL_SAFE_NO_PAD.encode(signature.to_der().as_bytes())
        ))
    }

    fn decode_signed_payload(
        &self,
        token: &str,
        allow_expired: bool,
    ) -> Result<WebLicensePayload, String> {
        let (payload_data, signature_data) = decode_license_segments(token)?;
        let signature = decode_license_signature(&signature_data)?;
        let verifying_key: VerifyingKey = *self.signing_key.verifying_key();
        verifying_key
            .verify(&payload_data, &signature)
            .map_err(|_| "Activation token signature is invalid.".to_string())?;
        let payload: WebLicensePayload = serde_json::from_slice(&payload_data)
            .map_err(|_| "Activation token payload is invalid.".to_string())?;
        validate_license_payload(&payload, allow_expired)?;
        Ok(payload)
    }

    async fn curl_form_json(
        &self,
        url: &str,
        params: &[(&str, String)],
    ) -> Result<serde_json::Value, String> {
        let encoded_params: Vec<_> = params
            .iter()
            .map(|(key, value)| (key.to_string(), value.clone()))
            .collect();
        self.curl_json("POST", url, &encoded_params).await
    }

    async fn curl_query_json(
        &self,
        url: &str,
        params: &[(&str, &str)],
    ) -> Result<serde_json::Value, String> {
        let encoded_params: Vec<_> = params
            .iter()
            .map(|(key, value)| (key.to_string(), value.to_string()))
            .collect();
        self.curl_json("GET", url, &encoded_params).await
    }

    async fn curl_json(
        &self,
        method: &str,
        url: &str,
        params: &[(String, String)],
    ) -> Result<serde_json::Value, String> {
        let mut config = String::new();
        config.push_str(&format!("url = \"{}\"\n", escape_curl_config(url)));
        config.push_str("silent\nshow-error\n");
        config.push_str("connect-timeout = 5\nmax-time = 25\n");
        config.push_str(&format!(
            "user = \"{}:\"\n",
            escape_curl_config(&self.stripe_api_key)
        ));
        config.push_str("write-out = \"\\n__WINDOWDROP_STATUS__:%{http_code}\"\n");
        if method == "GET" {
            config.push_str("get\n");
        }
        for (key, value) in params {
            config.push_str(&format!(
                "data-urlencode = \"{}={}\"\n",
                escape_curl_config(key),
                escape_curl_config(value)
            ));
        }

        let mut child = Command::new("curl")
            .arg("--config")
            .arg("-")
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|error| format!("Failed to launch curl: {error}"))?;

        if let Some(mut stdin) = child.stdin.take() {
            stdin
                .write_all(config.as_bytes())
                .await
                .map_err(|error| format!("Failed to send curl config: {error}"))?;
        }

        let output = child
            .wait_with_output()
            .await
            .map_err(|error| format!("curl execution failed: {error}"))?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            return Err(if stderr.is_empty() {
                format!("curl exited with status {}.", output.status)
            } else {
                format!("curl failed: {stderr}")
            });
        }

        let stdout = String::from_utf8(output.stdout)
            .map_err(|_| "curl returned non-UTF-8 output.".to_string())?;
        let (body, status) = split_curl_status(&stdout)?;
        let json: serde_json::Value = serde_json::from_str(body)
            .map_err(|_| "Stripe returned unreadable JSON.".to_string())?;

        if (200..300).contains(&status) {
            Ok(json)
        } else {
            Err(stripe_error_message_from_value(status, &json))
        }
    }
}

pub(crate) async fn lifetime_checkout(
    State(state): State<WebCheckoutState>,
) -> Result<Redirect, ApiError> {
    let service = state.service()?;
    let checkout_url = service
        .create_lifetime_checkout()
        .await
        .map_err(server_error_response)?;
    Ok(Redirect::to(&checkout_url))
}

pub(crate) async fn verify_session(
    State(state): State<WebCheckoutState>,
    Query(query): Query<SessionQuery>,
) -> Result<Json<WebLicenseResponse>, ApiError> {
    let service = state.service()?;
    let session = service
        .load_completed_session(&query.session_id)
        .await
        .map_err(client_error_response)?;
    let response = service
        .issue_purchase_proof(&session)
        .map_err(server_error_response)?;
    state.send_license_email_async(&response);
    Ok(Json(response))
}

pub(crate) async fn activate_license(
    State(state): State<WebCheckoutState>,
    Json(request): Json<WebLicenseActivationRequest>,
) -> Result<Json<WebLicenseResponse>, ApiError> {
    let service = state.service()?;
    let token = request.license_token.trim();
    let device_id = request.device_id.trim();
    if token.is_empty() || device_id.is_empty() {
        return Err(client_error_response(
            "Activation requires both the purchase token and a device identifier.".to_string(),
        ));
    }

    let payload = service
        .decode_signed_payload(token, true)
        .map_err(client_error_response)?;
    let session = service
        .load_completed_session(&payload.session_id)
        .await
        .map_err(client_error_response)?;
    let now = Utc::now().timestamp();

    state
        .activation_registry
        .bind_or_renew(&payload.session_id, &payload.email, device_id, now)
        .map_err(client_error_response)?;

    let response = service
        .issue_device_license(&session, device_id, now)
        .map_err(server_error_response)?;
    Ok(Json(response))
}

pub(crate) async fn recover_purchase(
    State(state): State<WebCheckoutState>,
    ConnectInfo(remote_addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(request): Json<WebLicenseRecoveryRequest>,
) -> Result<Json<WebLicenseRecoveryResponse>, ApiError> {
    let _ = state.email_service()?;
    let email = request.email.trim();
    if email.is_empty() || !email.contains('@') {
        return Err(client_error_response(
            "Enter the email address you used during checkout.".to_string(),
        ));
    }

    let client_scope = recovery_client_scope(&headers, remote_addr.ip());
    let decision = state
        .recovery_guard
        .check_and_record(email, &client_scope, Instant::now());
    if !decision.allowed {
        tracing::warn!(
            email_fingerprint = %decision.email_fingerprint,
            client_fingerprint = %decision.client_fingerprint,
            "Recovery request throttled"
        );
        return Ok(Json(recovery_accepted_response()));
    }

    let service = state.service()?;
    match service.recover_completed_session(email).await {
        Ok(session) => {
            let response = service
                .issue_purchase_proof(&session)
                .map_err(server_error_response)?;
            state.send_license_email_async(&response);
        }
        Err(error) => {
            tracing::info!(
                email_fingerprint = %decision.email_fingerprint,
                client_fingerprint = %decision.client_fingerprint,
                error = %error,
                "Recovery request completed without a matching paid purchase"
            );
        }
    }

    Ok(Json(recovery_accepted_response()))
}

#[derive(Deserialize)]
pub(crate) struct SessionQuery {
    session_id: String,
}

#[derive(Deserialize)]
struct StripeCreateSessionResponse {
    url: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct StripeCheckoutSessionList {
    data: Vec<StripeCheckoutSession>,
}

#[derive(Clone, Debug, Deserialize)]
struct StripeCheckoutSession {
    id: String,
    status: Option<String>,
    payment_status: Option<String>,
    customer_details: Option<StripeCustomerDetails>,
    metadata: HashMap<String, String>,
    created: Option<i64>,
}

impl StripeCheckoutSession {
    fn is_completed_lifetime_purchase(&self) -> bool {
        self.status.as_deref() == Some("complete")
            && self.payment_status.as_deref() == Some("paid")
            && self.metadata.get("windowdrop_plan").map(String::as_str)
                == Some(WEB_LICENSE_PLAN_LIFETIME)
            && self
                .customer_details
                .as_ref()
                .and_then(|details| details.email.as_ref())
                .is_some()
    }
}

#[derive(Clone, Debug, Deserialize)]
struct StripeCustomerDetails {
    email: Option<String>,
}

fn client_error_response(message: String) -> ApiError {
    ApiError {
        status: StatusCode::BAD_REQUEST,
        message,
    }
}

fn server_error_response(message: String) -> ApiError {
    ApiError {
        status: StatusCode::INTERNAL_SERVER_ERROR,
        message,
    }
}

fn format_reqwest_error(context: &str, error: &reqwest::Error) -> String {
    let mut message = format!("{context}: {error}");
    let mut current = error.source();
    while let Some(source) = current {
        message.push_str(": ");
        message.push_str(&source.to_string());
        current = source.source();
    }
    message
}

async fn stripe_error_message(response: reqwest::Response) -> String {
    let status = response.status().as_u16();
    let fallback = format!("Stripe returned HTTP {}.", status);
    let value: Result<serde_json::Value, _> = response.json().await;
    match value {
        Ok(json) => stripe_error_message_from_value(status, &json),
        Err(_) => fallback,
    }
}

fn stripe_error_message_from_value(status: u16, value: &serde_json::Value) -> String {
    value
        .get("error")
        .and_then(|error| error.get("message"))
        .and_then(|message| message.as_str())
        .unwrap_or(&format!("Stripe returned HTTP {status}."))
        .to_string()
}

fn split_curl_status(stdout: &str) -> Result<(&str, u16), String> {
    let marker = "\n__WINDOWDROP_STATUS__:";
    let (body, status) = stdout
        .rsplit_once(marker)
        .ok_or_else(|| "curl response did not include an HTTP status marker.".to_string())?;
    let status = status
        .trim()
        .parse::<u16>()
        .map_err(|_| "curl response did not include a valid HTTP status code.".to_string())?;
    Ok((body, status))
}

fn escape_curl_config(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
}

fn decode_license_segments(token: &str) -> Result<(Vec<u8>, Vec<u8>), String> {
    let parts: Vec<_> = token.split('.').collect();
    let (payload_part, signature_part) = match parts.as_slice() {
        [payload, signature] => (*payload, *signature),
        ["wdl1", payload, signature] => (*payload, *signature),
        _ => return Err("Activation token format is invalid.".to_string()),
    };

    Ok((
        URL_SAFE_NO_PAD
            .decode(payload_part)
            .map_err(|_| "Activation token payload is invalid.".to_string())?,
        URL_SAFE_NO_PAD
            .decode(signature_part)
            .map_err(|_| "Activation token signature is invalid.".to_string())?,
    ))
}

fn decode_license_signature(data: &[u8]) -> Result<Signature, String> {
    Signature::from_der(data)
        .or_else(|_| Signature::from_slice(data))
        .map_err(|_| "Activation token signature is invalid.".to_string())
}

fn validate_license_payload(
    payload: &WebLicensePayload,
    allow_expired: bool,
) -> Result<(), String> {
    if payload.kind != WEB_LICENSE_KIND || payload.plan != WEB_LICENSE_PLAN_LIFETIME {
        return Err("Activation token payload is invalid.".to_string());
    }
    if payload.email.trim().is_empty() || payload.session_id.trim().is_empty() {
        return Err("Activation token payload is invalid.".to_string());
    }

    match payload.v {
        1 => {
            if payload.expires_at.is_some() || payload.device_id.is_some() {
                return Err("Activation token payload is invalid.".to_string());
            }
        }
        2 => {
            if payload
                .device_id
                .as_ref()
                .map(|value| value.trim().is_empty())
                != Some(false)
            {
                return Err("Activation token payload is invalid.".to_string());
            }
            let expires_at = payload
                .expires_at
                .ok_or_else(|| "Activation token payload is invalid.".to_string())?;
            if !allow_expired && expires_at <= Utc::now().timestamp() {
                return Err("Activation token has expired.".to_string());
            }
        }
        version => {
            return Err(format!(
                "Activation token version {version} is not supported."
            ));
        }
    }

    Ok(())
}

fn normalize_email(email: &str) -> String {
    email.trim().to_ascii_lowercase()
}

fn fingerprint(value: &str) -> String {
    let mut hasher = DefaultHasher::new();
    value.hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

fn forwarded_ip(headers: &HeaderMap) -> Option<IpAddr> {
    headers
        .get("x-forwarded-for")
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.split(',').next())
        .map(str::trim)
        .and_then(|value| value.parse::<IpAddr>().ok())
}

fn recovery_client_scope(headers: &HeaderMap, remote_ip: IpAddr) -> String {
    forwarded_ip(headers).unwrap_or(remote_ip).to_string()
}

fn recovery_accepted_response() -> WebLicenseRecoveryResponse {
    WebLicenseRecoveryResponse {
        status: "accepted".to_string(),
        message: RECOVERY_GENERIC_MESSAGE.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;

    #[test]
    fn issues_signed_license_token() {
        let service = WebCheckoutService {
            client: Client::new(),
            stripe_api_key: "test".to_string(),
            site_url: "https://windowdrop.pro".to_string(),
            download_url: "https://windowdrop.pro/download".to_string(),
            signing_key: SigningKey::from_slice(&[7u8; 32]).unwrap(),
        };
        let session = StripeCheckoutSession {
            id: "cs_test_123".to_string(),
            status: Some("complete".to_string()),
            payment_status: Some("paid".to_string()),
            customer_details: Some(StripeCustomerDetails {
                email: Some("buyer@example.com".to_string()),
            }),
            metadata: HashMap::from([(
                "windowdrop_plan".to_string(),
                WEB_LICENSE_PLAN_LIFETIME.to_string(),
            )]),
            created: Some(1_700_000_000),
        };

        let response = service.issue_purchase_proof(&session).unwrap();

        assert!(response.license_token.starts_with("wdl1."));
        assert_eq!(
            response
                .activation_url
                .starts_with("windowdrop://activate?license="),
            true
        );
        assert_eq!(response.download_url, "https://windowdrop.pro/download");
    }

    #[test]
    fn completed_lifetime_purchase_requires_paid_complete_session() {
        let session = StripeCheckoutSession {
            id: "cs_test_123".to_string(),
            status: Some("complete".to_string()),
            payment_status: Some("paid".to_string()),
            customer_details: Some(StripeCustomerDetails {
                email: Some("buyer@example.com".to_string()),
            }),
            metadata: HashMap::from([(
                "windowdrop_plan".to_string(),
                WEB_LICENSE_PLAN_LIFETIME.to_string(),
            )]),
            created: None,
        };

        assert!(session.is_completed_lifetime_purchase());
    }

    #[test]
    fn leased_device_license_contains_expiry_and_device_binding() {
        let service = WebCheckoutService {
            client: Client::new(),
            stripe_api_key: "test".to_string(),
            site_url: "https://windowdrop.pro".to_string(),
            download_url: "https://windowdrop.pro/download".to_string(),
            signing_key: SigningKey::from_slice(&[7u8; 32]).unwrap(),
        };
        let session = StripeCheckoutSession {
            id: "cs_test_123".to_string(),
            status: Some("complete".to_string()),
            payment_status: Some("paid".to_string()),
            customer_details: Some(StripeCustomerDetails {
                email: Some("buyer@example.com".to_string()),
            }),
            metadata: HashMap::from([(
                "windowdrop_plan".to_string(),
                WEB_LICENSE_PLAN_LIFETIME.to_string(),
            )]),
            created: Some(1_700_000_000),
        };

        let response = service
            .issue_device_license(&session, "device-123", 1_700_000_100)
            .unwrap();
        let payload = service
            .decode_signed_payload(&response.license_token, true)
            .unwrap();

        assert_eq!(payload.v, 2);
        assert_eq!(payload.device_id.as_deref(), Some("device-123"));
        assert_eq!(
            payload.expires_at,
            Some(1_700_000_100 + LICENSE_LEASE_DURATION.as_secs() as i64)
        );
    }

    #[test]
    fn recovery_guard_limits_by_email_and_client_scope() {
        let guard = RecoveryAbuseGuard::default();
        let now = Instant::now();

        let first = guard.check_and_record("buyer@example.com", "198.51.100.10", now);
        assert!(first.allowed);

        let repeated_email = guard.check_and_record(
            "buyer@example.com",
            "198.51.100.11",
            now + Duration::from_secs(5),
        );
        assert!(!repeated_email.allowed);

        let repeated_client = guard.check_and_record(
            "other@example.com",
            "198.51.100.10",
            now + Duration::from_secs(5),
        );
        assert!(!repeated_client.allowed);

        let after_cooldown = guard.check_and_record(
            "buyer@example.com",
            "198.51.100.10",
            now + RECOVERY_EMAIL_COOLDOWN + Duration::from_secs(1),
        );
        assert!(after_cooldown.allowed);
    }

    #[test]
    fn recovery_client_scope_prefers_forwarded_for() {
        let mut headers = HeaderMap::new();
        headers.insert(
            "x-forwarded-for",
            HeaderValue::from_static("203.0.113.5, 10.0.0.1"),
        );

        let scope = recovery_client_scope(&headers, "127.0.0.1".parse().unwrap());

        assert_eq!(scope, "203.0.113.5");
    }

    #[test]
    fn activation_registry_allows_first_device_and_renews_same_device() {
        let registry = ActivationRegistry {
            path: None,
            inner: Mutex::new(ActivationRegistryState::default()),
        };

        assert!(registry
            .bind_or_renew("cs_test_123", "buyer@example.com", "device-a", 100)
            .is_ok());
        assert!(registry
            .bind_or_renew("cs_test_123", "buyer@example.com", "device-a", 200)
            .is_ok());

        let state = registry.inner.lock().unwrap();
        let record = state.sessions.get("cs_test_123").unwrap();
        assert_eq!(record.device_id, "device-a");
        assert_eq!(record.first_activated_at, 100);
        assert_eq!(record.last_renewed_at, 200);
        assert_eq!(record.revoked_at, None);
    }

    #[test]
    fn activation_registry_rejects_second_device_for_same_purchase() {
        let registry = ActivationRegistry {
            path: None,
            inner: Mutex::new(ActivationRegistryState::default()),
        };

        registry
            .bind_or_renew("cs_test_123", "buyer@example.com", "device-a", 100)
            .unwrap();
        let error = registry
            .bind_or_renew("cs_test_123", "buyer@example.com", "device-b", 200)
            .unwrap_err();

        assert!(error.contains("already activated"));
    }

    #[test]
    fn activation_registry_rejects_revoked_purchase() {
        let mut state = ActivationRegistryState::default();
        state.sessions.insert(
            "cs_test_123".to_string(),
            ActivationRecord {
                device_id: "device-a".to_string(),
                email: "buyer@example.com".to_string(),
                first_activated_at: 100,
                last_renewed_at: 200,
                revoked_at: Some(300),
                revoked_reason: Some("chargeback".to_string()),
            },
        );
        let registry = ActivationRegistry {
            path: None,
            inner: Mutex::new(state),
        };

        let error = registry
            .bind_or_renew("cs_test_123", "buyer@example.com", "device-a", 400)
            .unwrap_err();

        assert!(error.contains("revoked"));
    }
}
