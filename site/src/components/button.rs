use leptos::*;
use leptos_router::A;

#[component]
pub fn Button(
    #[prop(into)] href: String,
    #[prop(default = false)] primary: bool,
    children: Children,
) -> impl IntoView {
    let class = if primary {
        "btn btn-primary"
    } else {
        "btn btn-secondary"
    };

    view! {
        <A href=href class=class>
            {children()}
        </A>
    }
}
