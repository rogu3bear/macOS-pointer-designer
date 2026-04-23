use crate::components::icons::{IconCheckCircle, IconShieldCheck};
use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn PrivacyChoices() -> impl IntoView {
    view! {
        <SeoMeta
            title="Your Privacy Choices"
            description="Your control over data at WindowDrop. No cookies, no tracking, nothing to opt out of."
            path="/privacy-choices"
        />
        <div class="privacy-page privacy-page-choices">
            <section class="privacy-hero">
                <div class="container container-narrow">
                    <div class="privacy-hero-icon">
                        <IconShieldCheck size=48 />
                    </div>
                    <h1 class="privacy-hero-title">"Your Privacy Choices"</h1>
                    <p class="privacy-hero-subtitle">
                        "You control your data. Here are your options."
                    </p>
                </div>
            </section>

            <section class="section privacy-promises">
                <div class="container container-narrow">
                    <h2 class="section-title">"No Opt-Out Needed"</h2>
                    <p class="privacy-intro">
                        "WindowDrop and this website do not collect, sell, or share personal data. We don't use cookies or tracking. There is nothing to opt out of."
                    </p>
                    <div class="promises-grid">
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Cookies"</h3>
                            <p class="promise-description">
                                "We do not use cookies. No cookie banner, no consent popup."
                            </p>
                        </div>
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Do Not Sell"</h3>
                            <p class="promise-description">
                                "We do not sell personal information. We don't collect it."
                            </p>
                        </div>
                        <div class="promise-card">
                            <div class="promise-icon">
                                <IconCheckCircle size=28 />
                            </div>
                            <h3 class="promise-title">"Targeted Ads"</h3>
                            <p class="promise-description">
                                "We do not use your data for advertising. No ad tracking."
                            </p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="section privacy-details">
                <div class="container container-narrow">
                    <h2 class="section-title">"Your Rights"</h2>
                    <p>
                        "Because we don't collect personal data, there are no data requests to make. If you have questions or want to exercise any rights, contact "
                        <a href="mailto:support@windowdrop.pro" class="privacy-link">"support@windowdrop.pro"</a>
                        "."
                    </p>
                    <p>
                        "For our full privacy policy, see "
                        <A href="/privacy" class="privacy-link">"Privacy Policy"</A>
                        "."
                    </p>
                </div>
            </section>
        </div>
    }
}
