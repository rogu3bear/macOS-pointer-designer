use crate::components::icons::{IconCheckCircle, IconEyeOff, IconShieldCheck, IconWifiOff};
use crate::seo::meta::SeoMeta;
use leptos::*;

#[component]
pub fn Privacy() -> impl IntoView {
    view! {
        <SeoMeta
            title="Privacy Policy"
            description="WindowDrop privacy policy. Your data stays on your Mac. No tracking, no collection, no network requests."
            path="/privacy"
        />
        <div class="privacy-page">
            // Hero
            <section class="privacy-hero">
                <div class="container container-narrow">
                    <div class="privacy-hero-icon">
                        <IconShieldCheck size=48 />
                    </div>
                    <h1 class="privacy-hero-title">"Privacy Policy"</h1>
                    <p class="privacy-hero-subtitle">
                        "WindowDrop respects your privacy. Your data stays on your Mac."
                    </p>
                    <p class="privacy-effective-date">
                        "Effective date: February 15, 2026"
                    </p>
                </div>
            </section>

            // Privacy Promises
            <section class="section privacy-promises">
                <div class="container container-narrow">
                    <h2 class="section-title">"Our Promises"</h2>
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

            // Scope of Policy
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Scope of This Policy"</h2>

                    <div class="privacy-section">
                        <p>
                            "This privacy policy covers the WindowDrop macOS application, the windowdrop.pro website, and any support interactions you may have with us. It does not cover third-party applications whose windows WindowDrop repositions \u{2014} those applications are governed by their own respective privacy policies."
                        </p>
                    </div>
                </div>
            </section>

            // Data Controller Identity
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Data Controller"</h2>

                    <div class="privacy-section">
                        <p>
                            "WindowDrop is developed and maintained by James KC Auchterlonie as an independent developer, based in Australia."
                        </p>
                        <p>
                            "For any privacy-related inquiries, you can contact us at "
                            <a href="mailto:support@windowdrop.pro">"support@windowdrop.pro"</a>
                            "."
                        </p>
                    </div>
                </div>
            </section>

            // Information We Collect
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Information We Collect"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Personal Information"</h3>
                        <p>
                            "WindowDrop does not collect any personal information. We do not collect your name, email address, location, contacts, browsing history, search history, or any other personally identifiable information."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Usage Data"</h3>
                        <p>
                            "WindowDrop does not collect usage data. We do not track how you use the app, which windows you move, how often you use the app, or any behavioral data."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Device Information"</h3>
                        <p>
                            "WindowDrop does not collect device information. We do not access your hardware model, operating system version, unique device identifiers, or any other device-level data."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Third-Party Data Sharing"</h3>
                        <p>
                            "WindowDrop does not share data with third parties because there is no data to share. We do not integrate third-party SDKs, analytics tools, advertising networks, or data brokers."
                        </p>
                    </div>
                </div>
            </section>

            // What WindowDrop Does
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"How WindowDrop Works"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What WindowDrop Does"</h3>
                        <p>
                            "WindowDrop monitors for new window creation events and repositions windows to your cursor location. It uses the macOS Accessibility API to move windows \u{2014} the same API used by screen readers and other assistive tools. All processing happens locally on your Mac."
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
                                <span>"Does not access your files, documents, or browsing history"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not send any data to external servers"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not use cookies or tracking technologies"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not access your contacts, calendar, photos, or other personal data"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Does not record or transmit window titles or application names"</span>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>

            // Accessibility Permission
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Accessibility Permission"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Why Accessibility Permission Is Required"</h3>
                        <p>
                            "WindowDrop requires the macOS Accessibility permission to detect new window creation events and reposition windows. This is the minimum system permission needed to move windows that belong to other applications on macOS. Without this permission, WindowDrop cannot function."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"What Accessibility Permission Grants"</h3>
                        <p>
                            "The Accessibility permission allows WindowDrop to interact with the window management system. WindowDrop uses this permission exclusively to detect when new windows appear and to set their position. It does not use this permission to read window content, capture text, monitor input, or access any data within your applications."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"How to Manage This Permission"</h3>
                        <p>
                            "You can grant or revoke Accessibility permission at any time in System Settings \u{2192} Privacy & Security \u{2192} Accessibility. Revoking this permission will prevent WindowDrop from repositioning windows, but the app will continue to run and can be re-enabled at any time."
                        </p>
                    </div>
                </div>
            </section>

            // App Store Privacy
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"App Store Privacy Label"</h2>

                    <div class="privacy-section">
                        <p>
                            "WindowDrop\u{2019}s App Store privacy label states: "
                            <strong>"\"Data Not Collected.\""</strong>
                            " This means WindowDrop does not collect any data from the app, as defined by Apple\u{2019}s App Store guidelines. No data is transmitted off your device, and no data is accessible to us or any third party."
                        </p>
                        <p>
                            "This label is accurate and reflects WindowDrop\u{2019}s complete privacy practices. WindowDrop does not use any third-party SDKs or frameworks that collect data on our behalf."
                        </p>
                    </div>
                </div>
            </section>

            // Diagnostics
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Diagnostics"</h2>

                    <div class="privacy-section">
                        <p>
                            "If you encounter issues with WindowDrop, you may optionally choose to share diagnostic information with us by contacting support. Diagnostic logs are generated locally on your Mac and contain only:"
                        </p>
                        <ul class="privacy-list">
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Window position coordinates (x, y)"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Application bundle identifiers (e.g., com.apple.Safari)"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"Timestamp of window events"</span>
                            </li>
                            <li class="privacy-list-item">
                                <IconCheckCircle size=18 />
                                <span>"macOS version and WindowDrop version"</span>
                            </li>
                        </ul>
                        <p>
                            "Diagnostic logs never contain window content, personal data, file paths, or any information beyond what is listed above. Sharing diagnostics is always opt-in \u{2014} you must manually copy and send the log to us. We do not have any mechanism to collect diagnostics automatically."
                        </p>
                        <p>
                            "If you share diagnostic logs with us, we retain them only for the duration needed to resolve your issue and then delete them. We do not use diagnostic data for any purpose other than troubleshooting."
                        </p>
                    </div>
                </div>
            </section>

            // Data Retention and Deletion
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Data Retention and Deletion"</h2>

                    <div class="privacy-section">
                        <p>
                            "Because WindowDrop does not collect or store any personal data, there is nothing to retain or delete. The app maintains no databases, user accounts, or persistent data stores."
                        </p>
                        <p>
                            "Diagnostic logs that you voluntarily share with us are retained only for the duration needed to resolve your support issue and are then deleted. Website hosting logs are managed by our hosting provider per their own retention policies. Support emails are retained as needed for ongoing support."
                        </p>
                    </div>
                </div>
            </section>

            // Data Security
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Data Security"</h2>

                    <div class="privacy-section">
                        <p>
                            "Because no personal data is collected or transmitted, there is no user data requiring security measures. The app operates entirely locally on your Mac. All window management processing occurs in-memory and is not persisted to disk."
                        </p>
                    </div>
                </div>
            </section>

            // This Website
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"This Website"</h2>

                    <div class="privacy-section">
                        <p>
                            "The WindowDrop website (windowdrop.pro) does not use cookies, third-party analytics, or tracking scripts. We do not serve advertisements or integrate any third-party marketing tools."
                        </p>
                        <p>
                            "Our hosting infrastructure may collect standard server access logs (IP addresses, user agents, request timestamps) as part of normal web server operation. These logs are managed by our hosting provider and are not used by us for analytics, marketing, or user identification purposes."
                        </p>
                    </div>
                </div>
            </section>

            // Children's Privacy
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Children\u{2019}s Privacy"</h2>

                    <div class="privacy-section">
                        <p>
                            "WindowDrop does not knowingly collect personal information from children under the age of 13 (or the applicable age in your jurisdiction). Because WindowDrop collects no personal information from any user, the app is inherently compliant with the Children\u{2019}s Online Privacy Protection Act (COPPA) and similar regulations."
                        </p>
                        <p>
                            "WindowDrop is a general-purpose utility application and is not directed at children."
                        </p>
                    </div>
                </div>
            </section>

            // International Users
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"International Users"</h2>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"European Economic Area (GDPR)"</h3>
                        <p>
                            "If you are located in the European Economic Area, you have rights under the General Data Protection Regulation (GDPR) regarding your personal data, including the right to access, correct, delete, and port your data. Because WindowDrop does not collect, process, or store any personal data, these rights are inherently satisfied \u{2014} there is no personal data to access, correct, delete, or port."
                        </p>
                        <p>
                            "If you believe your data protection rights have been violated, you have the right to lodge a complaint with a supervisory authority in your country of residence."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"United Kingdom (UK GDPR)"</h3>
                        <p>
                            "Following Brexit, the United Kingdom has its own data protection framework known as the UK GDPR, which provides equivalent protections to the EU GDPR. The same analysis applies \u{2014} because WindowDrop does not collect, process, or store any personal data, the rights afforded under the UK GDPR are inherently satisfied."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"California Residents (CCPA/CPRA)"</h3>
                        <p>
                            "If you are a California resident, the California Consumer Privacy Act (CCPA), as amended by the California Privacy Rights Act (CPRA), provides you with specific rights regarding your personal information. Because WindowDrop does not collect, sell, or share personal information, these rights are inherently satisfied. WindowDrop does not sell or share your personal information, and there is no personal information to disclose, delete, or correct."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"California Online Privacy Protection Act (CalOPPA)"</h3>
                        <p>
                            "In accordance with CalOPPA, this privacy policy identifies the categories of personally identifiable information collected (none), the categories of third parties with whom information may be shared (none), and includes the effective date of this policy. We honor Do Not Track signals, though WindowDrop does not track users regardless of any browser or system-level signals."
                        </p>
                    </div>

                    <div class="privacy-section">
                        <h3 class="privacy-section-title">"Australia (Privacy Act 1988)"</h3>
                        <p>
                            "WindowDrop is developed in Australia. Under the Privacy Act 1988, entities with annual turnover under $3 million AUD are generally exempt from the Australian Privacy Principles. Regardless of this exemption, WindowDrop does not collect personal information as defined under the Act."
                        </p>
                    </div>
                </div>
            </section>

            // Changes to Policy
            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Changes to This Policy"</h2>

                    <div class="privacy-section">
                        <p>
                            "We may update this privacy policy from time to time to reflect changes in our practices or for legal, regulatory, or operational reasons. When we make changes, we will update the effective date at the top of this page. If we make material changes that affect your rights, we will provide prominent notice on this website."
                        </p>
                        <p>
                            "We review this policy at least annually and update it as needed to reflect changes in our practices or applicable laws."
                        </p>
                        <p>
                            "We encourage you to review this policy periodically. Your continued use of WindowDrop after any changes constitutes acceptance of the updated policy."
                        </p>
                    </div>
                </div>
            </section>

            // Contact
            <section class="section privacy-contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Questions?"</h2>
                    <p>
                        "For privacy questions, concerns, or to exercise any rights you may have under applicable privacy laws, contact us at:"
                    </p>
                    <a href="mailto:support@windowdrop.pro" class="privacy-email">
                        "support@windowdrop.pro"
                    </a>
                </div>
            </section>
        </div>
    }
}
