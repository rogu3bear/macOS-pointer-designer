use crate::components::icons::{IconCheckCircle, IconEye};
use crate::seo::meta::SeoMeta;
use leptos::*;

#[component]
pub fn PrivacyChoices() -> impl IntoView {
    view! {
        <SeoMeta
            title="User Privacy Choices"
            description="Learn about your privacy choices and controls within WindowDrop. Manage accessibility permissions and understand your rights."
            path="/privacy-choices"
        />
        <div class="privacy-choices-page">
            // Hero
            <section class="privacy-choices-hero">
                <div class="container container-narrow">
                    <div class="privacy-choices-hero-icon">
                        <IconEye size=48 />
                    </div>
                    <h1 class="privacy-choices-hero-title">"User Privacy Choices"</h1>
                    <p class="privacy-choices-hero-subtitle">
                        "Your privacy controls for WindowDrop."
                    </p>
                </div>
            </section>

            // Overview
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Overview"</h2>

                    <div class="privacy-section">
                        <p>
                            "WindowDrop is designed with privacy as a core principle. Because WindowDrop collects no personal data and makes no network requests, your privacy choices are straightforward \u{2014} you are always in full control."
                        </p>
                        <p>
                            "This page explains the privacy-related controls available to you and how to manage them."
                        </p>
                    </div>
                </div>
            </section>

            // Accessibility Permission Control
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Accessibility Permission"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What It Controls"</h3>
                        <p>
                            "The Accessibility permission allows WindowDrop to detect new window creation events and reposition windows to your cursor. This is the only system permission WindowDrop requests."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Your Choices"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Grant permission"</strong>
                                    " \u{2014} WindowDrop can reposition windows. No data is collected or transmitted."
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Revoke permission"</strong>
                                    " \u{2014} WindowDrop cannot reposition windows. The app remains installed but non-functional."
                                </span>
                            </li>
                        </ul>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"How to Manage"</h3>
                        <div class="choices-steps">
                            <div class="choices-step">
                                <div class="choices-step-number">"1"</div>
                                <div class="choices-step-content">
                                    <p class="choices-step-title">"Open System Settings"</p>
                                    <p class="choices-step-description">"Click the Apple menu and select System Settings."</p>
                                </div>
                            </div>
                            <div class="choices-step">
                                <div class="choices-step-number">"2"</div>
                                <div class="choices-step-content">
                                    <p class="choices-step-title">"Navigate to Privacy & Security"</p>
                                    <p class="choices-step-description">"Select Privacy & Security from the sidebar, then click Accessibility."</p>
                                </div>
                            </div>
                            <div class="choices-step">
                                <div class="choices-step-number">"3"</div>
                                <div class="choices-step-content">
                                    <p class="choices-step-title">"Toggle WindowDrop"</p>
                                    <p class="choices-step-description">"Enable or disable the toggle next to WindowDrop to grant or revoke permission."</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            // Diagnostics Control
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Diagnostic Sharing"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What It Controls"</h3>
                        <p>
                            "If you experience issues with WindowDrop, you can optionally share diagnostic logs with our support team. Diagnostic sharing is entirely manual and opt-in."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Your Choices"</h3>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Do nothing"</strong>
                                    " \u{2014} No diagnostic data is ever sent. There is no automatic reporting."
                                </span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>
                                    <strong>"Share voluntarily"</strong>
                                    " \u{2014} When contacting support, you may manually copy and send diagnostic logs. These contain only window position data, application bundle identifiers, and version information."
                                </span>
                            </li>
                        </ul>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What Diagnostics Contain"</h3>
                        <p>
                            "Diagnostic logs include only: window position coordinates, application bundle identifiers (e.g., com.apple.Safari), event timestamps, and your macOS and WindowDrop version numbers. Diagnostics never include window content, personal data, file names, or browsing history."
                        </p>
                    </div>
                </div>
            </section>

            // App Store Privacy Label
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"App Store Privacy Label"</h2>

                    <div class="privacy-section">
                        <p>
                            "WindowDrop\u{2019}s App Store privacy nutrition label displays "
                            <strong>"\"Data Not Collected\""</strong>
                            " \u{2014} the strongest privacy designation available. This means:"
                        </p>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"No data is transmitted off your device"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"No data is linked to your identity"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"No data is used to track you across apps or websites"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"No third-party code collects data on our behalf"</span>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>

            // Uninstallation
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Uninstallation"</h2>

                    <div class="privacy-section">
                        <p>
                            "You can remove WindowDrop from your Mac at any time. Because WindowDrop stores no personal data, uninstalling the app removes everything. No data persists after uninstallation."
                        </p>
                        <p>
                            "To uninstall, move WindowDrop from your Applications folder to the Trash. The Accessibility permission entry will be automatically removed by macOS."
                        </p>
                    </div>
                </div>
            </section>

            // Your Rights
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Your Rights Under Privacy Laws"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"General Rights"</h3>
                        <p>
                            "Depending on your jurisdiction, you may have the right to access, correct, delete, and port your personal data. Because WindowDrop collects no personal data, these rights are inherently fulfilled \u{2014} there is no data for us to access, correct, delete, or transfer."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Right to Know (CCPA/CPRA)"</h3>
                        <p>
                            "California residents have the right to know what personal information is collected, used, and shared. WindowDrop collects no personal information. We do not sell or share personal information with third parties."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Do Not Sell or Share"</h3>
                        <p>
                            "WindowDrop does not sell your personal information. WindowDrop does not share your personal information for cross-context behavioral advertising."
                        </p>
                        <p>
                            "Because no personal information is collected, there is no information to sell or share. There is no need for a \u{201c}Do Not Sell or Share My Personal Information\u{201d} mechanism, as this right is inherently satisfied."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Data Portability"</h3>
                        <p>
                            "Under GDPR and CCPA, you have the right to receive your personal data in a portable format. Because WindowDrop collects no personal data, there is no data to export or transfer."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Data Protection (GDPR)"</h3>
                        <p>
                            "Residents of the European Economic Area have rights under the GDPR including data access, rectification, erasure, and portability. Because no personal data is collected or processed by WindowDrop, no data processing occurs that would require a lawful basis under the GDPR."
                        </p>
                        <p>
                            "If you believe your rights under the GDPR have been violated, you have the right to lodge a complaint with a data protection supervisory authority in your country of residence, place of work, or where the alleged violation occurred."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Do Not Track"</h3>
                        <p>
                            "WindowDrop honors Do Not Track signals by design. The app performs no tracking of any kind, regardless of your system or browser-level Do Not Track preferences."
                        </p>
                    </div>
                </div>
            </section>

            // How to Exercise Your Rights
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"How to Exercise Your Rights"</h2>

                    <div class="privacy-section">
                        <p>
                            "To exercise any privacy right, email "
                            <a href="mailto:support@windowdrop.pro">"support@windowdrop.pro"</a>
                            ". Please include:"
                        </p>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Your name"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"The specific right you want to exercise"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Any relevant details about your request"</span>
                            </li>
                        </ul>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Response Time"</h3>
                        <p>
                            "We will respond to your request within 30 days. For requests under GDPR Article 12, we will respond within one month as required."
                        </p>
                        <p>
                            "Because WindowDrop collects no personal data, most requests can be confirmed immediately."
                        </p>
                    </div>
                </div>
            </section>

            // Contact
            <section class="section privacy-contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Questions About Your Choices?"</h2>
                    <p>
                        "If you have questions about your privacy choices or need help managing your settings, contact us at:"
                    </p>
                    <a href="mailto:support@windowdrop.pro" class="privacy-email">
                        "support@windowdrop.pro"
                    </a>
                    <p class="privacy-choices-policy-link">
                        "For our complete privacy practices, see our "
                        <a href="/privacy">"Privacy Policy"</a>
                        "."
                    </p>
                </div>
            </section>
        </div>
    }
}
