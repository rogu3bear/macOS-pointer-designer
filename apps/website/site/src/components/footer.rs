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
                <nav class="footer-nav">
                    <A href="/">"Home"</A>
                    <A href="/download">"Download"</A>
                    <A href="/privacy">"Privacy"</A>
                    <A href="/privacy-choices">"Privacy Choices"</A>
                    <A href="/terms">"Terms"</A>
                    <A href="/accessibility">"Accessibility"</A>
                    <A href="/support">"Support"</A>
                    <A href="/changelog">"Changelog"</A>
                </nav>
            </div>
            <div class="container" style="text-align: center; margin-top: 1rem; font-size: 0.8rem; color: var(--color-text-muted);">
                "Site by "
                <a href="https://jkca.me" style="color: var(--color-text-muted);">"James KC Auchterlonie"</a>
                " · "
                <a href="https://mlnavigator.com" style="color: var(--color-text-muted);">"MLNavigator"</a>
            </div>
        </footer>
    }
}
