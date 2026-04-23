use leptos::*;
use leptos_router::A;

#[component]
pub fn Header() -> impl IntoView {
    view! {
        <header class="site-header">
            <div class="container header-inner">
                <A href="/" class="logo-link">
                    <img src="/assets/logo.svg" alt="WindowDrop Logo" class="logo-icon" />
                    <span class="logo-text">"WindowDrop"</span>
                </A>
                <nav class="site-nav" aria-label="Main Navigation">
                    <A href="/" exact=true active_class="active">"Home"</A>
                    <A href="/download" active_class="active">"Download Free"</A>
                    <A href="/pricing" active_class="active">"Pricing"</A>
                    <A href="/support" active_class="active">"Support"</A>
                    <A href="/changelog" active_class="active">"Changelog"</A>
                </nav>
            </div>
        </header>
    }
}
