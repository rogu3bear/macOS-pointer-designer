use crate::components::icons::{
    IconBook, IconCheckCircle, IconMail, IconQuestion, IconSupport, IconTerminal,
};
use crate::content::markdown::render_markdown;
use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Support() -> impl IntoView {
    let faq_html = render_markdown(include_str!("../content/faq.md"));

    view! {
        <SeoMeta
            title="Support"
            description="Get help with WindowDrop. FAQ, troubleshooting, and contact information."
            path="/support"
        />
        <div class="support-page">
            // Hero
            <section class="support-hero">
                <div class="container container-narrow">
                    <div class="support-hero-icon">
                        <IconSupport size=48 />
                    </div>
                    <h1 class="support-hero-title">"Support Center"</h1>
                    <p class="support-hero-subtitle">
                        "Get help with WindowDrop. We're here to assist."
                    </p>
                </div>
            </section>

            // Quick Links
            <section class="section support-quick">
                <div class="container container-narrow">
                    <h2 class="section-title">"Quick Help"</h2>
                    <div class="quick-links-grid">
                        <A href="#faq" class="quick-link-card">
                            <div class="quick-link-icon">
                                <IconQuestion size=24 />
                            </div>
                            <h3 class="quick-link-title">"FAQ"</h3>
                            <p class="quick-link-description">"Common questions answered"</p>
                        </A>
                        <A href="#troubleshooting" class="quick-link-card">
                            <div class="quick-link-icon">
                                <IconTerminal size=24 />
                            </div>
                            <h3 class="quick-link-title">"Troubleshooting"</h3>
                            <p class="quick-link-description">"Fix common issues"</p>
                        </A>
                        <A href="#contact" class="quick-link-card">
                            <div class="quick-link-icon">
                                <IconMail size=24 />
                            </div>
                            <h3 class="quick-link-title">"Contact Us"</h3>
                            <p class="quick-link-description">"Get personalized help"</p>
                        </A>
                        <A href="/changelog" class="quick-link-card">
                            <div class="quick-link-icon">
                                <IconBook size=24 />
                            </div>
                            <h3 class="quick-link-title">"Release Notes"</h3>
                            <p class="quick-link-description">"What's new and fixed"</p>
                        </A>
                    </div>
                </div>
            </section>

            // Troubleshooting
            <section class="section support-troubleshooting" id="troubleshooting">
                <div class="container container-narrow">
                    <h2 class="section-title">"Troubleshooting"</h2>

                    <div class="troubleshoot-item">
                        <h3 class="troubleshoot-title">"WindowDrop isn't moving my windows"</h3>
                        <div class="troubleshoot-content">
                            <ol class="troubleshoot-steps">
                                <li>"Open System Settings → Privacy & Security → Accessibility"</li>
                                <li>"Find WindowDrop in the list"</li>
                                <li>"Toggle it off, then back on"</li>
                                <li>"Restart WindowDrop from the menu bar"</li>
                            </ol>
                        </div>
                    </div>

                    <div class="troubleshoot-item">
                        <h3 class="troubleshoot-title">"Windows appear in the wrong position"</h3>
                        <div class="troubleshoot-content">
                            <p>"This can happen with certain apps that use non-standard window management. Check the placement mode in WindowDrop settings:"</p>
                            <ul class="troubleshoot-options">
                                <li><strong>"Cursor"</strong>" — Window appears under your mouse (default)"</li>
                                <li><strong>"Screen Center"</strong>" — Window appears in the center of the screen"</li>
                                <li><strong>"Title Bar"</strong>" — Window appears so the title bar is at cursor"</li>
                            </ul>
                        </div>
                    </div>

                    <div class="troubleshoot-item">
                        <h3 class="troubleshoot-title">"WindowDrop doesn't work with a specific app"</h3>
                        <div class="troubleshoot-content">
                            <p>"WindowDrop currently supports:"</p>
                            <ul class="troubleshoot-apps">
                                <li><IconCheckCircle size=16 />" Finder"</li>
                                <li><IconCheckCircle size=16 />" Safari"</li>
                                <li><IconCheckCircle size=16 />" Preview"</li>
                                <li><IconCheckCircle size=16 />" TextEdit"</li>
                                <li><IconCheckCircle size=16 />" Notes"</li>
                            </ul>
                            <p>"More apps are being added. Email us with app requests!"</p>
                        </div>
                    </div>
                </div>
            </section>

            // Diagnostics
            <section class="section support-diagnostics">
                <div class="container container-narrow">
                    <h2 class="section-title">"Sharing Diagnostics"</h2>
                    <p class="diagnostics-intro">
                        "If you need to report an issue, you can share diagnostic information:"
                    </p>
                    <div class="diagnostics-steps">
                        <div class="diagnostics-step">
                            <span class="diagnostics-step-number">"1"</span>
                            <span>"Click the WindowDrop icon in the menu bar"</span>
                        </div>
                        <div class="diagnostics-step">
                            <span class="diagnostics-step-number">"2"</span>
                            <span>"Choose 'Copy Debug Log'"</span>
                        </div>
                        <div class="diagnostics-step">
                            <span class="diagnostics-step-number">"3"</span>
                            <span>"Paste into your support email"</span>
                        </div>
                    </div>
                </div>
            </section>

            // FAQ
            <section class="section support-faq" id="faq">
                <div class="container container-narrow">
                    <h2 class="section-title">"Frequently Asked Questions"</h2>
                    <div class="faq-container" inner_html=faq_html></div>
                </div>
            </section>

            // Contact
            <section class="section support-contact" id="contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Still Need Help?"</h2>
                    <p class="contact-intro">
                        "Email us with your macOS version and WindowDrop version."
                    </p>
                    <a href="mailto:support@windowdrop.pro" class="btn btn-primary">
                        <IconMail size=20 />
                        "Email Support"
                    </a>
                    <p class="contact-note">
                        "We typically respond within 24 hours."
                    </p>
                </div>
            </section>
        </div>
    }
}
