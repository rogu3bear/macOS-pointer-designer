use leptos::*;
mod analytics;
mod app;
mod components;
mod config;
mod content;
mod pages;
mod routes;
mod seo;

use app::App;

fn main() {
    console_error_panic_hook::set_once();
    mount_to_body(|| view! { <App/> })
}
