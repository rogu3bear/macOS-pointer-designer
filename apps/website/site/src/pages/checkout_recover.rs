use crate::seo::meta::SeoMeta;
use crate::web_license::{ApiErrorResponse, WebLicenseRecoveryRequest, WebLicenseRecoveryResponse};
use leptos::*;
use leptos_router::A;
use wasm_bindgen::JsCast;
use wasm_bindgen_futures::{spawn_local, JsFuture};
use web_sys::{Event, HtmlInputElement};

#[component]
pub fn CheckoutRecover() -> impl IntoView {
    let (email, set_email) = create_signal(String::new());
    let (submitting, set_submitting) = create_signal(false);
    let (result, set_result) = create_signal(Option::<WebLicenseRecoveryResponse>::None);
    let (error, set_error) = create_signal(Option::<String>::None);

    let on_input = move |ev: Event| {
        if let Some(target) = ev.target() {
            if let Ok(input) = target.dyn_into::<HtmlInputElement>() {
                set_email.set(input.value());
                set_error.set(None);
            }
        }
    };

    let on_submit = move |ev: web_sys::SubmitEvent| {
        ev.prevent_default();
        let email_value = email.get_untracked().trim().to_string();
        if email_value.is_empty() || !email_value.contains('@') {
            set_error.set(Some(
                "Enter the email address you used during checkout.".to_string(),
            ));
            return;
        }
        if submitting.get_untracked() {
            return;
        }
        set_submitting.set(true);
        set_error.set(None);
        set_result.set(None);

        spawn_local(async move {
            let payload = WebLicenseRecoveryRequest { email: email_value };
            match serde_json::to_string(&payload) {
                Ok(body) => {
                    match fetch_json::<WebLicenseRecoveryResponse>(
                        "/api/web-license/recover",
                        "POST",
                        Some(body),
                    )
                    .await
                    {
                        Ok(response) => set_result.set(Some(response)),
                        Err(message) => set_error.set(Some(message)),
                    }
                }
                Err(_) => set_error.set(Some("Failed to prepare recovery request.".to_string())),
            }
            set_submitting.set(false);
        });
    };

    view! {
        <SeoMeta
            title="Recover Web Purchase"
            description="Recover a WindowDrop web purchase by email and activate it in the app."
            path="/checkout/recover"
        />
        <div class="download-page">
            <section class="download-hero">
                <div class="container container-narrow">
                    <div class="download-hero-icon">"↺"</div>
                    <h1 class="download-hero-title">"Recover web purchase"</h1>
                    <p class="download-hero-subtitle">
                        "Enter the checkout email address and we will resend the WindowDrop lifetime activation to that inbox."
                    </p>
                </div>
            </section>

            <section class="section email-section">
                <div class="container container-narrow">
                    <div class="email-capture-form-wrapper">
                        <form class="email-capture-form" on:submit=on_submit>
                            <div class="email-capture-input-group">
                                <input
                                    type="email"
                                    class="email-capture-input"
                                    placeholder="your@email.com"
                                    required
                                    autocomplete="email"
                                    aria-label="Checkout email address"
                                    on:input=on_input
                                    prop:value=email
                                />
                                <button
                                    type="submit"
                                    class="btn btn-primary email-capture-btn"
                                    disabled=move || submitting.get()
                                >
                                    {move || if submitting.get() { "Recovering..." } else { "Recover purchase" }}
                                </button>
                            </div>
                            {move || error.get().map(|message| view! {
                                <p class="email-capture-error">{message}</p>
                            })}
                        </form>
                        <p class="email-capture-privacy">
                            "We only use the email address to look up completed WindowDrop lifetime checkouts."
                        </p>
                    </div>
                </div>
            </section>

            <section class="section download-install">
                <div class="container container-narrow">
                    <div class="verify-card">
                        {move || {
                            if let Some(response) = result.get() {
                                view! {
                                    <>
                                        <p class="verify-instruction">
                                            {response.message.clone()}
                                        </p>
                                        <p class="verify-instruction">
                                            "Open the email on the Mac where you want to activate WindowDrop, then use the activation link or paste the code into Preferences → Access."
                                        </p>
                                    </>
                                }.into_view()
                            } else {
                                view! {
                                    <p class="verify-instruction">
                                        "Need the app first? "
                                        <A href="/download">"Download WindowDrop"</A>
                                    </p>
                                }.into_view()
                            }
                        }}
                    </div>
                </div>
            </section>
        </div>
    }
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
        serde_json::from_str(&text).map_err(|_| "Failed to read recovery response.".to_string())
    } else {
        let error: ApiErrorResponse = serde_json::from_str(&text).unwrap_or(ApiErrorResponse {
            error: "Could not recover a purchase for that email address.".to_string(),
        });
        Err(error.error)
    }
}
