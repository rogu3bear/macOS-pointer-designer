use reqwest::Client;
use serde::Serialize;

use super::web_license::WebLicenseResponse;

#[derive(Clone)]
pub(crate) struct EmailService {
    client: Client,
    api_key: String,
    from_email: String,
}

#[derive(Serialize)]
struct ResendEmail {
    from: String,
    to: Vec<String>,
    subject: String,
    html: String,
}

impl EmailService {
    pub fn from_env() -> Option<Self> {
        let api_key = std::env::var("RESEND_API_KEY").ok()?.trim().to_string();
        if api_key.is_empty() {
            return None;
        }
        let from_email = std::env::var("RESEND_FROM_EMAIL")
            .unwrap_or_else(|_| "WindowDrop <licenses@windowdrop.pro>".to_string())
            .trim()
            .to_string();
        let client = Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .build()
            .ok()?;
        Some(Self {
            client,
            api_key,
            from_email,
        })
    }

    pub async fn send_license_email(&self, response: &WebLicenseResponse) {
        let html = format_license_email(response);
        let email = ResendEmail {
            from: self.from_email.clone(),
            to: vec![response.email.clone()],
            subject: "Your WindowDrop Lifetime License".to_string(),
            html,
        };

        let result = self
            .client
            .post("https://api.resend.com/emails")
            .bearer_auth(&self.api_key)
            .json(&email)
            .send()
            .await;

        match result {
            Ok(resp) if resp.status().is_success() => {
                tracing::info!(email = %response.email, "License email sent via Resend");
            }
            Ok(resp) => {
                let status = resp.status();
                let body = resp.text().await.unwrap_or_default();
                tracing::warn!(
                    email = %response.email,
                    status = %status,
                    body = %body,
                    "Resend API returned non-success"
                );
            }
            Err(error) => {
                tracing::warn!(
                    email = %response.email,
                    error = %error,
                    "Failed to send license email via Resend"
                );
            }
        }
    }
}

fn format_license_email(response: &WebLicenseResponse) -> String {
    format!(
        r#"<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; color: #333;">
  <h1 style="font-size: 24px; margin-bottom: 8px;">WindowDrop Lifetime License</h1>
  <p>Thank you for your purchase! Here is your lifetime license for WindowDrop.</p>

  <div style="background: #f5f5f7; border-radius: 12px; padding: 20px; margin: 24px 0;">
    <p style="margin: 0 0 8px;"><strong>Plan:</strong> {plan} ({price})</p>
    <p style="margin: 0 0 8px;"><strong>Email:</strong> {email}</p>
  </div>

  <h2 style="font-size: 18px;">Activate your license</h2>
  <p>Click the button below to activate WindowDrop on this Mac, or paste the activation code into WindowDrop Preferences → Access while online.</p>

  <div style="text-align: center; margin: 24px 0;">
    <a href="{activation_url}" style="display: inline-block; background: #007AFF; color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600;">Activate in WindowDrop</a>
  </div>

  <div style="text-align: center; margin: 16px 0;">
    <a href="{download_url}" style="display: inline-block; color: #007AFF; text-decoration: none; font-weight: 500;">Download WindowDrop</a>
  </div>

  <h2 style="font-size: 18px;">Activation code</h2>
  <div style="background: #1a1a1a; color: #e0e0e0; border-radius: 8px; padding: 16px; word-break: break-all; font-family: 'SF Mono', Monaco, monospace; font-size: 12px; line-height: 1.5;">
    {license_token}
  </div>

  <h2 style="font-size: 18px; margin-top: 24px;">Need help later?</h2>
  <ul style="line-height: 1.8;">
    <li>Recover your license anytime at <a href="https://windowdrop.pro/checkout/recover" style="color: #007AFF;">windowdrop.pro/checkout/recover</a></li>
    <li>Use the email address from your original purchase</li>
    <li>Each web purchase activates one Mac at a time through the WindowDrop activation service</li>
  </ul>

  <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 32px 0;">
  <p style="font-size: 12px; color: #888;">
    WindowDrop · <a href="https://windowdrop.pro" style="color: #888;">windowdrop.pro</a><br>
    Save this email for your records.
  </p>
</body>
</html>"#,
        plan = response.plan,
        price = response.price_label,
        email = response.email,
        activation_url = response.activation_url,
        download_url = response.download_url,
        license_token = response.license_token,
    )
}
