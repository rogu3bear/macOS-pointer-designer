use leptos::*;

/// Premium SVG icons for WindowDrop
/// All icons are inline SVGs for optimal performance and styling flexibility

#[component]
pub fn IconFolder(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-folder"
        >
            <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
        </svg>
    }
}

#[component]
pub fn IconCompass(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-compass"
        >
            <circle cx="12" cy="12" r="10"/>
            <polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76" fill=color/>
        </svg>
    }
}

#[component]
pub fn IconMail(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-mail"
        >
            <rect x="2" y="4" width="20" height="16" rx="2"/>
            <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
        </svg>
    }
}

#[component]
pub fn IconNotes(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-notes"
        >
            <path d="M16 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8Z"/>
            <path d="M15 3v4a2 2 0 0 0 2 2h4"/>
            <path d="M7 13h10"/>
            <path d="M7 17h6"/>
        </svg>
    }
}

#[component]
pub fn IconImage(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-image"
        >
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
            <circle cx="9" cy="9" r="2"/>
            <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>
        </svg>
    }
}

#[component]
pub fn IconTextEdit(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-textedit"
        >
            <path d="M12 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
            <path d="M18.375 2.625a2.121 2.121 0 1 1 3 3L12 15l-4 1 1-4Z"/>
        </svg>
    }
}

#[component]
pub fn IconCheck(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-check"
        >
            <polyline points="20 6 9 17 4 12"/>
        </svg>
    }
}

#[component]
pub fn IconCheckCircle(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-check-circle"
        >
            <circle cx="12" cy="12" r="10"/>
            <path d="m9 12 2 2 4-4"/>
        </svg>
    }
}

#[component]
pub fn IconArrowRight(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-arrow-right"
        >
            <path d="M5 12h14"/>
            <path d="m12 5 7 7-7 7"/>
        </svg>
    }
}

#[component]
pub fn IconArrowDown(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-arrow-down"
        >
            <path d="M12 5v14"/>
            <path d="m19 12-7 7-7-7"/>
        </svg>
    }
}

#[component]
pub fn IconDownload(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-download"
        >
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="7 10 12 15 17 10"/>
            <line x1="12" x2="12" y1="15" y2="3"/>
        </svg>
    }
}

#[component]
pub fn IconCursor(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-cursor"
        >
            <path d="m4 4 7.07 17 2.51-7.39L21 11.07z"/>
        </svg>
    }
}

#[component]
pub fn IconWindow(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-window"
        >
            <rect x="3" y="3" width="18" height="18" rx="2"/>
            <path d="M3 9h18"/>
            <circle cx="7" cy="6" r="0.5" fill=color/>
            <circle cx="10" cy="6" r="0.5" fill=color/>
            <circle cx="13" cy="6" r="0.5" fill=color/>
        </svg>
    }
}

#[component]
pub fn IconShield(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-shield"
        >
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
        </svg>
    }
}

#[component]
pub fn IconShieldCheck(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-shield-check"
        >
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
            <path d="m9 12 2 2 4-4"/>
        </svg>
    }
}

#[component]
pub fn IconSupport(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-support"
        >
            <circle cx="12" cy="12" r="10"/>
            <circle cx="12" cy="12" r="4"/>
            <line x1="4.93" x2="9.17" y1="4.93" y2="9.17"/>
            <line x1="14.83" x2="19.07" y1="14.83" y2="19.07"/>
            <line x1="14.83" x2="19.07" y1="9.17" y2="4.93"/>
            <line x1="14.83" x2="18.36" y1="9.17" y2="5.64"/>
            <line x1="4.93" x2="9.17" y1="19.07" y2="14.83"/>
        </svg>
    }
}

#[component]
pub fn IconQuestion(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-question"
        >
            <circle cx="12" cy="12" r="10"/>
            <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>
            <path d="M12 17h.01"/>
        </svg>
    }
}

#[component]
pub fn IconBook(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-book"
        >
            <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>
        </svg>
    }
}

#[component]
pub fn IconTerminal(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-terminal"
        >
            <polyline points="4 17 10 11 4 5"/>
            <line x1="12" x2="20" y1="19" y2="19"/>
        </svg>
    }
}

#[component]
pub fn IconClock(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-clock"
        >
            <circle cx="12" cy="12" r="10"/>
            <polyline points="12 6 12 12 16 14"/>
        </svg>
    }
}

#[component]
pub fn IconStar(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-star"
        >
            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
        </svg>
    }
}

#[component]
pub fn IconZap(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-zap"
        >
            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
        </svg>
    }
}

#[component]
pub fn IconApple(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill=color
            class="icon icon-apple"
        >
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
        </svg>
    }
}

#[component]
pub fn IconExternalLink(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-external-link"
        >
            <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
            <polyline points="15 3 21 3 21 9"/>
            <line x1="10" x2="21" y1="14" y2="3"/>
        </svg>
    }
}

#[component]
pub fn IconChevronRight(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-chevron-right"
        >
            <path d="m9 18 6-6-6-6"/>
        </svg>
    }
}

#[component]
pub fn IconEye(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-eye"
        >
            <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/>
            <circle cx="12" cy="12" r="3"/>
        </svg>
    }
}

#[component]
pub fn IconEyeOff(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-eye-off"
        >
            <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24"/>
            <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68"/>
            <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61"/>
            <line x1="2" x2="22" y1="2" y2="22"/>
        </svg>
    }
}

#[component]
pub fn IconWifi(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-wifi"
        >
            <path d="M5 12.55a11 11 0 0 1 14.08 0"/>
            <path d="M1.42 9a16 16 0 0 1 21.16 0"/>
            <path d="M8.53 16.11a6 6 0 0 1 6.95 0"/>
            <line x1="12" x2="12.01" y1="20" y2="20"/>
        </svg>
    }
}

#[component]
pub fn IconWifiOff(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-wifi-off"
        >
            <line x1="2" x2="22" y1="2" y2="22"/>
            <path d="M8.5 16.5a5 5 0 0 1 7 0"/>
            <path d="M2 8.82a15 15 0 0 1 4.17-2.65"/>
            <path d="M10.66 5c4.01-.36 8.14.9 11.34 3.76"/>
            <path d="M16.85 11.25a10 10 0 0 1 2.22 1.68"/>
            <path d="M5 13a10 10 0 0 1 5.24-2.76"/>
            <line x1="12" x2="12.01" y1="20" y2="20"/>
        </svg>
    }
}

#[component]
pub fn IconTag(
    #[prop(default = 24)] size: u32,
    #[prop(default = "currentColor")] color: &'static str,
) -> impl IntoView {
    view! {
        <svg
            width=size
            height=size
            viewBox="0 0 24 24"
            fill="none"
            stroke=color
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="icon icon-tag"
        >
            <path d="M12 2H2v10l9.29 9.29c.94.94 2.48.94 3.42 0l6.58-6.58c.94-.94.94-2.48 0-3.42L12 2Z"/>
            <path d="M7 7h.01"/>
        </svg>
    }
}
