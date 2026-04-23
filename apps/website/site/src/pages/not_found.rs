use crate::seo::meta::SeoMeta;
use leptos::*;
use leptos_router::A;

#[component]
pub fn NotFound() -> impl IntoView {
    view! {
        <SeoMeta
            title="Not Found"
            description="The page could not be found. Return home, download WindowDrop, or contact support."
            path="/404"
        />
        <section class="section not-found-page">
            <div class="container container-narrow text-center not-found-content">
                <p class="not-found-eyebrow">"404"</p>
                <h1 class="not-found-title">"Page not found"</h1>
                <p class="not-found-copy">
                    "The page you requested does not exist. You can return home, download WindowDrop, or contact support."
                </p>
                <div class="not-found-actions">
                    <A href="/" class="btn btn-primary">"Go Home"</A>
                    <A href="/download" class="btn btn-secondary">"Download Free"</A>
                    <A href="/support" class="not-found-tertiary">"Support"</A>
                </div>
            </div>
        </section>
    }
}
