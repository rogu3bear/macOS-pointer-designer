use crate::components::footer::Footer;
use crate::components::header::Header;
use crate::routes::SiteRoutes;
use leptos::*;
use leptos_meta::*;
use leptos_router::*;

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    view! {
        <Router>
            <div class="site-layout">
                <a href="#main-content" class="skip-link">"Skip to content"</a>
                <Header />
                <main id="main-content" class="site-content">
                    <SiteRoutes />
                </main>
                <Footer />
            </div>
        </Router>
    }
}
