use crate::components::cta::CtaPrimary;
use crate::components::faq_section::FaqSection;
use crate::components::hero_demo_block::HeroDemoBlock;
use crate::components::icons::{IconCompass, IconFolder, IconMail, IconTerminal, IconWindow};
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
            // Hero Demo Block (title → graphic → how it works → Replay)
            <section class="section demo-section" id="demo">
                <div class="container">
                    <HeroDemoBlock />
                </div>
            </section>

            // Value Section
            <ValueSection />

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
                                <IconTerminal size=32 />
                            </div>
                            <span class="app-name">"Terminal"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconMail size=32 />
                            </div>
                            <span class="app-name">"Mail"</span>
                        </div>
                        <div class="app-card">
                            <div class="app-icon-wrapper">
                                <IconWindow size=32 />
                            </div>
                            <span class="app-name">"Chrome, Firefox, Xcode & more"</span>
                        </div>
                    </div>
                </div>
            </section>

            // FAQ Section
            <FaqSection />

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
