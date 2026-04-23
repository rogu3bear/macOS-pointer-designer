#[cfg(feature = "ssr")]
#[path = "../web_license.rs"]
mod web_license;

#[cfg(feature = "ssr")]
mod email;

#[cfg(feature = "ssr")]
mod web_checkout;

#[cfg(feature = "ssr")]
#[tokio::main]
async fn main() {
    use axum::{
        middleware,
        routing::{get, get_service, post},
        Router,
    };
    use std::net::SocketAddr;
    use tower_http::compression::CompressionLayer;
    use tower_http::services::{ServeDir, ServeFile};

    // Initialize logging
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "3410".to_string());
    let addr = format!("0.0.0.0:{}", port)
        .parse::<SocketAddr>()
        .expect("Invalid address");

    // Serve "dist" directory with a 200 SPA fallback for extensionless routes.
    let serve_dir = ServeDir::new("dist").fallback(ServeFile::new("dist/index.html"));
    let web_checkout_state = web_checkout::WebCheckoutState::from_env();

    let app = Router::new()
        .route("/healthz", get(|| async { "ok" }))
        .route("/checkout/lifetime", get(web_checkout::lifetime_checkout))
        .route(
            "/api/web-license/session",
            get(web_checkout::verify_session),
        )
        .route(
            "/api/web-license/activate",
            post(web_checkout::activate_license),
        )
        .route(
            "/api/web-license/recover",
            post(web_checkout::recover_purchase),
        )
        .with_state(web_checkout_state)
        .nest_service("/", get_service(serve_dir))
        .layer(middleware::from_fn(cache_control_middleware))
        .layer(CompressionLayer::new());

    tracing::info!("Listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await
    .unwrap();
}

#[cfg(feature = "ssr")]
async fn cache_control_middleware(
    request: axum::extract::Request,
    next: axum::middleware::Next,
) -> axum::response::Response {
    use axum::http::{header, HeaderValue};

    let path = request.uri().path().to_string();
    let mut response = next.run(request).await;

    // Skip healthz endpoint
    if path == "/healthz" {
        return response;
    }

    if path.starts_with("/api/") || path == "/checkout/lifetime" {
        response
            .headers_mut()
            .insert(header::CACHE_CONTROL, HeaderValue::from_static("no-store"));
        return response;
    }

    // Hashed assets (contain hash in filename) - cache for 1 year
    // Pattern: filename-[hash].ext (e.g., base-3fea4d2757701139.css)
    let is_hashed_asset = path.contains('-')
        && (path.ends_with(".css")
            || path.ends_with(".js")
            || path.ends_with(".wasm")
            || path.ends_with(".png")
            || path.ends_with(".svg")
            || path.ends_with(".woff2"));
    let is_extensionless_route = !path.rsplit('/').next().unwrap_or_default().contains('.');

    let cache_value = if is_hashed_asset {
        // Immutable assets with content hash - cache forever
        HeaderValue::from_static("public, max-age=31536000, immutable")
    } else if path.ends_with(".html") || path == "/" || is_extensionless_route {
        // HTML shell / SPA routes - revalidate every time
        HeaderValue::from_static("no-cache, must-revalidate")
    } else {
        // Other static assets - short cache with revalidation
        HeaderValue::from_static("public, max-age=3600, must-revalidate")
    };

    response
        .headers_mut()
        .insert(header::CACHE_CONTROL, cache_value);

    response
}

#[cfg(not(feature = "ssr"))]
fn main() {
    // No-op for non-SSR builds (e.g. WASM)
}
