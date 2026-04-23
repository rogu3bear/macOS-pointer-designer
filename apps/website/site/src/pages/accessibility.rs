use crate::components::icons::{IconCheckCircle, IconShieldCheck};
use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Accessibility() -> impl IntoView {
    view! {
        <SeoMeta
            title="Accessibility"
            description="WindowDrop accessibility: why we need the permission, how to grant it, and how the app supports accessible use."
            path="/accessibility"
        />
        <div class="privacy-page">
            <section class="privacy-hero">
                <div class="container container-narrow">
                    <div class="privacy-hero-icon">
                        <IconShieldCheck size=48 />
                    </div>
                    <h1 class="privacy-hero-title">"Accessibility"</h1>
                    <p class="privacy-hero-subtitle">
                        "WindowDrop uses the same macOS APIs as VoiceOver and other assistive tools. Here's why, and how to set it up."
                    </p>
                </div>
            </section>

            <section class="section privacy-promises">
                <div class="container container-narrow">
                    <h2 class="section-title">"Why Accessibility Permission?"</h2>
                    <p class="privacy-intro">
                        "WindowDrop needs Accessibility permission to move windows. macOS provides no other API for this. The same Accessibility API (AXUIElement, AXObserver) is used by VoiceOver, screen readers, and other assistive technologies."
                    </p>
                    <div class="promises-grid">
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Window Movement Only"</h3>
                            <p class="promise-description">
                                "We read window position and size, then set new positions. We do not read window content, keystrokes, or screen pixels."
                            </p>
                        </div>
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Minimum Required"</h3>
                            <p class="promise-description">
                                "We use only the attributes needed to move windows: position, size, role, subrole. No broader access."
                            </p>
                        </div>
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Revocable Anytime"</h3>
                            <p class="promise-description">
                                "You can revoke permission in System Settings → Privacy & Security → Accessibility. The app will prompt you to re-enable if needed."
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"How to Grant Permission"</h2>
                    <ol class="accessibility-steps">
                        <li class="accessibility-step">
                            <span class="accessibility-step-num">"1"</span>
                            <span>"Open System Settings (or System Preferences on older macOS)"</span>
                        </li>
                        <li class="accessibility-step">
                            <span class="accessibility-step-num">"2"</span>
                            <span>"Go to Privacy & Security → Accessibility"</span>
                        </li>
                        <li class="accessibility-step">
                            <span class="accessibility-step-num">"3"</span>
                            <span>"Enable WindowDrop in the list"</span>
                        </li>
                        <li class="accessibility-step">
                            <span class="accessibility-step-num">"4"</span>
                            <span>"Relaunch WindowDrop if it was already running"</span>
                        </li>
                    </ol>
                    <p>
                        "If WindowDrop prompts you, you can click \"Open Accessibility Settings\" to jump directly there."
                    </p>
                </div>
            </section>

            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Keyboard & App Accessibility"</h2>
                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Hotkeys"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span><strong>"Ctrl+Opt+W"</strong> - Arm next window (switch to Armed Once mode)</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span><strong>"Ctrl+Opt+Shift+W"</strong> - Toggle Always On mode</span>
                            </li>
                        </ul>
                        <p>"All menu actions are available via keyboard. The menu bar icon is focusable and has an accessibility description."</p>
                    </div>
                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What We Don't Do"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"We do not capture keystrokes or screen content"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"We do not read the contents of your windows"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"We do not move the mouse cursor"</span>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>

            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"This Website"</h2>
                    <p>
                        "This site is built with accessibility in mind: semantic HTML, skip links, visible focus states, and sufficient color contrast. If you encounter issues, please "
                        <A href="/support" class="privacy-link">"contact us"</A>
                        "."
                    </p>
                </div>
            </section>
        </div>
    }
}
