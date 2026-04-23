//! Hero animation component demonstrating WindowDrop behavior.
//!
//! Storyboard:
//! 1. Scene shows one Finder window, WindowDrop OFF
//! 2. Cmd+N (default) opens a new window stacked on Finder (bad)
//! 3. Cursor drags that window across the screen
//! 4. Cursor closes the bad window
//! 5. Cursor clicks "Activate WindowDrop" in the menu bar
//! 6. Cursor moves to target area, Cmd+N places new window under cursor (good)
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
pub fn HeroAnimation(
    /// When false, hides the caption footer (e.g. when embedded in HeroDemoBlock).
    #[prop(default = true)]
    show_footer: bool,
) -> impl IntoView {
    let prefers_reduced_motion = get_prefers_reduced_motion();
    let animation_enabled = CONFIG.animation_enabled && !prefers_reduced_motion;
    let replay_key = create_rw_signal(0u32);

    // Track animation viewed after it completes (when animated)
    if animation_enabled {
        set_timeout(
            move || {
                track_event(AnalyticsEvent::AnimationViewed);
            },
            std::time::Duration::from_millis(12000),
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
            aria-label="Demonstration: Cmd+N stacks a new window on Finder, cursor drags and closes it, activates WindowDrop in the menu bar, then Cmd+N opens a new window under the cursor"
        >
            {move || {
                let _ = replay_key.get();
                view! {
                    <div class="hero-animation-stage">
                        {if animation_enabled {
                            view! { <AnimatedDemo /> }.into_view()
                        } else {
                            view! { <StaticDemo /> }.into_view()
                        }}
                    </div>
                }
            }}
            {if show_footer {
                view! {
                    <div class="hero-animation-footer">
                        <p class="hero-animation-caption">
                            "Default Cmd+N stacks windows. Activate WindowDrop, then "<kbd>"⌘N"</kbd>" opens new windows under your cursor."
                        </p>
                    </div>
                }
                    .into_view()
            } else {
                ().into_view()
            }}
        </div>
    }
}

/// The animated SVG demonstration.
#[component]
fn AnimatedDemo() -> impl IntoView {
    view! {
        <svg
            class="hero-animation-svg"
            viewBox="0 0 900 520"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
        >
            <defs>
                <pattern id="grid" width="48" height="48" patternUnits="userSpaceOnUse">
                    <path d="M 48 0 L 0 0 0 48" fill="none" stroke="#E2E8F0" stroke-width="0.6"/>
                </pattern>
                <linearGradient id="macosDesktop" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#E8EEF4"/>
                    <stop offset="40%" style="stop-color:#F0F4F8"/>
                    <stop offset="100%" style="stop-color:#F8FAFC"/>
                </linearGradient>
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

            // Single large display background
            <rect width="900" height="520" fill="url(#grid)"/>
            <rect x="24" y="16" width="852" height="488" rx="14" fill="url(#macosDesktop)" stroke="#E2E8F0" stroke-width="1.2"/>

            // Menu bar
            <rect x="24" y="16" width="852" height="28" rx="14" fill="#F1F5F9"/>
            <rect x="24" y="30" width="852" height="14" fill="#F1F5F9"/>

            // WindowDrop status in menu bar: off -> on (cursor clicks to activate)
            <g class="windowdrop-toggle-off">
                <rect x="712" y="20" width="150" height="20" rx="10" fill="#E2E8F0" stroke="#CBD5E1" stroke-width="1"/>
                <circle cx="726" cy="30" r="4" fill="#94A3B8"/>
                <text x="788" y="34" text-anchor="middle" fill="#475569" font-size="11" font-weight="600">
                    "Activate WindowDrop"
                </text>
            </g>
            <g class="windowdrop-toggle-on">
                <rect x="712" y="20" width="150" height="20" rx="10" fill="#DCFCE7" stroke="#86EFAC" stroke-width="1"/>
                <circle cx="726" cy="30" r="4" fill="#16A34A"/>
                <text x="790" y="34" text-anchor="middle" fill="#166534" font-size="11" font-weight="700">
                    "WindowDrop Active"
                </text>
            </g>

            // Existing Finder window
            <g class="existing-window">
                <rect
                    x="130"
                    y="120"
                    width="305"
                    height="220"
                    rx="6"
                    fill="url(#windowGradient)"
                    stroke="#D1D5DB"
                    stroke-width="1"
                    filter="url(#windowShadow)"
                />
                // Title bar
                <rect x="130" y="120" width="305" height="26" rx="6" fill="url(#titleBarGradient)"/>
                <rect x="130" y="140" width="305" height="6" fill="url(#titleBarGradient)"/>
                // Traffic lights
                <circle cx="146" cy="133" r="5" fill="#FF5F57"/>
                <circle cx="162" cy="133" r="5" fill="#FEBC2E"/>
                <circle cx="178" cy="133" r="5" fill="#28C840"/>
                <text x="282" y="137" text-anchor="middle" fill="#6B7280" font-size="11" font-weight="600">
                    "Finder"
                </text>
                // Content placeholder
                <rect x="148" y="164" width="106" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="148" y="182" width="176" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="148" y="200" width="132" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="148" y="218" width="156" height="9" rx="2" fill="#E5E7EB"/>
            </g>

            // Default behavior window (offset down-left over existing Finder window)
            <g class="hero-window-default">
                <rect
                    x="108"
                    y="168"
                    width="305"
                    height="220"
                    rx="6"
                    fill="url(#windowGradient)"
                    stroke="#94A3B8"
                    stroke-width="1.5"
                    filter="url(#windowShadow)"
                />
                <rect x="108" y="168" width="305" height="26" rx="6" fill="url(#titleBarGradient)"/>
                <rect x="108" y="188" width="305" height="6" fill="url(#titleBarGradient)"/>
                <circle cx="124" cy="181" r="5" fill="#FF5F57"/>
                <circle cx="140" cy="181" r="5" fill="#FEBC2E"/>
                <circle cx="156" cy="181" r="5" fill="#28C840"/>
                <text x="258" y="185" text-anchor="middle" fill="#6B7280" font-size="11" font-weight="600">
                    "New Finder Window"
                </text>
                <rect x="126" y="212" width="106" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="126" y="230" width="176" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="126" y="248" width="132" height="9" rx="2" fill="#E5E7EB"/>
            </g>

            // First Cmd+N (default behavior) - positioned below cursor to signal "key pressed"
            <g class="hero-keys-default">
                <rect x="552" y="238" width="96" height="42" rx="8" fill="rgba(23, 23, 23, 0.92)" filter="url(#keyShadow)"/>
                <text x="600" y="265" text-anchor="middle" fill="white" font-family="-apple-system, BlinkMacSystemFont, monospace" font-size="17" font-weight="600">
                    "⌘ N"
                </text>
            </g>

            // Story labels
            <g class="hero-mode-default">
                <rect x="52" y="454" width="360" height="36" rx="18" fill="rgba(15, 23, 42, 0.82)"/>
                <text x="232" y="476" text-anchor="middle" fill="#F8FAFC" font-size="13" font-weight="600">
                    "Default: new window stacks, drag to move, then close"
                </text>
            </g>
            <g class="hero-mode-windowdrop">
                <rect x="52" y="454" width="360" height="36" rx="18" fill="rgba(22, 163, 74, 0.88)"/>
                <text x="232" y="476" text-anchor="middle" fill="#ECFDF5" font-size="13" font-weight="700">
                    "WindowDrop: new window appears under cursor"
                </text>
            </g>

            // WindowDrop behavior window (under cursor in target area)
            <g class="hero-window-windowdrop">
                <rect
                    x="540"
                    y="230"
                    width="290"
                    height="205"
                    rx="6"
                    fill="url(#windowGradient)"
                    stroke="#3B82F6"
                    stroke-width="2"
                    filter="url(#windowShadow)"
                />
                // Title bar
                <rect x="540" y="230" width="290" height="26" rx="6" fill="url(#titleBarGradient)"/>
                <rect x="540" y="250" width="290" height="6" fill="url(#titleBarGradient)"/>
                // Traffic lights
                <circle cx="556" cy="243" r="5" fill="#FF5F57"/>
                <circle cx="572" cy="243" r="5" fill="#FEBC2E"/>
                <circle cx="588" cy="243" r="5" fill="#28C840"/>
                <text x="685" y="247" text-anchor="middle" fill="#6B7280" font-size="11" font-weight="600">
                    "Finder"
                </text>
                <rect x="558" y="274" width="106" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="558" y="292" width="176" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="558" y="310" width="132" height="9" rx="2" fill="#E5E7EB"/>
            </g>

            // Second Cmd+N (WindowDrop behavior) - rendered after window so it stays visible
            <g class="hero-keys-windowdrop">
                <rect x="624" y="298" width="96" height="42" rx="8" fill="rgba(23, 23, 23, 0.92)" filter="url(#keyShadow)"/>
                <text x="672" y="325" text-anchor="middle" fill="white" font-family="-apple-system, BlinkMacSystemFont, monospace" font-size="17" font-weight="600">
                    "⌘ N"
                </text>
            </g>

            // Cursor (rendered last so it stays on top of all windows)
            <g class="hero-cursor">
                <path
                    d="M0 0 L0 17 L4 13 L7 20 L10 19 L7 12 L12 12 Z"
                    fill="#171717"
                    stroke="#FFFFFF"
                    stroke-width="1.5"
                />
            </g>

            // Cursor target highlight
            <circle class="cursor-highlight" cx="664" cy="284" r="26" fill="none" stroke="#3B82F6" stroke-width="2" stroke-dasharray="4 4" opacity="0"/>
        </svg>
    }
}

/// Static fallback for reduced motion.
#[component]
fn StaticDemo() -> impl IntoView {
    view! {
        <svg
            class="hero-animation-svg hero-animation-svg--static"
            viewBox="0 0 900 520"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
        >
            <defs>
                <pattern id="grid-static" width="48" height="48" patternUnits="userSpaceOnUse">
                    <path d="M 48 0 L 0 0 0 48" fill="none" stroke="#E2E8F0" stroke-width="0.6"/>
                </pattern>
                <linearGradient id="macosDesktop-static" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" style="stop-color:#E8EEF4"/>
                    <stop offset="40%" style="stop-color:#F0F4F8"/>
                    <stop offset="100%" style="stop-color:#F8FAFC"/>
                </linearGradient>
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

            // Single large display background
            <rect width="900" height="520" fill="url(#grid-static)"/>
            <rect x="24" y="16" width="852" height="488" rx="14" fill="url(#macosDesktop-static)" stroke="#E2E8F0" stroke-width="1.2"/>

            // Menu bar
            <rect x="24" y="16" width="852" height="28" rx="14" fill="#F1F5F9"/>
            <rect x="24" y="30" width="852" height="14" fill="#F1F5F9"/>
            <rect x="712" y="20" width="150" height="20" rx="10" fill="#DCFCE7" stroke="#86EFAC" stroke-width="1"/>
            <circle cx="726" cy="30" r="4" fill="#16A34A"/>
            <text x="790" y="34" text-anchor="middle" fill="#166534" font-size="11" font-weight="700">
                "WindowDrop Active"
            </text>

            // Existing Finder window
            <g>
                <rect x="130" y="120" width="305" height="220" rx="6" fill="url(#windowGradient-static)" stroke="#D1D5DB" stroke-width="1" filter="url(#windowShadow-static)"/>
                <rect x="130" y="120" width="305" height="26" rx="6" fill="url(#titleBarGradient-static)"/>
                <rect x="130" y="140" width="305" height="6" fill="#E2E8F0"/>
                <circle cx="146" cy="133" r="5" fill="#FF5F57"/>
                <circle cx="162" cy="133" r="5" fill="#FEBC2E"/>
                <circle cx="178" cy="133" r="5" fill="#28C840"/>
                <text x="282" y="137" text-anchor="middle" fill="#6B7280" font-size="11" font-weight="600">"Finder"</text>
                <rect x="148" y="164" width="106" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="148" y="182" width="176" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="148" y="200" width="132" height="9" rx="2" fill="#E5E7EB"/>
            </g>

            // Default behavior result shown as ghosted overlap
            <g opacity="0.35">
                <rect x="108" y="168" width="305" height="220" rx="6" fill="url(#windowGradient-static)" stroke="#94A3B8" stroke-width="1.5" filter="url(#windowShadow-static)"/>
                <rect x="108" y="168" width="305" height="26" rx="6" fill="#E2E8F0"/>
                <rect x="108" y="188" width="305" height="6" fill="#E2E8F0"/>
            </g>

            // Cursor at final target area
            <g transform="translate(702, 278)">
                <path d="M0 0 L0 17 L4 13 L7 20 L10 19 L7 12 L12 12 Z" fill="#171717" stroke="#FFFFFF" stroke-width="1.5"/>
            </g>

            // WindowDrop result window
            <g>
                <rect x="540" y="230" width="290" height="205" rx="6" fill="url(#windowGradient-static)" stroke="#3B82F6" stroke-width="2" filter="url(#windowShadow-static)"/>
                <rect x="540" y="230" width="290" height="26" rx="6" fill="url(#titleBarGradient-static)"/>
                <rect x="540" y="250" width="290" height="6" fill="#E2E8F0"/>
                <circle cx="556" cy="243" r="5" fill="#FF5F57"/>
                <circle cx="572" cy="243" r="5" fill="#FEBC2E"/>
                <circle cx="588" cy="243" r="5" fill="#28C840"/>
                <text x="685" y="247" text-anchor="middle" fill="#6B7280" font-size="11" font-weight="600">"Finder"</text>
                <rect x="558" y="274" width="106" height="9" rx="2" fill="#E5E7EB"/>
                <rect x="558" y="292" width="176" height="9" rx="2" fill="#E5E7EB"/>
            </g>

            <rect x="52" y="454" width="360" height="36" rx="18" fill="rgba(22, 163, 74, 0.88)"/>
            <text x="232" y="476" text-anchor="middle" fill="#ECFDF5" font-size="13" font-weight="700">
                "WindowDrop: new window appears under cursor"
            </text>
            <circle cx="664" cy="284" r="22" fill="none" stroke="#3B82F6" stroke-width="2" stroke-dasharray="4 4" opacity="0"/>
        </svg>
    }
}
