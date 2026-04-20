//! CTA button component that respects config modes.
//!
//! Adapts behavior based on `CONFIG.cta_mode`:
//! - TrialDownload / EarlyAccess: Direct download link
//! - NotifyMe: Scrolls to email capture section
//! - AppStoreLink: Links to App Store

use leptos::*;
use leptos_router::use_location;

use crate::analytics::{track_event, AnalyticsEvent};
use crate::config::CONFIG;

/// Primary CTA button that adapts to the current config mode.
#[component]
pub fn CtaPrimary(
    /// Additional CSS classes
    #[prop(optional)]
    class: &'static str,
) -> impl IntoView {
    let label = CONFIG.primary_cta_label();
    let url = CONFIG.primary_cta_url();
    let is_email_capture = CONFIG.primary_cta_is_email_capture();
    let location = use_location();

    let on_click = move |_| {
        track_event(AnalyticsEvent::CtaPrimaryClicked);

        if is_email_capture {
            // Scroll to email capture section
            if let Some(window) = web_sys::window() {
                if let Some(document) = window.document() {
                    if let Some(element) = document.get_element_by_id("email-capture") {
                        element.scroll_into_view();
                        return;
                    }
                }

                // If the current route doesn't have the capture section (e.g. /download),
                // bounce to the home route where it exists.
                if location.pathname.get_untracked() != "/" {
                    let _ = window.location().set_href("/#email-capture");
                }
            }
        }
    };

    let btn_class = format!("btn btn-primary {}", class);

    if let Some(href) = url {
        view! {
            <a href=href class=btn_class on:click=on_click>
                {label}
            </a>
        }
        .into_view()
    } else if is_email_capture {
        view! {
            <button type="button" class=btn_class on:click=on_click>
                {label}
            </button>
        }
        .into_view()
    } else {
        // Fallback: Coming soon state
        view! {
            <span class="btn btn-disabled" aria-disabled="true">
                "Coming Soon"
            </span>
        }
        .into_view()
    }
}

/// Secondary CTA button (e.g., "How it works").
#[component]
pub fn CtaSecondary(
    /// Button label
    label: &'static str,
    /// Target href or scroll target
    href: &'static str,
    /// Additional CSS classes
    #[prop(optional)]
    class: &'static str,
) -> impl IntoView {
    let on_click = move |_| {
        track_event(AnalyticsEvent::CtaSecondaryClicked);
    };

    let btn_class = format!("btn btn-secondary {}", class);

    view! {
        <a href=href class=btn_class on:click=on_click>
            {label}
        </a>
    }
}

/// CTA section with primary and secondary buttons.
#[component]
pub fn CtaSection() -> impl IntoView {
    view! {
        <section class="section cta-section" id="cta">
            <div class="container text-center">
                <h2 class="section-title">"Ready to try WindowDrop?"</h2>
                <p class="section-subtitle">
                    "Your windows appear where you are."
                </p>
                <div class="cta-buttons">
                    <CtaPrimary />
                    <CtaSecondary label="How it works" href="#how-it-works" />
                </div>
            </div>
        </section>
    }
}
