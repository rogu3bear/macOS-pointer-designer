use crate::seo::meta::SeoMeta;
use crate::web_license::{ApiErrorResponse, WebLicenseResponse, WEB_LICENSE_PRICE_LABEL};
use leptos::*;
use leptos_router::A;
use wasm_bindgen::JsCast;
use wasm_bindgen_futures::{spawn_local, JsFuture};

#[component]
pub fn CheckoutSuccess() -> impl IntoView {
    let (loading, set_loading) = create_signal(true);
    let (result, set_result) = create_signal(Option::<WebLicenseResponse>::None);
    let (error, set_error) = create_signal(Option::<String>::None);
    let (copy_status, set_copy_status) = create_signal(Option::<String>::None);
    let session_id = current_query_param("session_id");

    create_effect(move |_| {
        let Some(session_id) = session_id.clone() else {
            set_loading.set(false);
            set_error.set(Some(
                "Missing checkout session. If you already paid, recover your web purchase by email."
                    .to_string(),
            ));
            return;
        };

        spawn_local(async move {
            match fetch_json::<WebLicenseResponse>(
                &format!("/api/web-license/session?session_id={session_id}"),
                "GET",
                None,
            )
            .await
            {
                Ok(response) => set_result.set(Some(response)),
                Err(message) => set_error.set(Some(message)),
            }
            set_loading.set(false);
        });
    });

    let on_copy = move |_| {
        let Some(response) = result.get_untracked() else {
            return;
        };
        let token = response.license_token.clone();
        set_copy_status.set(None);
        spawn_local(async move {
            let status = match copy_to_clipboard(&token).await {
                Ok(()) => "Activation code copied.".to_string(),
                Err(message) => message,
            };
            set_copy_status.set(Some(status));
        });
    };

    view! {
        <SeoMeta
            title="Purchase Confirmed"
            description="Your WindowDrop lifetime purchase is ready. Download the app and activate it."
            path="/checkout/success"
        />
        <div class="download-page">
            <section class="download-hero">
                <div class="container container-narrow">
                    <div class="download-hero-icon">"✓"</div>
                    <h1 class="download-hero-title">"Purchase confirmed"</h1>
                    <p class="download-hero-subtitle">
                        "Download WindowDrop and activate your lifetime unlock."
                    </p>
                </div>
            </section>

            <section class="section download-install">
                <div class="container container-narrow">
                    <div class="verify-card">
                        {move || {
                            if loading.get() {
                                view! { <p class="verify-instruction">"Verifying your checkout..."</p> }.into_view()
                            } else if let Some(message) = error.get() {
                                view! {
                                    <>
                                        <p class="verify-instruction">{message}</p>
                                        <p class="verify-instruction">
                                            <A href="/checkout/recover">"Recover web purchase"</A>
                                            " if you already completed payment."
                                        </p>
                                    </>
                                }.into_view()
                            } else if let Some(response) = result.get() {
                                let license_token = response.license_token.clone();
                                view! {
                                    <>
                                        <p class="verify-instruction">
                                            {format!(
                                                "Verified {price} lifetime purchase for {email}.",
                                                price = WEB_LICENSE_PRICE_LABEL,
                                                email = response.email
                                            )}
                                        </p>
                                        <div class="cta-buttons">
                                            <a href=response.download_url.clone() class="btn btn-primary">
                                                "Download WindowDrop"
                                            </a>
                                            <a href=response.activation_url.clone() class="btn btn-secondary">
                                                "Activate in WindowDrop"
                                            </a>
                                        </div>
                                        <h3 class="section-title" style="margin-top: 24px;">"Activation code"</h3>
                                        <code class="verify-hash" style="white-space: pre-wrap;">{license_token}</code>
                                        <div class="cta-buttons" style="margin-top: 16px;">
                                            <button type="button" class="btn btn-secondary" on:click=on_copy>
                                                "Copy activation code"
                                            </button>
                                            <A href="/checkout/recover" class="btn btn-secondary">
                                                "Recover by email"
                                            </A>
                                        </div>
                                        {move || copy_status.get().map(|message| view! {
                                            <p class="verify-instruction">{message}</p>
                                        })}
                                        <div class="install-steps" style="margin-top: 24px;">
                                            <div class="install-step">
                                                <div class="install-step-number">"1"</div>
                                                <div class="install-step-content">
                                                    <h3 class="install-step-title">"Download the app"</h3>
                                                    <p class="install-step-description">
                                                        "Use the Download button above if WindowDrop is not installed yet."
                                                    </p>
                                                </div>
                                            </div>
                                            <div class="install-step">
                                                <div class="install-step-number">"2"</div>
                                                <div class="install-step-content">
                                                    <h3 class="install-step-title">"Activate your purchase"</h3>
                                                    <p class="install-step-description">
                                                        "Open the Activate in WindowDrop link, or paste the activation code into WindowDrop Preferences → Access while online on the Mac you want to unlock."
                                                    </p>
                                                </div>
                                            </div>
                                            <div class="install-step">
                                                <div class="install-step-number">"3"</div>
                                                <div class="install-step-content">
                                                    <h3 class="install-step-title">"Recover later by email"</h3>
                                                    <p class="install-step-description">
                                                        "If you need help later, recover the web purchase from this site using the checkout email and reactivate it from that inbox."
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    </>
                                }.into_view()
                            } else {
                                view! { <p class="verify-instruction">"No purchase details available."</p> }.into_view()
                            }
                        }}
                    </div>
                </div>
            </section>
        </div>
    }
}

fn current_query_param(name: &str) -> Option<String> {
    let search = web_sys::window()?.location().search().ok()?;
    let params = web_sys::UrlSearchParams::new_with_str(&search).ok()?;
    params.get(name)
}

async fn copy_to_clipboard(value: &str) -> Result<(), String> {
    let navigator = web_sys::window()
        .ok_or_else(|| "No browser window available.".to_string())?
        .navigator();
    let clipboard = navigator.clipboard();
    JsFuture::from(clipboard.write_text(value))
        .await
        .map_err(|_| "Copy failed. You can still select and copy the code manually.".to_string())?;
    Ok(())
}

async fn fetch_json<T>(url: &str, method: &str, body: Option<String>) -> Result<T, String>
where
    T: for<'de> serde::Deserialize<'de>,
{
    let window = web_sys::window().ok_or_else(|| "No browser window available.".to_string())?;
    let opts = web_sys::RequestInit::new();
    opts.set_method(method);
    if let Some(body) = body {
        opts.set_body(&wasm_bindgen::JsValue::from_str(&body));
    }
    let headers = web_sys::Headers::new().map_err(|_| "Failed to build request.".to_string())?;
    headers
        .set("Content-Type", "application/json")
        .map_err(|_| "Failed to set request headers.".to_string())?;
    opts.set_headers(&headers);
    let request = web_sys::Request::new_with_str_and_init(url, &opts)
        .map_err(|_| "Failed to create request.".to_string())?;
    let response = JsFuture::from(window.fetch_with_request(&request))
        .await
        .map_err(|_| "Network error. Please try again.".to_string())?;
    let response: web_sys::Response = response
        .dyn_into()
        .map_err(|_| "Invalid server response.".to_string())?;
    let text = JsFuture::from(
        response
            .text()
            .map_err(|_| "Server response was not valid JSON.".to_string())?,
    )
    .await
    .map_err(|_| "Server response was not valid JSON.".to_string())?
    .as_string()
    .ok_or_else(|| "Server response was not valid JSON.".to_string())?;

    if response.ok() {
        serde_json::from_str(&text).map_err(|_| "Failed to read purchase response.".to_string())
    } else {
        let error: ApiErrorResponse = serde_json::from_str(&text).unwrap_or(ApiErrorResponse {
            error: "Something went wrong while verifying your purchase.".to_string(),
        });
        Err(error.error)
    }
}
