//! Analytics instrumentation for interest measurement.
//!
//! MVP implementation using console logging.
//! No external vendor SDKs per PRD requirements.

use wasm_bindgen::JsValue;

/// Analytics events tracked by the site.
#[derive(Debug, Clone, Copy)]
pub enum AnalyticsEvent {
    /// Primary CTA button clicked
    CtaPrimaryClicked,
    /// Secondary CTA button clicked
    CtaSecondaryClicked,
    /// Hero animation completed viewing
    AnimationViewed,
    /// Email submitted for waitlist/notifications
    WaitlistSubmitted,
}

impl AnalyticsEvent {
    /// Returns the event name for logging.
    pub fn name(&self) -> &'static str {
        match self {
            Self::CtaPrimaryClicked => "cta_primary_clicked",
            Self::CtaSecondaryClicked => "cta_secondary_clicked",
            Self::AnimationViewed => "animation_viewed",
            Self::WaitlistSubmitted => "waitlist_submitted",
        }
    }
}

/// Track an analytics event.
///
/// Currently logs to console. Can be extended to send to an endpoint.
pub fn track_event(event: AnalyticsEvent) {
    // Privacy: do not emit any analytics/telemetry in production builds.
    // Dev builds log to console for instrumentation sanity checks.
    if cfg!(debug_assertions) {
        let message = format!("[analytics] {}", event.name());
        web_sys::console::log_1(&JsValue::from_str(&message));
    }
}

/// Track an analytics event with additional data.
#[allow(dead_code)]
pub fn track_event_with_data(event: AnalyticsEvent, data: &str) {
    if cfg!(debug_assertions) {
        let message = format!("[analytics] {} | {}", event.name(), data);
        web_sys::console::log_1(&JsValue::from_str(&message));
    }
}
