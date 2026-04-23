use chrono::Datelike;
use leptos::*;
use leptos_router::A;

#[component]
pub fn Footer() -> impl IntoView {
    let year = chrono::Utc::now().year();

    view! {
        <footer class="site-footer">
            <div class="container footer-inner">
                <div class="footer-copyright">
                    {format!("© {} WindowDrop", year)}
                </div>
                <nav class="footer-nav" aria-label="Footer navigation">
                    <A href="/">"Home"</A>
                    <A href="/download">"Download Free"</A>
                    <A href="/privacy">"Privacy"</A>
                    <A href="/privacy-choices">"Privacy Choices"</A>
                    <A href="/accessibility">"Accessibility"</A>
                    <A href="/support">"Support"</A>
                    <A href="/changelog">"Changelog"</A>
                </nav>
            </div>
            <div class="container footer-meta">
                "Site by "
                <a href="https://jkca.me">"James KC Auchterlonie"</a>
                " · "
                <a href="https://mlnavigator.com">"MLNavigator"</a>
            </div>
        </footer>
    }
}
