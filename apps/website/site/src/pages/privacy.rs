use crate::components::icons::{IconCheckCircle, IconEyeOff, IconShieldCheck, IconWifiOff};
use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Privacy() -> impl IntoView {
    view! {
        <SeoMeta
            title="Privacy Policy"
            description="WindowDrop privacy policy. Your data stays on your Mac. No tracking, no collection."
            path="/privacy"
        />
        <div class="privacy-page privacy-page-policy">
            // Hero - formal policy
            <section class="privacy-hero">
                <div class="container container-narrow">
                    <div class="privacy-hero-icon">
                        <IconShieldCheck size=48 />
                    </div>
                    <h1 class="privacy-hero-title">"Privacy Policy"</h1>
                    <p class="privacy-hero-subtitle">
                        "Last updated: 2026. How WindowDrop handles your data."
                    </p>
                </div>
            </section>

            // Summary
            <section class="section privacy-promises">
                <div class="container container-narrow">
                    <h2 class="section-title">"Summary"</h2>
                    <p class="privacy-intro">
                        "WindowDrop does not collect, store, or transmit personal data. The app runs entirely on your Mac. This website does not use cookies or tracking. For your control over data, see "
                        <A href="/privacy-choices" class="privacy-link">"Privacy Choices"</A>
                        "."
                    </p>
                    <div class="promises-grid">
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconEyeOff size=28 />
                            </div>
                            <h3 class="promise-title">"No Data Collection"</h3>
                            <p class="promise-description">
                                "WindowDrop does not collect, store, or transmit any personal data. Period."
                            </p>
                        </div>
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconWifiOff size=28 />
                            </div>
                            <h3 class="promise-title">"No Network Requests"</h3>
                            <p class="promise-description">
                                "The app works entirely offline. It never contacts external servers."
                            </p>
                        </div>
                            <div class="promise-card">
                                <div class="promise-icon">
                                    <IconShieldCheck size=28 />
                                </div>
                                <h3 class="promise-title">"No Tracking"</h3>
                                <p class="promise-description">
                                    "No third-party analytics, no cookies, no tracking scripts. Just a utility that does its job."
                                </p>
                            </div>
                    </div>
                </div>
            </section>

            // Detailed Policy
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"In Detail"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What WindowDrop Does"</h3>
                        <p>
                            "WindowDrop monitors for new window creation events and repositions windows to your cursor location. It uses the macOS Accessibility API to move windows — the same API used by screen readers and other assistive tools."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What WindowDrop Does NOT Do"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not capture keystrokes or screen content"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not read the contents of your windows"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not access your files or browsing history"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not send any data to external servers"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not use cookies or tracking technologies"</span>
                            </li>
                        </ul>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Accessibility Permission"</h3>
                        <p>
                            "WindowDrop requires Accessibility permission to reposition windows. This is the minimum permission needed to move windows on macOS. You can revoke this permission at any time in System Settings → Privacy & Security → Accessibility."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Diagnostics"</h3>
                        <p>
                            "If you encounter issues, you can optionally share diagnostic logs with us. These logs contain only window position data and app names — no personal content. Sharing is always opt-in and initiated by you."
                        </p>
                    </div>

                        <div class="privacy-section">
                            <h3 class="privacy-section-title">"This Website"</h3>
                            <p>
                                "This website does not use cookies, third-party analytics, or tracking scripts. We don't know who visits this site or how they use it."
                            </p>
                            <p>
                                "In development builds, basic interaction events may be logged to the browser console for debugging."
                            </p>
                        </div>
                </div>
            </section>

            // Contact
            <section class="section privacy-contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Contact"</h2>
                    <p>
                        "For privacy questions or to exercise your rights, contact "
                        <a href="mailto:support@windowdrop.pro" class="privacy-email">"support@windowdrop.pro"</a>
                        "."
                    </p>
                    <p class="privacy-policy-footer">
                        <A href="/privacy-choices" class="privacy-link">"Your Privacy Choices"</A>
                        " | "
                        <A href="/support" class="privacy-link">"Support"</A>
                    </p>
                </div>
            </section>
        </div>
    }
}
