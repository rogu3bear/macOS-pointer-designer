//! Pricing page: free Finder plan plus $7.99 one-time lifetime unlock.

use crate::components::icons::IconApple;
use crate::config::{LifetimeCtaMode, CONFIG};
use crate::seo::meta::SeoMeta;
use crate::web_license::WEB_LICENSE_PRICE_LABEL;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Pricing() -> impl IntoView {
    let free_download_url = CONFIG.download_page_url;
    let lifetime_mode = CONFIG.lifetime_cta_mode;
    let lifetime_href = CONFIG.lifetime_cta_href;

    view! {
        <SeoMeta
            title="Pricing"
            description="WindowDrop for macOS — free Finder plan, plus a $7.99 one-time lifetime unlock for all supported apps. Clear download and activation steps, no subscription."
            path="/pricing"
        />
        <div class="pricing-page">
            <section class="pricing-hero">
                <div class="container container-narrow">
                    <div class="pricing-hero-icon">
                        <IconApple size=48 />
                    </div>
                    <h1 class="pricing-hero-title">"WindowDrop"</h1>
                    <p class="pricing-hero-subtitle">
                        "New windows appear under your mouse."
                    </p>

                    <div class="pricing-grid">
                        // Free card
                        <div class="pricing-card">
                            <div class="pricing-card-header">
                                <h2 class="pricing-card-name">"Free"</h2>
                            </div>
                            <div class="pricing-price">
                                <span class="pricing-amount">"$0"</span>
                                <span class="pricing-period">"forever"</span>
                            </div>
                            <ul class="pricing-features">
                                <li>"Finder support"</li>
                                <li>"No subscription"</li>
                                <li>"Includes updates"</li>
                            </ul>
                            <a href=free_download_url class="btn btn-secondary btn-lg pricing-cta">
                                "Download Free"
                            </a>
                        </div>

                        // Lifetime card
                        <div class="pricing-card pricing-card-featured">
                            <div class="pricing-card-badge">"Unlock all apps"</div>
                            <div class="pricing-card-header">
                                <h2 class="pricing-card-name">"Lifetime"</h2>
                            </div>
                            <div class="pricing-price">
                                <span class="pricing-amount">{WEB_LICENSE_PRICE_LABEL}</span>
                                <span class="pricing-period">"one-time payment"</span>
                            </div>
                            <ul class="pricing-features">
                                <li>"All supported apps"</li>
                                <li>"One-time payment"</li>
                                <li>"No subscription"</li>
                            </ul>
                            {move || match lifetime_mode {
                                crate::config::LifetimeCtaMode::Web => view! {
                                    <a href=lifetime_href class="btn btn-primary btn-lg pricing-cta">
                                        {lifetime_mode.label()}
                                    </a>
                                }.into_view(),
                                crate::config::LifetimeCtaMode::InApp => view! {
                                    <A href=lifetime_href class="btn btn-primary btn-lg pricing-cta">
                                        {lifetime_mode.label()}
                                    </A>
                                }.into_view(),
                            }}
                        </div>
                    </div>

                    // Free plan callout
                    <div class="pricing-trial">
                        <p class="pricing-trial-text">
                            "Download the current release and use Finder for free — "
                            <a href=free_download_url class="pricing-trial-link">"download WindowDrop"</a>
                        </p>
                    </div>

                    <p class="pricing-secure">
                        {lifetime_mode.secure_note()}
                    </p>
                    {move || match lifetime_mode {
                        LifetimeCtaMode::Web => view! {
                            <div class="pricing-trial">
                                <p class="pricing-trial-text">
                                    "After checkout you can download WindowDrop immediately, activate it with a signed code or "
                                    <code>"windowdrop://activate"</code>
                                    " link, and recover the purchase later by email."
                                </p>
                            </div>
                        }.into_view(),
                        LifetimeCtaMode::InApp => ().into_view(),
                    }}
                </div>
            </section>

            <section class="section pricing-links">
                <div class="container container-narrow text-center">
                    {move || match lifetime_mode {
                        LifetimeCtaMode::Web => view! {
                            <>
                                <A href="/checkout/recover" class="pricing-link">
                                    "Recover web purchase"
                                </A>
                                <span class="pricing-link-sep">"·"</span>
                            </>
                        }.into_view(),
                        LifetimeCtaMode::InApp => ().into_view(),
                    }}
                    <A href="/download" class="pricing-link">
                        "System requirements"
                    </A>
                    <span class="pricing-link-sep">"·"</span>
                    <A href="/changelog" class="pricing-link">
                        "Release notes"
                    </A>
                </div>
            </section>
        </div>
    }
}
