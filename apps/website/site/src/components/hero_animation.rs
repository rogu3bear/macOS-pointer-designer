//! Hero animation component demonstrating WindowDrop behavior.
//!
//! Storyboard:
//! 1. Scene shows an existing window on the left
//! 2. Cursor moves to the right side (away from existing window)
//! 3. Keys overlay: "⌘ N"
//! 4. NEW window appears directly under cursor (not near old window)
//! 5. Demonstrates: new window follows cursor, not default position
//!
//! Respects reduced motion preferences.

use leptos::*;

use crate::analytics::{track_event, AnalyticsEvent};
use crate::config::CONFIG;

/// Check if user prefers reduced motion.
fn get_prefers_reduced_motion() -> bool {
    if let Some(window) = web_sys::window() {
        if let Ok(Some(media_query)) = window.match_media("(prefers-reduced-motion: reduce)") {
            return media_query.matches();
        }
    }
    false
}

/// The animated hero demonstration.
#[component]
pub fn HeroAnimation() -> impl IntoView {
    let prefers_reduced_motion = get_prefers_reduced_motion();
    let animation_enabled = CONFIG.animation_enabled && !prefers_reduced_motion;

    // Track animation viewed after it completes
    if animation_enabled {
        set_timeout(
            move || {
                track_event(AnalyticsEvent::AnimationViewed);
            },
            std::time::Duration::from_millis(5000),
        );
    }

    let class_name = if animation_enabled {
        "hero-animation"
    } else {
        "hero-animation hero-animation--static"
    };

    view! {
        <div
            class=class_name
            role="img"
            aria-label="Demonstration: a cursor moves away from an existing window, presses Command+N, and a new window appears directly under the cursor"
        >
            <div class="hero-animation-stage">
                {if animation_enabled {
                    view! { <AnimatedDemo /> }.into_view()
                } else {
                    view! { <StaticDemo /> }.into_view()
                }}
            </div>
            <p class="hero-animation-caption">
                "Press "<kbd>"⌘N"</kbd>". Window appears where you are."
            </p>
        </div>
    }
}

/// The animated SVG demonstration.
#[component]
fn AnimatedDemo() -> impl IntoView {
    view! {
        <svg
            class="hero-animation-svg"
            viewBox="0 0 600 400"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
        >
            <defs>
                <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                    <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#E2E8F0" stroke-width="0.5"/>
                </pattern>
                <linearGradient id="windowGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#F8FAFC"/>
                    <stop offset="100%" style="stop-color:#FFFFFF"/>
                </linearGradient>
                <linearGradient id="titleBarGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#F1F5F9"/>
                    <stop offset="100%" style="stop-color:#E2E8F0"/>
                </linearGradient>
                <filter id="windowShadow" x="-20%" y="-20%" width="140%" height="140%">
                    <feDropShadow dx="0" dy="4" stdDeviation="8" flood-opacity="0.12"/>
                </filter>
                <filter id="keyShadow" x="-20%" y="-20%" width="140%" height="140%">
                    <feDropShadow dx="0" dy="2" stdDeviation="4" flood-opacity="0.2"/>
                </filter>
            </defs>

            // Desktop background with grid
            <rect width="600" height="400" fill="url(#grid)"/>
            <rect x="20" y="10" width="560" height="380" rx="8" fill="#F8FAFC" stroke="#E2E8F0" stroke-width="1"/>

            // Menu bar
            <rect x="20" y="10" width="560" height="22" rx="8" fill="#F1F5F9"/>
            <rect x="20" y="24" width="560" height="8" fill="#F1F5F9"/>

            // ===== EXISTING WINDOW (on the LEFT side) =====
            // This window is already open and stays in place
            <g class="existing-window">
                <rect
                    x="40"
                    y="60"
                    width="220"
                    height="160"
                    rx="6"
                    fill="url(#windowGradient)"
                    stroke="#D1D5DB"
                    stroke-width="1"
                    filter="url(#windowShadow)"
                />
                // Title bar
                <rect x="40" y="60" width="220" height="24" rx="6" fill="url(#titleBarGradient)"/>
                <rect x="40" y="78" width="220" height="6" fill="url(#titleBarGradient)"/>
                // Traffic lights
                <circle cx="54" cy="72" r="5" fill="#FF5F57"/>
                <circle cx="70" cy="72" r="5" fill="#FEBC2E"/>
                <circle cx="86" cy="72" r="5" fill="#28C840"/>
                // Window title
                <text x="150" y="76" text-anchor="middle" fill="#6B7280" font-size="10" font-weight="500">
                    "Documents"
                </text>
                // Content placeholder
                <rect x="52" y="96" width="80" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="52" y="112" width="140" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="52" y="128" width="100" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="52" y="144" width="120" height="8" rx="2" fill="#E5E7EB"/>
            </g>

            // ===== CURSOR - starts near existing window, moves FAR to the right =====
            <g class="hero-cursor">
                <path
                    d="M0 0 L0 17 L4 13 L7 20 L10 19 L7 12 L12 12 Z"
                    fill="#171717"
                    stroke="#FFFFFF"
                    stroke-width="1.5"
                />
            </g>

            // ===== KEY OVERLAY - appears after cursor moves =====
            <g class="hero-keys">
                <rect x="420" y="155" width="90" height="40" rx="8" fill="rgba(23, 23, 23, 0.92)" filter="url(#keyShadow)"/>
                <text x="465" y="181" text-anchor="middle" fill="white" font-family="-apple-system, BlinkMacSystemFont, monospace" font-size="16" font-weight="600">
                    "⌘ N"
                </text>
            </g>

            // ===== NEW WINDOW - appears on the RIGHT under the cursor =====
            // Key point: this window appears FAR from the existing window
            <g class="hero-window">
                <rect
                    x="340"
                    y="120"
                    width="220"
                    height="160"
                    rx="6"
                    fill="url(#windowGradient)"
                    stroke="#3B82F6"
                    stroke-width="2"
                    filter="url(#windowShadow)"
                />
                // Title bar
                <rect x="340" y="120" width="220" height="24" rx="6" fill="url(#titleBarGradient)"/>
                <rect x="340" y="138" width="220" height="6" fill="url(#titleBarGradient)"/>
                // Traffic lights
                <circle cx="354" cy="132" r="5" fill="#FF5F57"/>
                <circle cx="370" cy="132" r="5" fill="#FEBC2E"/>
                <circle cx="386" cy="132" r="5" fill="#28C840"/>
                // Window title - "Untitled" for new window
                <text x="450" y="136" text-anchor="middle" fill="#6B7280" font-size="10" font-weight="500">
                    "Untitled"
                </text>
                // Empty new window content
                <rect x="352" y="156" width="80" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="352" y="172" width="140" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="352" y="188" width="100" height="8" rx="2" fill="#E5E7EB"/>
            </g>

            // Visual indicator: highlight where cursor is
            <circle class="cursor-highlight" cx="450" cy="145" r="24" fill="none" stroke="#3B82F6" stroke-width="2" stroke-dasharray="4 4" opacity="0"/>
        </svg>
    }
}

/// Static fallback for reduced motion.
#[component]
fn StaticDemo() -> impl IntoView {
    view! {
        <svg
            class="hero-animation-svg hero-animation-svg--static"
            viewBox="0 0 600 400"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
        >
            <defs>
                <pattern id="grid-static" width="40" height="40" patternUnits="userSpaceOnUse">
                    <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#E2E8F0" stroke-width="0.5"/>
                </pattern>
                <linearGradient id="windowGradient-static" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#F8FAFC"/>
                    <stop offset="100%" style="stop-color:#FFFFFF"/>
                </linearGradient>
                <linearGradient id="titleBarGradient-static" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#F1F5F9"/>
                    <stop offset="100%" style="stop-color:#E2E8F0"/>
                </linearGradient>
                <filter id="windowShadow-static" x="-20%" y="-20%" width="140%" height="140%">
                    <feDropShadow dx="0" dy="4" stdDeviation="8" flood-opacity="0.12"/>
                </filter>
            </defs>

            // Desktop background
            <rect width="600" height="400" fill="url(#grid-static)"/>
            <rect x="20" y="10" width="560" height="380" rx="8" fill="#F8FAFC" stroke="#E2E8F0" stroke-width="1"/>

            // Menu bar
            <rect x="20" y="10" width="560" height="22" rx="8" fill="#F1F5F9"/>
            <rect x="20" y="24" width="560" height="8" fill="#F1F5F9"/>

            // Existing window (left side)
            <g>
                <rect x="40" y="60" width="220" height="160" rx="6" fill="url(#windowGradient-static)" stroke="#D1D5DB" stroke-width="1" filter="url(#windowShadow-static)"/>
                <rect x="40" y="60" width="220" height="24" rx="6" fill="url(#titleBarGradient-static)"/>
                <rect x="40" y="78" width="220" height="6" fill="url(#titleBarGradient-static)"/>
                <circle cx="54" cy="72" r="5" fill="#FF5F57"/>
                <circle cx="70" cy="72" r="5" fill="#FEBC2E"/>
                <circle cx="86" cy="72" r="5" fill="#28C840"/>
                <text x="150" y="76" text-anchor="middle" fill="#6B7280" font-size="10" font-weight="500">"Documents"</text>
                <rect x="52" y="96" width="80" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="52" y="112" width="140" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="52" y="128" width="100" height="8" rx="2" fill="#E5E7EB"/>
            </g>

            // Cursor at final position (right side, near new window)
            <g transform="translate(448, 143)">
                <path d="M0 0 L0 17 L4 13 L7 20 L10 19 L7 12 L12 12 Z" fill="#171717" stroke="#FFFFFF" stroke-width="1.5"/>
            </g>

            // New window (right side, under cursor) - highlighted border
            <g>
                <rect x="340" y="120" width="220" height="160" rx="6" fill="url(#windowGradient-static)" stroke="#3B82F6" stroke-width="2" filter="url(#windowShadow-static)"/>
                <rect x="340" y="120" width="220" height="24" rx="6" fill="url(#titleBarGradient-static)"/>
                <rect x="340" y="138" width="220" height="6" fill="url(#titleBarGradient-static)"/>
                <circle cx="354" cy="132" r="5" fill="#FF5F57"/>
                <circle cx="370" cy="132" r="5" fill="#FEBC2E"/>
                <circle cx="386" cy="132" r="5" fill="#28C840"/>
                <text x="450" y="136" text-anchor="middle" fill="#6B7280" font-size="10" font-weight="500">"Untitled"</text>
                <rect x="352" y="156" width="80" height="8" rx="2" fill="#E5E7EB"/>
                <rect x="352" y="172" width="140" height="8" rx="2" fill="#E5E7EB"/>
            </g>

            // Visual arrow/indicator showing cursor -> new window relationship
            <circle cx="450" cy="145" r="20" fill="none" stroke="#3B82F6" stroke-width="2" stroke-dasharray="4 4" opacity="0.5"/>
        </svg>
    }
}
