use crate::components::icons::IconNotes;
use crate::seo::meta::SeoMeta;
use leptos::*;

#[component]
pub fn Terms() -> impl IntoView {
    view! {
        <SeoMeta
            title="Terms and Conditions"
            description="WindowDrop terms and conditions. Read the terms governing your use of the WindowDrop application."
            path="/terms"
        />
        <div class="terms-page">
            // Hero
            <section class="terms-hero">
                <div class="container container-narrow">
                    <div class="terms-hero-icon">
                        <IconNotes size=48 />
                    </div>
                    <h1 class="terms-hero-title">"Terms and Conditions"</h1>
                    <p class="terms-hero-subtitle">
                        "Please read these terms carefully before using WindowDrop."
                    </p>
                    <p class="terms-effective-date">
                        "Effective date: February 15, 2026"
                    </p>
                </div>
            </section>

            // Agreement to Terms
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Agreement to Terms"</h2>

                    <div class="legal-section">
                        <p>
                            "By downloading, installing, or using WindowDrop (\u{201c}the App\u{201d}), you agree to be bound by these Terms and Conditions (\u{201c}Terms\u{201d}). If you do not agree to these Terms, do not download, install, or use the App."
                        </p>
                        <p>
                            "These Terms constitute a legally binding agreement between you (\u{201c}User\u{201d} or \u{201c}you\u{201d}) and WindowDrop (\u{201c}we,\u{201d} \u{201c}us,\u{201d} or \u{201c}our\u{201d}) governing your use of the App."
                        </p>
                    </div>
                </div>
            </section>

            // License Grant
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"License Grant"</h2>

                    <div class="legal-section">
                        <p>
                            "Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the App on any Mac computer that you own or control, solely for your personal, non-commercial use."
                        </p>
                        <p>
                            "If you obtained the App through the Apple App Store, your use of the App is also governed by the Usage Rules set forth in the Apple Media Services Terms and Conditions."
                        </p>
                    </div>
                </div>
            </section>

            // License Restrictions
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"License Restrictions"</h2>

                    <div class="legal-section">
                        <p>"You agree not to:"</p>
                        <ul class="legal-list">
                            <li>"Copy, modify, or distribute the App or any portion thereof"</li>
                            <li>"Reverse engineer, decompile, disassemble, or attempt to derive the source code of the App"</li>
                            <li>"Sell, resell, rent, lease, sublicense, or otherwise transfer rights to the App"</li>
                            <li>"Remove, alter, or obscure any proprietary notices, labels, or marks on the App"</li>
                            <li>"Use the App for any unlawful purpose or in violation of any applicable laws or regulations"</li>
                            <li>"Use the App in any manner that could damage, disable, or impair the functioning of any computer system"</li>
                        </ul>
                    </div>
                </div>
            </section>

            // System Requirements and Permissions
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"System Requirements and Permissions"</h2>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"System Requirements"</h3>
                        <p>
                            "The App requires macOS 14.0 (Sonoma) or later running on an Apple Silicon Mac. The App may not function correctly on unsupported systems."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Accessibility Permission"</h3>
                        <p>
                            "The App requires the macOS Accessibility permission to function. This permission allows the App to detect window creation events and reposition windows. You must explicitly grant this permission through macOS System Settings. You may revoke this permission at any time, which will prevent the App from functioning until the permission is restored."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Third-Party Applications"</h3>
                        <p>
                            "WindowDrop interacts with windows created by third-party applications. We are not responsible for the behavior, privacy practices, or terms of service of any third-party applications whose windows WindowDrop repositions. WindowDrop does not access, modify, or interact with the content of any third-party application windows."
                        </p>
                    </div>
                </div>
            </section>

            // Intellectual Property
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Intellectual Property"</h2>

                    <div class="legal-section">
                        <p>
                            "The App and all related materials, including but not limited to software, design, graphics, text, and documentation, are owned by WindowDrop and are protected by copyright, trademark, and other intellectual property laws. These Terms do not grant you any rights to our trademarks, service marks, or trade names."
                        </p>
                    </div>
                </div>
            </section>

            // Updates
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Updates and Modifications"</h2>

                    <div class="legal-section">
                        <p>
                            "We may release updates to the App from time to time. Updates may include bug fixes, feature enhancements, or security patches. While we are not obligated to provide updates, we recommend keeping the App up to date for the best experience."
                        </p>
                        <p>
                            "We reserve the right to modify, suspend, or discontinue the App at any time without notice or liability. We are not obligated to provide support or maintenance for the App."
                        </p>
                    </div>
                </div>
            </section>

            // Maintenance and Support
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Maintenance and Support"</h2>

                    <div class="legal-section">
                        <p>
                            "WindowDrop is solely responsible for any maintenance and support services for the App, as specified in these Terms or as required under applicable law. Support is available via "
                            <a href="mailto:support@windowdrop.pro">"support@windowdrop.pro"</a>
                            "."
                        </p>
                        <p>
                            "Apple has no obligation whatsoever to furnish any maintenance and support services with respect to the App."
                        </p>
                    </div>
                </div>
            </section>

            // Disclaimer of Warranties
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Disclaimer of Warranties"</h2>

                    <div class="legal-section legal-section-emphasis">
                        <p>
                            "THE APP IS PROVIDED \u{201c}AS IS\u{201d} AND \u{201c}AS AVAILABLE\u{201d} WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT."
                        </p>
                        <p>
                            "WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF HARMFUL COMPONENTS. WE DO NOT WARRANT THAT THE APP WILL MEET YOUR REQUIREMENTS OR THAT ANY DEFECTS WILL BE CORRECTED."
                        </p>
                        <p>
                            "YOU USE THE APP AT YOUR OWN RISK. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE APP IS WITH YOU."
                        </p>
                    </div>
                </div>
            </section>

            // Limitation of Liability
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Limitation of Liability"</h2>

                    <div class="legal-section legal-section-emphasis">
                        <p>
                            "TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL WINDOWDROP, ITS DEVELOPERS, OR ITS AFFILIATES BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM:"
                        </p>
                        <ul class="legal-list">
                            <li>"YOUR USE OR INABILITY TO USE THE APP"</li>
                            <li>"ANY UNAUTHORIZED ACCESS TO OR ALTERATION OF YOUR COMPUTER SYSTEM"</li>
                            <li>"ANY INTERRUPTION OR CESSATION OF THE APP\u{2019}S FUNCTIONALITY"</li>
                            <li>"ANY BUGS, VIRUSES, OR OTHER HARMFUL CODE THAT MAY BE TRANSMITTED THROUGH THE APP"</li>
                            <li>"ANY ERRORS OR OMISSIONS IN THE APP\u{2019}S FUNCTIONALITY"</li>
                            <li>"ANY INTERACTION BETWEEN THE APP AND THIRD-PARTY SOFTWARE"</li>
                        </ul>
                        <p>
                            "IN NO EVENT SHALL OUR TOTAL LIABILITY TO YOU EXCEED THE AMOUNT YOU PAID FOR THE APP, IF ANY."
                        </p>
                    </div>
                </div>
            </section>

            // Indemnification
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Indemnification"</h2>

                    <div class="legal-section">
                        <p>
                            "You agree to indemnify, defend, and hold harmless WindowDrop, its developers, and its affiliates from and against any claims, liabilities, damages, losses, costs, and expenses (including reasonable legal fees) arising out of or in any way connected with your use of the App or your violation of these Terms."
                        </p>
                    </div>
                </div>
            </section>

            // Termination
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Termination"</h2>

                    <div class="legal-section">
                        <p>
                            "These Terms are effective until terminated. Your rights under these Terms will terminate automatically without notice if you fail to comply with any provision of these Terms."
                        </p>
                        <p>
                            "Upon termination, you must cease all use of the App and destroy all copies in your possession. Termination does not limit any of our other rights or remedies at law or in equity."
                        </p>
                        <p>
                            "The following sections survive termination: Intellectual Property, Disclaimer of Warranties, Limitation of Liability, Indemnification, Governing Law, and General Provisions."
                        </p>
                    </div>
                </div>
            </section>

            // Governing Law
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Governing Law"</h2>

                    <div class="legal-section">
                        <p>
                            "These Terms shall be governed by and construed in accordance with the laws of Australia, without regard to its conflict of law provisions. Any legal action or proceeding arising under these Terms shall be brought exclusively in the courts located in Australia, and you consent to the personal jurisdiction and venue therein."
                        </p>
                    </div>
                </div>
            </section>

            // Dispute Resolution
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Dispute Resolution"</h2>

                    <div class="legal-section">
                        <p>
                            "Any dispute arising from or relating to these Terms or your use of the App shall first be attempted to be resolved through good-faith negotiation between the parties. If a dispute cannot be resolved through negotiation within thirty (30) days, either party may pursue the remedies available under the governing law specified above."
                        </p>
                    </div>
                </div>
            </section>

            // Apple-Specific Terms
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Apple App Store Terms"</h2>

                    <div class="legal-section">
                        <p>
                            "If you downloaded the App from the Apple App Store, the following additional terms apply:"
                        </p>
                        <ul class="legal-list">
                            <li>"These Terms are between you and WindowDrop, not Apple. WindowDrop, not Apple, is solely responsible for the App and its content."</li>
                            <li>"Apple has no obligation to provide maintenance or support services for the App."</li>
                            <li>"In the event of any failure of the App to conform to any applicable warranty, you may notify Apple for a refund of the purchase price (if any). To the maximum extent permitted by law, Apple has no other warranty obligation with respect to the App."</li>
                            <li>"Apple is not responsible for addressing any claims relating to the App, including product liability claims, claims that the App fails to conform to legal or regulatory requirements, and consumer protection claims."</li>
                            <li>"In the event of any third-party claim that the App infringes a third party\u{2019}s intellectual property rights, WindowDrop, not Apple, is solely responsible for the investigation, defense, settlement, and discharge of such claim."</li>
                            <li>"Apple and its subsidiaries are third-party beneficiaries of these Terms. Upon your acceptance of these Terms, Apple will have the right to enforce these Terms against you as a third-party beneficiary."</li>
                        </ul>
                    </div>
                </div>
            </section>

            // Export Control and Legal Compliance
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Export Control and Legal Compliance"</h2>

                    <div class="legal-section">
                        <p>"You represent and warrant that:"</p>
                        <ul class="legal-list">
                            <li>"You are not located in a country that is subject to a U.S. Government embargo, or that has been designated by the U.S. Government as a \u{201c}terrorist supporting\u{201d} country"</li>
                            <li>"You are not listed on any U.S. Government list of prohibited or restricted parties"</li>
                        </ul>
                        <p>
                            "You will comply with all applicable export and import laws and regulations in your use of the App."
                        </p>
                    </div>
                </div>
            </section>

            // Third-Party Terms Compliance
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Third-Party Terms Compliance"</h2>

                    <div class="legal-section">
                        <p>
                            "You must comply with applicable third-party terms of agreement when using the App. For example, if the App uses a wireless data connection, you must not be in violation of your wireless data service agreement terms when using the App."
                        </p>
                    </div>
                </div>
            </section>

            // General Provisions
            <section class="section legal-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"General Provisions"</h2>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Entire Agreement"</h3>
                        <p>
                            "These Terms, together with our "
                            <a href="/privacy">"Privacy Policy"</a>
                            ", constitute the entire agreement between you and WindowDrop regarding the App and supersede all prior agreements, understandings, and communications."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Severability"</h3>
                        <p>
                            "If any provision of these Terms is held to be invalid, illegal, or unenforceable, the remaining provisions shall continue in full force and effect. The invalid provision shall be modified to the minimum extent necessary to make it valid and enforceable."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Waiver"</h3>
                        <p>
                            "Our failure to enforce any right or provision of these Terms shall not constitute a waiver of such right or provision. Any waiver must be in writing and signed by an authorized representative."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Assignment"</h3>
                        <p>
                            "You may not assign or transfer these Terms or your rights under these Terms without our prior written consent. We may assign our rights and obligations under these Terms without restriction."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Changes to Terms"</h3>
                        <p>
                            "We reserve the right to modify these Terms at any time. When we make changes, we will update the effective date at the top of this page. Your continued use of the App after any changes constitutes acceptance of the modified Terms. If you do not agree to the modified Terms, you must stop using the App."
                        </p>
                    </div>

                    <div class="legal-section">
                        <h3 class="legal-section-title">"Force Majeure"</h3>
                        <p>
                            "Neither party shall be liable for any failure or delay in performance due to causes beyond their reasonable control, including but not limited to natural disasters, war, terrorism, riots, government actions, or internet and infrastructure failures."
                        </p>
                    </div>
                </div>
            </section>

            // Contact
            <section class="section privacy-contact">
                <div class="container container-narrow text-center">
                    <h2 class="section-title">"Questions?"</h2>
                    <p>
                        "For questions about these Terms, contact us at:"
                    </p>
                    <p>"Developer: James KC Auchterlonie"</p>
                    <p>"Location: Australia"</p>
                    <a href="mailto:support@windowdrop.pro" class="privacy-email">
                        "support@windowdrop.pro"
                    </a>
                </div>
            </section>
        </div>
    }
}
