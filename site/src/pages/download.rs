use crate::components::icons::{
    IconApple, IconCheckCircle, IconDownload, IconShieldCheck, IconTerminal,
};
use crate::components::{cta::CtaPrimary, email_capture::EmailCapture};
use crate::config::CONFIG;
use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Download() -> impl IntoView {
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
                        "Version 0.1.0 (Preview)"
                    </p>
                    <div class="download-hero-cta">
                        <CtaPrimary class="btn-lg download-btn" />
                    </div>
                    <p class="download-hero-note">
                        {move || {
                            if CONFIG.primary_cta_url().is_some() {
                                "Download links are provided above.".into_view()
                            } else if CONFIG.primary_cta_is_email_capture() {
                                "Coming soon. Join the waitlist below to be notified.".into_view()
                            } else {
                                "Coming soon.".into_view()
                            }
                        }}
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

            // Installation Steps
            <section class="section download-install">
                <div class="container container-narrow">
                    <h2 class="section-title">"Installation"</h2>
                    <div class="install-steps">
                        <div class="install-step">
                            <div class="install-step-number">"1"</div>
                            <div class="install-step-content">
                                <h3 class="install-step-title">"Download the DMG"</h3>
                                <p class="install-step-description">
                                    "Click the download button above to get the disk image."
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

            // Alternative Downloads
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
                                <p class="alternative-meta">"WindowDrop-0.1.0.dmg · 8 MB"</p>
                            </div>
                            <span class="alternative-badge">"Recommended"</span>
                        </div>
                        <div class="alternative-card">
                            <div class="alternative-icon">
                                <IconTerminal size=24 />
                            </div>
                            <div class="alternative-content">
                                <h3 class="alternative-title">"ZIP Archive"</h3>
                                <p class="alternative-meta">"WindowDrop-0.1.0.zip · 8 MB"</p>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            // Verification Section
            <section class="section download-verify">
                <div class="container container-narrow">
                    <h2 class="section-title">"Verify Your Download"</h2>
                    <p class="verify-intro">
                        "For security, you can verify the download using the SHA-256 checksum:"
                    </p>
                    <div class="verify-card">
                        <code class="verify-hash">"SHA-256: (published with release)"</code>
                        <p class="verify-instruction">
                            "Run "<code>"shasum -a 256 WindowDrop-0.1.0.dmg"</code>" in Terminal to verify."
                        </p>
                    </div>
                </div>
            </section>

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
