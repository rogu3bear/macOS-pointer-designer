//! Email capture component for waitlist/notification signup.
//!
//! Displays when CTA mode requires email capture instead of direct download.

use leptos::*;
use wasm_bindgen::JsCast;
use web_sys::HtmlInputElement;

use crate::analytics::{track_event, AnalyticsEvent};
use crate::config::CONFIG;

/// Email capture form for pre-launch signups.
#[component]
pub fn EmailCapture() -> impl IntoView {
    let (email, set_email) = create_signal(String::new());
    let (submitted, set_submitted) = create_signal(false);
    let (error, set_error) = create_signal(Option::<String>::None);

    let on_submit = move |ev: web_sys::SubmitEvent| {
        ev.prevent_default();

        let email_value = email.get();

        // Basic validation
        if email_value.is_empty() || !email_value.contains('@') {
            set_error.set(Some("Please enter a valid email address.".to_string()));
            return;
        }

        // Track the event
        track_event(AnalyticsEvent::WaitlistSubmitted);

        // In a real implementation, this would submit to a backend
        // For MVP, we just show success state
        set_submitted.set(true);
        set_error.set(None);
        // Privacy: never log user-entered emails to console (even in dev).
    };

    let on_input = move |ev: web_sys::Event| {
        if let Some(target) = ev.target() {
            if let Ok(input) = target.dyn_into::<HtmlInputElement>() {
                set_email.set(input.value());
                set_error.set(None);
            }
        }
    };

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
                                <form class="email-capture-form" on:submit=on_submit>
                                    <div class="email-capture-input-group">
                                        <input
                                            type="email"
                                            class="email-capture-input"
                                            placeholder="your@email.com"
                                            required
                                            autocomplete="email"
                                            aria-label="Email address"
                                            on:input=on_input
                                            prop:value=email
                                        />
                                        <button type="submit" class="btn btn-primary email-capture-btn">
                                            "Notify me"
                                        </button>
                                    </div>
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
