use crate::components::icons::{IconCheckCircle, IconClock, IconStar, IconTag, IconZap};
use crate::seo::meta::SeoMeta;
use leptos::*;

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

                    // Coming Soon
                    <div class="changelog-entry changelog-entry-upcoming">
                        <div class="changelog-entry-header">
                            <span class="changelog-version">"0.2.0"</span>
                            <span class="changelog-badge changelog-badge-soon">"Coming Soon"</span>
                        </div>
                        <div class="changelog-entry-content">
                            <h3 class="changelog-entry-title">"Mail Support & More Apps"</h3>
                            <ul class="changelog-list">
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Mail.app support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Calendar.app support"</span>
                                </li>
                                <li class="changelog-item changelog-item-improved">
                                    <IconZap size=16 />
                                    <span>"Improved detection for dialogs and sheets"</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    // Version 0.1.0
                    <div class="changelog-entry">
                        <div class="changelog-entry-header">
                            <span class="changelog-version">"0.1.0"</span>
                            <span class="changelog-date">"Preview Release"</span>
                            <span class="changelog-badge changelog-badge-current">"Current"</span>
                        </div>
                        <div class="changelog-entry-content">
                            <h3 class="changelog-entry-title">"First Public Preview"</h3>
                            <p class="changelog-entry-description">
                                "The first release of WindowDrop, bringing intelligent window positioning to macOS."
                            </p>
                            <h4 class="changelog-section-title">"Features"</h4>
                            <ul class="changelog-list">
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
                                    <span>"Preview support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"TextEdit support"</span>
                                </li>
                                <li class="changelog-item changelog-item-new">
                                    <IconStar size=16 />
                                    <span>"Notes support"</span>
                                </li>
                            </ul>
                            <h4 class="changelog-section-title">"Placement Modes"</h4>
                            <ul class="changelog-list">
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Cursor: Window top-left at mouse position"</span>
                                </li>
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Screen Center: Window centered on active display"</span>
                                </li>
                                <li class="changelog-item">
                                    <IconCheckCircle size=16 />
                                    <span>"Title Bar: Window title bar at cursor for easy dragging"</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                </div>
            </section>

            // Subscribe
            <section class="section changelog-subscribe">
                <div class="container container-narrow text-center">
                    <IconTag size=32 />
                    <h2 class="subscribe-title">"Stay Updated"</h2>
                    <p class="subscribe-description">
                        "Join our mailing list to get notified about new releases."
                    </p>
                </div>
            </section>
        </div>
    }
}
