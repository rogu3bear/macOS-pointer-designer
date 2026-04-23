use serde::{Deserialize, Serialize};

#[allow(dead_code)]
pub const WEB_LICENSE_KIND: &str = "windowdrop_web_license";
#[allow(dead_code)]
pub const WEB_LICENSE_PLAN_LIFETIME: &str = "lifetime";
#[allow(dead_code)]
pub const WEB_LICENSE_PRICE_CENTS: u32 = 799;
pub const WEB_LICENSE_PRICE_LABEL: &str = "$7.99";

#[allow(dead_code)]
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct WebLicensePayload {
    pub v: u8,
    pub kind: String,
    pub plan: String,
    pub email: String,
    pub session_id: String,
    pub issued_at: i64,
    pub expires_at: Option<i64>,
    pub device_id: Option<String>,
}

#[allow(dead_code)]
impl WebLicensePayload {
    pub fn purchase_proof(email: String, session_id: String, issued_at: i64) -> Self {
        Self {
            v: 1,
            kind: WEB_LICENSE_KIND.to_string(),
            plan: WEB_LICENSE_PLAN_LIFETIME.to_string(),
            email,
            session_id,
            issued_at,
            expires_at: None,
            device_id: None,
        }
    }

    pub fn leased_device_license(
        email: String,
        session_id: String,
        issued_at: i64,
        expires_at: i64,
        device_id: String,
    ) -> Self {
        Self {
            v: 2,
            kind: WEB_LICENSE_KIND.to_string(),
            plan: WEB_LICENSE_PLAN_LIFETIME.to_string(),
            email,
            session_id,
            issued_at,
            expires_at: Some(expires_at),
            device_id: Some(device_id),
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct WebLicenseResponse {
    pub status: String,
    pub email: String,
    pub plan: String,
    pub price_label: String,
    pub license_token: String,
    pub activation_url: String,
    pub download_url: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct WebLicenseRecoveryRequest {
    pub email: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct WebLicenseRecoveryResponse {
    pub status: String,
    pub message: String,
}

#[allow(dead_code)]
#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct WebLicenseActivationRequest {
    pub license_token: String,
    pub device_id: String,
}

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct ApiErrorResponse {
    pub error: String,
}
