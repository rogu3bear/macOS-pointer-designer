use crate::components::icons::{
    IconApple, IconCheckCircle, IconDownload, IconShieldCheck, IconTerminal,
};
use crate::components::{cta::CtaPrimary, email_capture::EmailCapture};
use crate::config::{LifetimeCtaMode, CONFIG};
use crate::seo::meta::SeoMeta;
use crate::web_license::WEB_LICENSE_PRICE_LABEL;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Download() -> impl IntoView {
    let dmg_url = CONFIG.trial_url;
    let lifetime_mode = CONFIG.lifetime_cta_mode;
    let has_download = dmg_url.is_some();
    let dmg_filename = dmg_url
        .and_then(|url| url.rsplit('/').next())
        .unwrap_or("WindowDrop.dmg")
        .to_string();
    let version_subtitle = dmg_filename
        .strip_prefix("WindowDrop-")
        .and_then(|name| name.strip_suffix(".dmg"))
        .map(|version| format!("Version {}", version))
        .unwrap_or_else(|| "Current release".to_string());
    let zip_url = dmg_url
        .and_then(|url| url.strip_suffix(".dmg"))
        .map(|stem| format!("{}.zip", stem));
    let zip_filename = zip_url
        .as_deref()
        .and_then(|url| url.rsplit('/').next())
        .unwrap_or("WindowDrop.zip")
        .to_string();
    let checksums_url = dmg_url
        .and_then(|url| url.strip_suffix(".dmg"))
        .map(|stem| format!("{}-checksums.txt", stem));
    let checksums_filename = checksums_url
        .as_deref()
        .and_then(|url| url.rsplit('/').next())
        .unwrap_or("WindowDrop-checksums.txt")
        .to_string();
    let verify_command = format!("shasum -a 256 {}", dmg_filename);
    let hero_note = if has_download {
        "Download links are provided above.".into_view()
    } else if CONFIG.primary_cta_is_email_capture() {
        "Coming soon. Join the waitlist below to be notified.".into_view()
    } else {
        "Coming soon.".into_view()
    };
    let install_step_one = if has_download {
        "Click the download button above to get the disk image.".into_view()
    } else {
        "When released, download the disk image from the button above.".into_view()
    };
    let zip_download_link = if let Some(url) = zip_url.clone() {
        view! {
            <a href=url class="download-link" rel="noopener noreferrer" target="_blank">
                "Download ZIP"
            </a>
        }
        .into_view()
    } else {
        view! { <span class="alternative-meta">"ZIP not available"</span> }.into_view()
    };
    let verify_instruction = if let Some(url) = checksums_url.clone() {
        view! {
            <>
                "Compare the output with "
                <a href=url rel="noopener noreferrer" target="_blank">{checksums_filename.clone()}</a>
                "."
            </>
        }
        .into_view()
    } else {
        view! { "Compare the output with the published checksums file." }.into_view()
    };
    let release_sections = if has_download {
        view! {
            <section class="section download-alternatives">
                <div class="container container-narrow">
                    <h2 class="section-title">"Alternative Downloads"</h2>
                    <div class="alternatives-grid">
                        <div class="alternative-card">
                            <div class="alternative-icon">
                                <IconDownload size=24 />
                            </div>
                            <div class="alternative-content">
                                <h3 class="alternative-title">"DMG Installer"</h3>
                                <p class="alternative-meta">{dmg_filename.clone()}</p>
                                <a href=dmg_url.unwrap_or("#") class="download-link" rel="noopener noreferrer" target="_blank">
                                    "Download DMG"
                                </a>
                            </div>
                            <span class="alternative-badge">"Recommended"</span>
                        </div>
                        <div class="alternative-card">
                            <div class="alternative-icon">
                                <IconTerminal size=24 />
                            </div>
                            <div class="alternative-content">
                                <h3 class="alternative-title">"ZIP Archive"</h3>
                                <p class="alternative-meta">{zip_filename.clone()}</p>
                                {zip_download_link}
                            </div>
                        </div>
                    </div>
                </div>
            </section>
            <section class="section download-verify">
                <div class="container container-narrow">
                    <h2 class="section-title">"Verify Your Download"</h2>
                    <p class="verify-intro">
                        "For security, verify your local file hash and compare it to the published checksums file."
                    </p>
                    <div class="verify-card">
                        <code class="verify-hash">{verify_command.clone()}</code>
                        <p class="verify-instruction">{verify_instruction}</p>
                    </div>
                </div>
            </section>
        }
        .into_view()
    } else {
        view! {
            <section class="section download-alternatives">
                <div class="container container-narrow">
                    <h2 class="section-title">"When Released"</h2>
                    <p class="download-when-released">
                        "WindowDrop will be available as a DMG installer and ZIP archive. Join the waitlist above to be notified."
                    </p>
                </div>
            </section>
        }
        .into_view()
    };

    view! {
        <SeoMeta
            title="Download"
            description="Download WindowDrop for macOS. System requirements and installation guide."
            path="/download"
        />
        <div class="download-page">
            // Hero Section
            <section class="download-hero">
                <div class="container container-narrow">
                    <div class="download-hero-icon">
                        <IconApple size=48 />
                    </div>
                    <h1 class="download-hero-title">"Download WindowDrop"</h1>
                    <p class="download-hero-subtitle">
                        {version_subtitle.clone()}
                    </p>
                    <div class="download-hero-cta">
                        {if let Some(url) = dmg_url {
                            view! {
                                <a href=url class="btn btn-primary btn-lg download-btn">
                                    "Download Free"
                                </a>
                            }.into_view()
                        } else {
                            view! {
                                <CtaPrimary class="btn-lg download-btn" />
                            }.into_view()
                        }}
                    </div>
                    <p class="download-hero-note">
                        {hero_note}
                    </p>
                </div>
            </section>

            // Email Capture (for notify/early-access-without-link mode)
            {move || {
                if CONFIG.primary_cta_is_email_capture() {
                    view! {
                        <section class="section email-section">
                            <div class="container container-narrow">
                                <EmailCapture />
                            </div>
                        </section>
                    }.into_view()
                } else {
                    view! { <></> };
                    ().into_view()
                }
            }}

            // Requirements Section
            <section class="section download-requirements">
                <div class="container container-narrow">
                    <h2 class="section-title">"System Requirements"</h2>
                    <div class="requirements-grid">
                        <div class="requirement-card">
                            <div class="requirement-icon">
                                <IconApple size=24 />
                            </div>
                            <div class="requirement-content">
                                <h3 class="requirement-title">"macOS"</h3>
                                <p class="requirement-value">"Ventura 13.0 or later"</p>
                            </div>
                        </div>
                        <div class="requirement-card">
                            <div class="requirement-icon">
                                <IconShieldCheck size=24 />
                            </div>
                            <div class="requirement-content">
                                <h3 class="requirement-title">"Permissions"</h3>
                                <p class="requirement-value">"Accessibility access required"</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            // Installation Steps (wording adapts when no download yet)
            <section class="section download-install">
                <div class="container container-narrow">
                    <h2 class="section-title">"Installation"</h2>
                    <div class="install-steps">
                        <div class="install-step">
                            <div class="install-step-number">"1"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Download the DMG"</h3>
                                <p class="install-step-description">
                                    {install_step_one}
                                </p>
                            </div>
                        </div>
                        <div class="install-step">
                            <div class="install-step-number">"2"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Open the DMG"</h3>
                                <p class="install-step-description">
                                    "Double-click the downloaded file to mount it."
                                </p>
                            </div>
                        </div>
                        <div class="install-step">
                            <div class="install-step-number">"3"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Drag to Applications"</h3>
                                <p class="install-step-description">
                                    "Drag WindowDrop.app to your Applications folder."
                                </p>
                            </div>
                        </div>
                        <div class="install-step">
                            <div class="install-step-number">"4"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Grant Accessibility Access"</h3>
                                <p class="install-step-description">
                                    "On first launch, allow WindowDrop in System Settings → Privacy & Security → Accessibility."
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="section download-install">
                <div class="container container-narrow">
                    <h2 class="section-title">"Free + Lifetime Unlock"</h2>
                    <div class="install-steps">
                        <div class="install-step">
                            <div class="install-step-number">"Free"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Use Finder at no cost"</h3>
                                <p class="install-step-description">
                                    "WindowDrop works with Finder in the free tier."
                                </p>
                            </div>
                        </div>
                        {move || match lifetime_mode {
                            LifetimeCtaMode::InApp => view! {
                                <>
                                    <div class="install-step">
                                        <div class="install-step-number">{WEB_LICENSE_PRICE_LABEL}</div>
                                        <div class="install-step-content">
                                            <h3 class="install-step-title">"Unlock all supported apps in-app"</h3>
                                            <p class="install-step-description">
                                                "Open WindowDrop Preferences and choose Unlock In App for a one-time lifetime unlock."
                                            </p>
                                        </div>
                                    </div>
                                    <div class="install-step">
                                        <div class="install-step-number">"Restore"</div>
                                        <div class="install-step-content">
                                            <h3 class="install-step-title">"Already purchased?"</h3>
                                            <p class="install-step-description">
                                                "Use Restore Purchases in Preferences on a new Mac or reinstall."
                                            </p>
                                        </div>
                                    </div>
                                </>
                            }.into_view(),
                            LifetimeCtaMode::Web => view! {
                                <>
                                    <div class="install-step">
                                        <div class="install-step-number">{WEB_LICENSE_PRICE_LABEL}</div>
                                        <div class="install-step-content">
                                            <h3 class="install-step-title">"Buy once on the website"</h3>
                                            <p class="install-step-description">
                                                "Use the pricing page to complete a one-time Stripe checkout for the lifetime unlock."
                                            </p>
                                        </div>
                                    </div>
                                    <div class="install-step">
                                        <div class="install-step-number">"Activate"</div>
                                        <div class="install-step-content">
                                            <h3 class="install-step-title">"Open the activation link or paste the code"</h3>
                                            <p class="install-step-description">
                                                "After payment, download WindowDrop and activate it from the checkout success page or by pasting the signed activation code into Preferences → Access while online."
                                            </p>
                                        </div>
                                    </div>
                                    <div class="install-step">
                                        <div class="install-step-number">"Recover"</div>
                                        <div class="install-step-content">
                                            <h3 class="install-step-title">"Need it again later?"</h3>
                                            <p class="install-step-description">
                                                "Use "
                                                <A href="/checkout/recover">"Recover web purchase"</A>
                                                " with the checkout email to resend the activation code."
                                            </p>
                                        </div>
                                    </div>
                                </>
                            }.into_view(),
                        }}
                    </div>
                </div>
            </section>

            // Alternative Downloads (only when download exists)
            {release_sections}

            // Links Section
            <section class="section download-links">
                <div class="container container-narrow text-center">
                    <div class="download-links-grid">
                        <A href="/changelog" class="download-link">
                            <IconCheckCircle size=20 />
                            "Release Notes"
                        </A>
                        <A href="/support" class="download-link">
                            <IconShieldCheck size=20 />
                            "Need Help?"
                        </A>
                    </div>
                </div>
            </section>
        </div>
    }
}
