use crate::components::cta::CtaPrimary;
use crate::components::icons::{IconCheckCircle, IconClock, IconStar, IconTag};
use crate::seo::meta::SeoMeta;
use leptos::*;

const CURRENT_RELEASE_VERSION: &str = match option_env!("WINDOWDROP_RELEASE_VERSION") {
    Some(version) => version,
    None => "1.1.0",
};

#[component]
pub fn Changelog() -> impl IntoView {
    view! {
        <SeoMeta
            title="Changelog"
            description="WindowDrop release notes and version history."
            path="/changelog"
        />
        <div class="changelog-page">
            // Hero
            <section class="changelog-hero">
                <div class="container container-narrow">
                    <div class="changelog-hero-icon">
                        <IconClock size=48 />
                    </div>
                    <h1 class="changelog-hero-title">"Changelog"</h1>
                    <p class="changelog-hero-subtitle">
                        "Version history and release notes"
                    </p>
                </div>
            </section>

            // Timeline
            <section class="section changelog-timeline">
                <div class="container container-narrow">

                    // Current release
                    <div class="changelog-entry">
                        <div class="changelog-entry-header">
                            <span class="changelog-version">{CURRENT_RELEASE_VERSION}</span>
                            <span class="changelog-date">"Current downloadable release"</span>
                            <span class="changelog-badge changelog-badge-current">"Current"</span>
                        </div>
                        <div class="changelog-entry-content">
                            <h3 class="changelog-entry-title">"Release Truth + Download Update"</h3>
                            <p class="changelog-entry-description">
                                "The current public release aligns versioned downloads, pricing copy, release notes, and support guidance around the safe in-app purchase path."
                            </p>
                            <h4 class="changelog-section-title">"Highlights"</h4>
                            <ul class="changelog-list">
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Download page now publishes versioned DMG, ZIP, and checksum files for the current release"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Pricing and download pages now keep the public lifetime path on the app/download flow by default"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Release notes and support copy now match the downloadable build version and the current selectable placement modes"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Finder stays free, while browsers, terminals, mail apps, and IDEs remain part of the one-time lifetime unlock"</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    // Version 1.0.3
                    <div class="changelog-entry">
                        <div class="changelog-entry-header">
                            <span class="changelog-version">"1.0.3"</span>
                            <span class="changelog-date">"February 2026"</span>
                        </div>
                        <div class="changelog-entry-content">
                            <h3 class="changelog-entry-title">"Pricing + Access Update"</h3>
                            <p class="changelog-entry-description">
                                "Free Finder tier and in-app lifetime unlock for all supported apps."
                            </p>
                            <h4 class="changelog-section-title">"Features"</h4>
                            <ul class="changelog-list">
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Free mode now includes Finder support with no subscription"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"One-time lifetime unlock ($7.99) for all supported apps"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"One-shot mode: Arm once, position one window"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Always-on mode: Every new window appears at cursor"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Finder support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Safari support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Chrome, Firefox, Edge, Brave, Arc support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Terminal, iTerm2, Warp, WezTerm support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Mail, Outlook, Spark, Mimestream support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Xcode, VS Code, Cursor, IntelliJ support"</span>
                                </li>
                            </ul>
                            <h4 class="changelog-section-title">"Placement Modes"</h4>
                            <ul class="changelog-list">
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Cursor + Close Button: Close button under cursor (default)"</span>
                                </li>
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Screen Center: Window centered on active display"</span>
                                </li>
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Titlebar Grab Zone: Title bar at cursor for easy dragging"</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                </div>
            </section>

            // Download CTA
            <section class="section changelog-subscribe">
                <div class="container container-narrow text-center">
                    <IconTag size=32 />
                    <h2 class="subscribe-title">"Get WindowDrop"</h2>
                    <p class="subscribe-description">
                        "Try it free, then unlock with a one-time purchase."
                    </p>
                    <div class="changelog-subscribe-cta">
                        <CtaPrimary />
                    </div>
                </div>
            </section>
        </div>
    }
}
