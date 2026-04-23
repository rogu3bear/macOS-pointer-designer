//! Site configuration for CTA modes and feature flags.
//!
//! This module provides a config-driven approach for the CTA layer,
//! allowing the site to adapt to different monetization phases without
//! code changes.

use std::sync::LazyLock;

pub const DEFAULT_RELEASE_VERSION: &str = "1.0.1";
pub const DEFAULT_RELEASE_REPO: &str = "rogu3bear/windowdrop";
pub const DEFAULT_RELEASE_TAG: &str = "v1.0.1";
#[allow(dead_code)]
pub const DEFAULT_DMG_URL: &str =
    "https://github.com/rogu3bear/windowdrop/releases/download/v1.0.1/WindowDrop-1.0.1.dmg";
#[allow(dead_code)]
pub const DEFAULT_ZIP_URL: &str =
    "https://github.com/rogu3bear/windowdrop/releases/download/v1.0.1/WindowDrop-1.0.1.zip";
#[allow(dead_code)]
pub const DEFAULT_CHECKSUMS_URL: &str =
    "https://github.com/rogu3bear/windowdrop/releases/download/v1.0.1/WindowDrop-1.0.1-checksums.txt";
#[allow(dead_code)]
pub const DEFAULT_RELEASE_URL: &str = "https://github.com/rogu3bear/windowdrop/releases/tag/v1.0.1";

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

/// The lifetime purchase route rendered on `/pricing`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LifetimeCtaMode {
    /// Route users into the app/download flow and keep StoreKit as source of truth.
    InApp,
    /// Route users through the server-backed Stripe checkout and web-license flow.
    Web,
}

impl LifetimeCtaMode {
    pub fn from_env(raw: Option<&'static str>) -> Self {
        match raw {
            Some("web") => Self::Web,
            Some("in-app") | Some("in_app") | Some("app") => Self::InApp,
            _ => Self::InApp,
        }
    }

    pub fn href(self) -> &'static str {
        match self {
            Self::InApp => "/download",
            Self::Web => "/checkout/lifetime",
        }
    }

    pub fn label(self) -> &'static str {
        match self {
            Self::InApp => "Buy Lifetime in App",
            Self::Web => "Buy Lifetime",
        }
    }

    pub fn secure_note(self) -> &'static str {
        match self {
            Self::InApp => "One-time lifetime unlock in app. No subscription.",
            Self::Web => "Secure Stripe checkout. Download the app and activate your lifetime unlock after payment.",
        }
    }
}

/// Site-wide configuration.
#[derive(Debug, Clone)]
pub struct SiteConfig {
    /// Current CTA mode
    pub cta_mode: CtaMode,
    /// Direct URL for the DMG download (usually /downloads/, optionally overridden)
    pub trial_url: Option<&'static str>,
    /// Direct URL for the ZIP archive.
    pub zip_url: &'static str,
    /// Direct URL for the checksums file.
    pub checksums_url: &'static str,
    /// Public release notes / asset page.
    pub release_url: &'static str,
    /// Public release version rendered in copy.
    pub release_version: &'static str,
    /// Path to the download page (always "/download")
    pub download_page_url: &'static str,
    /// URL for waitlist signup (if available)
    #[allow(dead_code)]
    pub waitlist_url: Option<&'static str>,
    /// URL for App Store (if available)
    pub store_url: Option<&'static str>,
    /// The effective lifetime checkout mode.
    #[allow(dead_code)]
    pub lifetime_cta_mode: LifetimeCtaMode,
    /// URL for the lifetime CTA target
    pub lifetime_cta_href: &'static str,
    /// Whether animations are enabled
    pub animation_enabled: bool,
    /// Whether email capture is enabled
    pub email_capture_enabled: bool,
}

/// Default configuration.
pub static CONFIG: LazyLock<SiteConfig> = LazyLock::new(|| {
    let lifetime_cta_mode = LifetimeCtaMode::from_env(option_env!("SITE_LIFETIME_MODE"));

    let release_version =
        option_env!("WINDOWDROP_RELEASE_VERSION").unwrap_or(DEFAULT_RELEASE_VERSION);
    let release_tag = option_env!("WINDOWDROP_RELEASE_TAG").unwrap_or(DEFAULT_RELEASE_TAG);
    let release_repo = option_env!("WINDOWDROP_RELEASE_REPO").unwrap_or(DEFAULT_RELEASE_REPO);
    let default_dmg_url = format!(
        "https://github.com/{release_repo}/releases/download/{release_tag}/WindowDrop-{release_version}.dmg"
    );
    let default_zip_url = format!(
        "https://github.com/{release_repo}/releases/download/{release_tag}/WindowDrop-{release_version}.zip"
    );
    let default_checksums_url = format!(
        "https://github.com/{release_repo}/releases/download/{release_tag}/WindowDrop-{release_version}-checksums.txt"
    );
    let default_release_url =
        format!("https://github.com/{release_repo}/releases/tag/{release_tag}");

    let dmg_url = option_env!("WINDOWDROP_DMG_URL")
        .map(str::to_string)
        .unwrap_or(default_dmg_url);
    let zip_url = option_env!("WINDOWDROP_ZIP_URL")
        .map(str::to_string)
        .unwrap_or(default_zip_url);
    let checksums_url = option_env!("WINDOWDROP_CHECKSUMS_URL")
        .map(str::to_string)
        .unwrap_or(default_checksums_url);
    let release_url = option_env!("WINDOWDROP_RELEASE_URL")
        .map(str::to_string)
        .unwrap_or(default_release_url);

    SiteConfig {
        cta_mode: CtaMode::TrialDownload,
        trial_url: Some(Box::leak(dmg_url.into_boxed_str())),
        zip_url: Box::leak(zip_url.into_boxed_str()),
        checksums_url: Box::leak(checksums_url.into_boxed_str()),
        release_url: Box::leak(release_url.into_boxed_str()),
        release_version,
        download_page_url: "/download",
        waitlist_url: None,
        store_url: option_env!("APP_STORE_URL"),
        lifetime_cta_mode,
        lifetime_cta_href: lifetime_cta_mode.href(),
        animation_enabled: true,
        email_capture_enabled: true,
    }
});

impl SiteConfig {
    /// Returns the primary CTA label based on the current mode.
    pub fn primary_cta_label(&self) -> &'static str {
        match self.cta_mode {
            CtaMode::TrialDownload => "Download Free",
            CtaMode::EarlyAccess => "Get Early Access",
            CtaMode::NotifyMe => "Get Notified",
            CtaMode::AppStoreLink => "Download on App Store",
        }
    }

    /// Returns the primary CTA URL, or None if unavailable.
    ///
    /// For download modes this points to the `/download` page (not the direct
    /// DMG URL) so the user lands on the page with system requirements and
    /// installation steps.
    pub fn primary_cta_url(&self) -> Option<&'static str> {
        match self.cta_mode {
            CtaMode::TrialDownload | CtaMode::EarlyAccess => Some(self.download_page_url),
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

#[cfg(test)]
mod tests {
    use super::{
        CtaMode, LifetimeCtaMode, SiteConfig, DEFAULT_CHECKSUMS_URL, DEFAULT_DMG_URL,
        DEFAULT_RELEASE_URL, DEFAULT_RELEASE_VERSION, DEFAULT_ZIP_URL,
    };

    #[test]
    fn lifetime_mode_defaults_to_in_app() {
        assert_eq!(LifetimeCtaMode::from_env(None), LifetimeCtaMode::InApp);
        assert_eq!(
            LifetimeCtaMode::from_env(Some("bogus")),
            LifetimeCtaMode::InApp
        );
    }

    #[test]
    fn in_app_mode_ignores_checkout_url() {
        assert_eq!(LifetimeCtaMode::InApp.href(), "/download");
        assert_eq!(LifetimeCtaMode::InApp.label(), "Buy Lifetime in App");
    }

    #[test]
    fn web_mode_routes_to_checkout_endpoint() {
        assert_eq!(LifetimeCtaMode::Web.href(), "/checkout/lifetime");
        assert_eq!(LifetimeCtaMode::Web.label(), "Buy Lifetime");
    }

    #[test]
    fn site_config_can_carry_in_app_mode() {
        let config = SiteConfig {
            cta_mode: CtaMode::TrialDownload,
            trial_url: Some(DEFAULT_DMG_URL),
            zip_url: DEFAULT_ZIP_URL,
            checksums_url: DEFAULT_CHECKSUMS_URL,
            release_url: DEFAULT_RELEASE_URL,
            release_version: DEFAULT_RELEASE_VERSION,
            download_page_url: "/download",
            waitlist_url: None,
            store_url: None,
            lifetime_cta_mode: LifetimeCtaMode::InApp,
            lifetime_cta_href: LifetimeCtaMode::InApp.href(),
            animation_enabled: true,
            email_capture_enabled: true,
        };

        assert_eq!(config.lifetime_cta_mode, LifetimeCtaMode::InApp);
        assert_eq!(config.lifetime_cta_href, "/download");
        assert_eq!(crate::web_license::WEB_LICENSE_PRICE_LABEL, "$7.99");
    }
}
