use leptos::*;

#[component]
pub fn Section(#[prop(into, optional)] title: Option<String>, children: Children) -> impl IntoView {
    view! {
        <section class="section">
            <div class="container">
                {move || title.clone().map(|t| view! { <h2 class="section-title">{t}</h2> })}
                {children()}
            </div>
        </section>
    }
}
