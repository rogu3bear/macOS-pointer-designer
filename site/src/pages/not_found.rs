use crate::components::button::Button;
use crate::components::section::Section;
use leptos::*;

#[component]
pub fn NotFound() -> impl IntoView {
    view! {
        <Section title="Page not found">
            <p>"The page you requested does not exist."</p>
            <Button href="/">"Go home"</Button>
        </Section>
    }
}
