use crate::components::cta::{CtaPrimary, CtaSecondary};
use crate::components::email_capture::EmailCapture;
use crate::components::faq_section::FaqSection;
use crate::components::hero_animation::HeroAnimation;
use crate::components::icons::{
    IconCompass, IconFolder, IconImage, IconMail, IconNotes, IconTextEdit,
};
use crate::components::value_section::ValueSection;
use crate::seo::meta::SeoMeta;
use leptos::*;

#[component]
pub fn Home() -> impl IntoView {
    view! {
        <SeoMeta
            title="Home"
            description="WindowDrop changes where new windows appear. Press ⌘N and the window appears under your mouse."
            path="/"
        />
        <div class="home-page">
            // Hero Section
            <section class="hero">
                <div class="container container-narrow">
                    <h1 class="hero-title">
                        "New windows appear "
                        <span class="text-gradient">"under your mouse."</span>
                    </h1>
                    <p class="hero-subhead">
                        "Press ⌘N. That's it."
                    </p>
                    <div class="hero-cta">
                        <CtaPrimary />
                        <CtaSecondary label="How it works" href="#how-it-works" />
                    </div>
                </div>
            </section>

            // Hero Animation Demo
            <section class="section demo-section" id="demo">
                <div class="container">
                    <HeroAnimation />
                </div>
            </section>

            // Value Section
            <ValueSection />

            // How it Works
            <section class="section how-it-works-section" id="how-it-works">
                <div class="container container-narrow">
                    <h2 class="section-title">"How it works"</h2>
                    <div class="how-it-works-steps">
                        <div class="step">
                            <div class="step-number">"1"</div>
                            <div class="step-content">
                                <h3 class="step-title">"Enable WindowDrop"</h3>
                                <p class="step-description">
                                    "Click the menu bar icon to arm the next window drop."
                                </p>
                            </div>
                        </div>
                        <div class="step">
                            <div class="step-number">"2"</div>
                            <div class="step-content">
                                <h3 class="step-title">"Position your cursor"</h3>
                                <p class="step-description">
                                    "Move your mouse to where you want the new window."
                                </p>
                            </div>
                        </div>
                        <div class="step">
                            <div class="step-number">"3"</div>
                            <div class="step-content">
                                <h3 class="step-title">"Open a new window"</h3>
                                <p class="step-description">
                                    "Press ⌘N in any supported app."
                                </p>
                            </div>
                        </div>
                        <div class="step">
                            <div class="step-number step-number-check">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"/>
                                </svg>
                            </div>
                            <div class="step-content">
                                <h3 class="step-title">"Window appears at cursor"</h3>
                                <p class="step-description">
                                    "The new window drops right where you need it."
                                </p>
                            </div>
                        </div>
                    </div>
                    <p class="how-it-works-note">
                        "WindowDrop uses macOS Accessibility to move windows. It does not read or access page content."
                    </p>
                </div>
            </section>

            // Supported Apps
            <section class="section apps-section">
                <div class="container container-narrow">
                    <h2 class="section-title">"Works with"</h2>
                    <div class="apps-grid">
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconFolder size=32 />
                            </div>
                            <span class="app-name">"Finder"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconCompass size=32 />
                            </div>
                            <span class="app-name">"Safari"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconImage size=32 />
                            </div>
                            <span class="app-name">"Preview"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconTextEdit size=32 />
                            </div>
                            <span class="app-name">"TextEdit"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconNotes size=32 />
                            </div>
                            <span class="app-name">"Notes"</span>
                        </div>
                        <div class="app-card app-card-coming">
                            <div class="app-icon-wrapper">
                                <IconMail size=32 />
                            </div>
                            <span class="app-name">"Mail"</span>
                            <span class="app-badge">"Soon"</span>
                        </div>
                    </div>
                </div>
            </section>

            // FAQ Section
            <FaqSection />

            // Email Capture (for notify mode)
            <section class="section email-section">
                <div class="container container-narrow">
                    <EmailCapture />
                </div>
            </section>

            // Final CTA
            <section class="section final-cta-section">
                <div class="container text-center">
                    <h2 class="section-title">"Try WindowDrop"</h2>
                    <p class="section-subtitle">
                        "Your windows appear where you are."
                    </p>
                    <div class="cta-buttons">
                        <CtaPrimary />
                    </div>
                </div>
            </section>
        </div>
    }
}
