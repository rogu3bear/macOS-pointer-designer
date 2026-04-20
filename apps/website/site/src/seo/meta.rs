use leptos::*;
use leptos_meta::*;

#[component]
pub fn SeoMeta(
    #[prop(into)] title: String,
    #[prop(into)] description: String,
    #[prop(into)] path: String,
) -> impl IntoView {
    let full_title = format!("{} | WindowDrop", title);
    let domain = "https://windowdrop.pro";
    let full_url = format!("{}{}", domain, path);
    // Use absolute URL for OG image
    let og_image = format!("{}/assets/og.svg", domain);

    view! {
        <Title text=full_title.clone() />
        <Meta name="description" content=description.clone() />
        <Link rel="canonical" href=full_url.clone() />

        // OpenGraph
        <Meta property="og:title" content=full_title.clone() />
        <Meta property="og:description" content=description.clone() />
        <Meta property="og:url" content=full_url.clone() />
        <Meta property="og:type" content="website" />
        <Meta property="og:image" content=og_image.clone() />

        // Twitter
        <Meta name="twitter:card" content="summary_large_image" />
        <Meta name="twitter:title" content=full_title />
        <Meta name="twitter:description" content=description />
        <Meta name="twitter:image" content=og_image />
    }
}
