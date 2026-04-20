//! Site configuration for CTA modes and feature flags.
//!
//! This module provides a config-driven approach for the CTA layer,
//! allowing the site to adapt to different monetization phases without
//! code changes.

/// The active CTA mode determines button labels and actions.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)]
pub enum CtaMode {
    /// Direct download link to trial version
    TrialDownload,
    /// Same as trial but labeled "Early Access"
    EarlyAccess,
    /// Email capture form for pre-launch
    NotifyMe,
    /// Link to Mac App Store
    AppStoreLink,
}

/// Site-wide configuration.
#[derive(Debug, Clone)]
pub struct SiteConfig {
    /// Current CTA mode
    pub cta_mode: CtaMode,
    /// URL for trial download (if available)
    pub trial_url: Option<&'static str>,
    /// URL for waitlist signup (if available)
    #[allow(dead_code)]
    pub waitlist_url: Option<&'static str>,
    /// URL for App Store (if available)
    pub store_url: Option<&'static str>,
    /// Whether animations are enabled
    pub animation_enabled: bool,
    /// Whether email capture is enabled
    pub email_capture_enabled: bool,
}

/// Default configuration.
///
/// Currently set to `NotifyMe` mode since no download URLs exist yet.
/// Update these values when trial/store links become available.
pub const CONFIG: SiteConfig = SiteConfig {
    cta_mode: CtaMode::NotifyMe,
    trial_url: None,
    waitlist_url: None,
    store_url: None,
    animation_enabled: true,
    email_capture_enabled: true,
};

impl SiteConfig {
    /// Returns the primary CTA label based on the current mode.
    pub fn primary_cta_label(&self) -> &'static str {
        match self.cta_mode {
            CtaMode::TrialDownload => "Download WindowDrop",
            CtaMode::EarlyAccess => "Get Early Access",
            CtaMode::NotifyMe => "Get Notified",
            CtaMode::AppStoreLink => "Download on App Store",
        }
    }

    /// Returns the primary CTA URL, or None if unavailable.
    pub fn primary_cta_url(&self) -> Option<&'static str> {
        match self.cta_mode {
            CtaMode::TrialDownload | CtaMode::EarlyAccess => self.trial_url,
            CtaMode::NotifyMe => None, // Uses email capture instead
            CtaMode::AppStoreLink => self.store_url,
        }
    }

    /// Returns true if the primary CTA should trigger email capture.
    pub fn primary_cta_is_email_capture(&self) -> bool {
        matches!(self.cta_mode, CtaMode::NotifyMe | CtaMode::EarlyAccess)
            && self.primary_cta_url().is_none()
    }

    /// Returns true if a functional CTA is available.
    #[allow(dead_code)]
    pub fn has_functional_cta(&self) -> bool {
        self.primary_cta_url().is_some() || self.email_capture_enabled
    }
}
