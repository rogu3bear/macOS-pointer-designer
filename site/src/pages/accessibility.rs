use crate::components::icons::{IconAccessibility, IconCheckCircle};
use crate::seo::meta::SeoMeta;
use leptos::*;

#[component]
pub fn Accessibility() -> impl IntoView {
    view! {
        <SeoMeta
            title="Accessibility"
            description="WindowDrop accessibility statement. Our commitment to making window management accessible to everyone."
            path="/accessibility"
        />
        <div class="accessibility-page">
            // Hero
            <section class="accessibility-hero">
                <div class="container container-narrow">
                    <div class="accessibility-hero-icon">
                        <IconAccessibility size=48 />
                    </div>
                    <h1 class="accessibility-hero-title">"Accessibility Statement"</h1>
                    <p class="accessibility-hero-subtitle">
                        "Our commitment to making WindowDrop usable by everyone."
                    </p>
                    <p class="privacy-effective-date">
                        "Last updated: February 15, 2026"
                    </p>
                </div>
            </section>

            // Commitment
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Our Commitment"</h2>

                    <div class="legal-section">
                        <p>
                            "WindowDrop is committed to ensuring digital accessibility for people of all abilities. We continually work to improve the user experience for everyone and apply relevant accessibility standards to our app and website."
                        </p>
                        <p>
                            "WindowDrop itself is built on the macOS Accessibility API \u{2014} the same framework that powers screen readers and assistive technologies. We believe the tools that leverage accessibility infrastructure should themselves be accessible."
                        </p>
                    </div>
                </div>
            </section>

            // Conformance Status
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Conformance Status"</h2>

                    <div class="legal-section">
                        <p>
                            "We aim to conform to the "
                            <strong>"Web Content Accessibility Guidelines (WCAG) 2.1 Level AA"</strong>
                            " for our website. The WindowDrop application follows Apple\u{2019}s "
                            <strong>"Human Interface Guidelines for Accessibility"</strong>
                            " and integrates with macOS built-in accessibility features."
                        </p>
                    </div>
                </div>
            </section>

            // App Accessibility Features
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"App Accessibility Features"</h2>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"macOS Integration"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"VoiceOver compatible"</strong>
                                    " \u{2014} WindowDrop\u{2019}s menu bar interface and preferences are accessible via VoiceOver"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Keyboard accessible"</strong>
                                    " \u{2014} All app controls can be operated using the keyboard alone"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"System appearance"</strong>
                                    " \u{2014} Respects your macOS display settings including Dark Mode, increased contrast, and reduced transparency"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Reduced motion"</strong>
                                    " \u{2014} Honors the macOS Reduce Motion preference for users sensitive to animation"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Native controls"</strong>
                                    " \u{2014} Uses standard macOS UI components that automatically support accessibility features"
                                </span>
                            </li>
                        </ul>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Window Management"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Non-disruptive"</strong>
                                    " \u{2014} WindowDrop repositions windows without stealing focus or interrupting your workflow"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Predictable behavior"</strong>
                                    " \u{2014} Windows always move to a predictable location (your cursor), reducing cognitive load"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"No required gestures"</strong>
                                    " \u{2014} WindowDrop works automatically without requiring complex mouse gestures, multi-finger trackpad actions, or precise targeting"
                                </span>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>

            // Website Accessibility
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Website Accessibility"</h2>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Features"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Semantic HTML"</strong>
                                    " \u{2014} Proper heading hierarchy, landmarks, and document structure"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Keyboard navigation"</strong>
                                    " \u{2014} All interactive elements are reachable and operable via keyboard"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Color contrast"</strong>
                                    " \u{2014} Text and interactive elements meet WCAG 2.1 AA contrast ratios"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Reduced motion"</strong>
                                    " \u{2014} Animations are disabled when the prefers-reduced-motion media query is active"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Responsive design"</strong>
                                    " \u{2014} Content is usable at all screen sizes and supports text scaling up to 200%"
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Link purpose"</strong>
                                    " \u{2014} Links are descriptive and indicate their destination"
                                </span>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>

            // Assistive Technology Compatibility
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Assistive Technology Compatibility"</h2>

                    <div class="legal-section">
                        <p>"WindowDrop is designed to be compatible with the following assistive technologies:"</p>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS VoiceOver (screen reader)"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS Voice Control"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS Switch Control"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS Full Keyboard Access"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS Zoom and Display Accommodations"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Third-party screen magnifiers"</span>
                            </li>
                        </ul>
                        <p>
                            "WindowDrop operates at the system level via the Accessibility API and does not interfere with other assistive technologies. It is designed to coexist with screen readers, switch devices, and other accessibility tools."
                        </p>
                    </div>
                </div>
            </section>

            // Known Limitations
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Known Limitations"</h2>

                    <div class="legal-section">
                        <p>
                            "While we strive for full accessibility, the following limitations currently exist:"
                        </p>
                        <ul class="legal-list">
                            <li>"WindowDrop\u{2019}s core function (repositioning windows to cursor location) inherently relies on a pointing device. Users who navigate exclusively via keyboard may not benefit from the primary window repositioning feature, though all configuration and controls remain fully keyboard accessible."</li>
                            <li>"Some third-party application windows may not respond to repositioning due to their own implementation choices. This is outside WindowDrop\u{2019}s control."</li>
                        </ul>
                    </div>
                </div>
            </section>

            // Standards and Guidelines
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Standards and Guidelines"</h2>

                    <div class="legal-section">
                        <p>"WindowDrop\u{2019}s accessibility efforts are guided by:"</p>
                        <ul class="legal-list">
                            <li>"Web Content Accessibility Guidelines (WCAG) 2.1, Level AA \u{2014} for our website"</li>
                            <li>"Apple Human Interface Guidelines: Accessibility \u{2014} for the macOS application"</li>
                            <li>"Section 508 of the Rehabilitation Act \u{2014} as a reference standard"</li>
                            <li>"EN 301 549 \u{2014} European accessibility standard for ICT products and services"</li>
                        </ul>
                    </div>
                </div>
            </section>

            // Assessment and Testing
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Assessment and Testing"</h2>

                    <div class="legal-section">
                        <p>
                            "We assess the accessibility of WindowDrop through the following methods:"
                        </p>
                        <ul class="legal-list">
                            <li>"Manual testing with macOS VoiceOver"</li>
                            <li>"Keyboard-only navigation testing"</li>
                            <li>"Color contrast verification against WCAG 2.1 AA requirements"</li>
                            <li>"Testing with macOS accessibility display settings (increased contrast, reduced motion, reduced transparency)"</li>
                            <li>"Automated accessibility audits for the website"</li>
                        </ul>
                    </div>
                </div>
            </section>

            // Feedback
            <section class="section privacy-contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Accessibility Feedback"</h2>
                    <p>
                        "We welcome your feedback on the accessibility of WindowDrop. If you encounter accessibility barriers, have suggestions for improvement, or need the information on this website in an alternative format, please contact us:"
                    </p>
                    <a href="mailto:support@windowdrop.pro" class="privacy-email">
                        "support@windowdrop.pro"
                    </a>
                    <p class="privacy-choices-policy-link">
                        "We aim to respond to accessibility feedback within 5 business days."
                    </p>
                </div>
            </section>
        </div>
    }
}
