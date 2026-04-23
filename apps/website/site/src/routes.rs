use crate::pages::accessibility::Accessibility;
use crate::pages::changelog::Changelog;
use crate::pages::checkout_recover::CheckoutRecover;
use crate::pages::checkout_success::CheckoutSuccess;
use crate::pages::download::Download;
use crate::pages::home::Home;
use crate::pages::not_found::NotFound;
use crate::pages::pricing::Pricing;
use crate::pages::privacy::Privacy;
use crate::pages::privacy_choices::PrivacyChoices;
use crate::pages::support::Support;
use leptos::*;
use leptos_router::*;

#[component]
pub fn SiteRoutes() -> impl IntoView {
    view! {
        <Routes>
            <Route path="/" view=Home />
            <Route path="/checkout/recover" view=CheckoutRecover />
            <Route path="/checkout/success" view=CheckoutSuccess />
            <Route path="/download" view=Download />
            <Route path="/pricing" view=Pricing />
            <Route path="/privacy" view=Privacy />
            <Route path="/privacy-choices" view=PrivacyChoices />
            <Route path="/accessibility" view=Accessibility />
            <Route path="/support" view=Support />
            <Route path="/changelog" view=Changelog />
            <Route path="/*any" view=NotFound />
        </Routes>
    }
}
