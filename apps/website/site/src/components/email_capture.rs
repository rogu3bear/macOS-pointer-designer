//! Email capture component for waitlist/notification signup.
//!
//! Displays when CTA mode requires email capture instead of direct download.
//! Includes Cloudflare Turnstile challenge for bot protection.

use leptos::*;
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use wasm_bindgen_futures::spawn_local;
use web_sys::HtmlInputElement;

use crate::analytics::{track_event, AnalyticsEvent};
use crate::config::CONFIG;

const TURNSTILE_SITEKEY: &str = "0x4AAAAAACh770I-GvLb9erh";

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = turnstile)]
    fn render(selector: &str, options: &JsValue) -> JsValue;

    #[wasm_bindgen(js_namespace = turnstile, js_name = getResponse)]
    fn get_response(widget_id: &JsValue) -> Option<String>;

    #[wasm_bindgen(js_namespace = turnstile)]
    fn reset(widget_id: &JsValue);
}

/// Email capture form for pre-launch signups.
#[component]
pub fn EmailCapture() -> impl IntoView {
    let (email, set_email) = create_signal(String::new());
    let (submitted, set_submitted) = create_signal(false);
    let (submitting, set_submitting) = create_signal(false);
    let (error, set_error) = create_signal(Option::<String>::None);
    let widget_id: std::cell::RefCell<Option<JsValue>> = std::cell::RefCell::new(None);
    let widget_id = std::rc::Rc::new(widget_id);

    // Render Turnstile widget after component mounts
    let widget_id_clone = widget_id.clone();
    create_effect(move |_| {
        // Small delay to ensure the DOM element exists
        let wid = widget_id_clone.clone();
        let cb = Closure::once_into_js(move || {
            let opts = js_sys::Object::new();
            let _ = js_sys::Reflect::set(&opts, &"sitekey".into(), &TURNSTILE_SITEKEY.into());
            let _ = js_sys::Reflect::set(&opts, &"size".into(), &"compact".into());
            let _ = js_sys::Reflect::set(&opts, &"theme".into(), &"light".into());
            if let Ok(id) = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                render("#turnstile-container", &opts)
            })) {
                *wid.borrow_mut() = Some(id);
            }
        });
        if let Some(window) = web_sys::window() {
            let _ = window
                .set_timeout_with_callback_and_timeout_and_arguments_0(cb.unchecked_ref(), 500);
        }
    });

    let widget_id_submit = widget_id.clone();
    let on_submit = store_value(move |ev: web_sys::SubmitEvent| {
        ev.prevent_default();

        let email_value = email.get();

        if email_value.is_empty() || !email_value.contains('@') {
            set_error.set(Some("Please enter a valid email address.".to_string()));
            return;
        }

        // Get Turnstile token
        let token = widget_id_submit
            .borrow()
            .as_ref()
            .and_then(get_response)
            .unwrap_or_default();

        if token.is_empty() {
            set_error.set(Some("Please complete the verification.".to_string()));
            return;
        }

        if submitting.get_untracked() {
            return;
        }

        set_submitting.set(true);
        set_error.set(None);
        track_event(AnalyticsEvent::WaitlistSubmitted);

        let widget_id_reset = widget_id_submit.clone();
        spawn_local(async move {
            match subscribe_email(&email_value, &token).await {
                Ok(()) => {
                    set_submitted.set(true);
                }
                Err(msg) => {
                    set_error.set(Some(msg));
                    // Reset Turnstile on failure
                    if let Some(wid) = widget_id_reset.borrow().as_ref() {
                        reset(wid);
                    }
                }
            }
            set_submitting.set(false);
        });
    });

    let on_input = store_value(move |ev: web_sys::Event| {
        if let Some(target) = ev.target() {
            if let Ok(input) = target.dyn_into::<HtmlInputElement>() {
                set_email.set(input.value());
                set_error.set(None);
            }
        }
    });

    // Don't render if email capture is disabled
    if !CONFIG.email_capture_enabled {
        return {
            view! { <></> };
            ().into_view()
        };
    }

    view! {
        <div class="email-capture" id="email-capture">
            <div class="email-capture-content">
                {move || {
                    if submitted.get() {
                        view! {
                            <div class="email-capture-success">
                                <div class="email-capture-success-icon">"✓"</div>
                                <h3 class="email-capture-heading">"You're on the list!"</h3>
                                <p class="email-capture-subtext">
                                    "We'll let you know when WindowDrop is ready."
                                </p>
                            </div>
                        }.into_view()
                    } else {
                        view! {
                            <div class="email-capture-form-wrapper">
                                <h3 class="email-capture-heading">"Get notified when it's ready"</h3>
                                <p class="email-capture-subtext">
                                    "We're finalizing release details."
                                </p>
                                <form class="email-capture-form" on:submit=move |ev| on_submit.with_value(|f| f(ev))>
                                    <div class="email-capture-input-group">
                                        <input
                                            type="email"
                                            class="email-capture-input"
                                            placeholder="your@email.com"
                                            required
                                            autocomplete="email"
                                            aria-label="Email address"
                                            on:input=move |ev| on_input.with_value(|f| f(ev))
                                            prop:value=email
                                        />
                                        <button
                                            type="submit"
                                            class="btn btn-primary email-capture-btn"
                                            disabled=move || submitting.get()
                                        >
                                            {move || if submitting.get() { "Submitting..." } else { "Notify me" }}
                                        </button>
                                    </div>
                                    <div id="turnstile-container" style="margin-top: 12px;"></div>
                                    {move || error.get().map(|e| view! {
                                        <p class="email-capture-error">{e}</p>
                                    })}
                                </form>
                                <p class="email-capture-privacy">
                                    "No spam. Unsubscribe anytime."
                                </p>
                            </div>
                        }.into_view()
                    }
                }}
            </div>
        </div>
    }.into_view()
}

async fn subscribe_email(email: &str, token: &str) -> Result<(), String> {
    let window = web_sys::window().ok_or_else(|| "No window".to_string())?;

    // Build JSON safely via js_sys to avoid injection
    let obj = js_sys::Object::new();
    let _ = js_sys::Reflect::set(&obj, &"email".into(), &JsValue::from_str(email));
    let _ = js_sys::Reflect::set(&obj, &"token".into(), &JsValue::from_str(token));
    let body = js_sys::JSON::stringify(&obj)
        .map_err(|_| "Failed to serialize".to_string())?
        .as_string()
        .ok_or_else(|| "Failed to serialize".to_string())?;

    let opts = web_sys::RequestInit::new();
    opts.set_method("POST");
    opts.set_body(&wasm_bindgen::JsValue::from_str(&body));
    let headers = web_sys::Headers::new().map_err(|_| "Failed to create headers".to_string())?;
    headers
        .set("Content-Type", "application/json")
        .map_err(|_| "Failed to set header".to_string())?;
    opts.set_headers(&headers);
    let request = web_sys::Request::new_with_str_and_init("/api/subscribe", &opts)
        .map_err(|_| "Failed to create request".to_string())?;
    let resp = wasm_bindgen_futures::JsFuture::from(window.fetch_with_request(&request))
        .await
        .map_err(|_| "Network error. Please try again.".to_string())?;
    let resp: web_sys::Response = resp
        .dyn_into()
        .map_err(|_| "Invalid response".to_string())?;
    if resp.ok() {
        Ok(())
    } else {
        Err("Something went wrong. Please try again.".to_string())
    }
}
