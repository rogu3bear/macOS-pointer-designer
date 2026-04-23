//! Hero demo block: title → graphic slides up → animation → how it works → collapse to Replay.
//!
//! Sequence: "New windows appear under your mouse" (moment) → graphic moves up →
//! show how it works → graphic moves down → all rolls up into subtle Replay button.

use leptos::*;

use crate::analytics::{track_event, AnalyticsEvent};
use crate::components::hero_animation::HeroAnimation;
use leptos_router::A;

/// Phases: 0=title, 1=graphic up, 2=animation, 3=how it works, 4=graphic down, 5=replay
const PHASE_TITLE_MS: u64 = 2000;
const PHASE_GRAPHIC_UP_MS: u64 = 1500;
const ANIMATION_MS: u64 = 12000;
const PHASE_HOW_MS: u64 = 2500;
const PHASE_GRAPHIC_DOWN_MS: u64 = 1000;
const PHASE_COLLAPSE_MS: u64 = 800;

/// Total sequence duration before Replay appears.
fn total_sequence_ms() -> u64 {
    PHASE_TITLE_MS
        + PHASE_GRAPHIC_UP_MS
        + ANIMATION_MS
        + PHASE_HOW_MS
        + PHASE_GRAPHIC_DOWN_MS
        + PHASE_COLLAPSE_MS
}

#[component]
pub fn HeroDemoBlock() -> impl IntoView {
    let phase = create_rw_signal(0u8);
    let replay_key = create_rw_signal(0u32);

    // Advance phases
    create_effect(move |_| {
        let _ = replay_key.get();
        phase.set(0);

        let advance = move |to: u8| {
            let delay_ms = match to {
                1 => PHASE_TITLE_MS,
                2 => PHASE_TITLE_MS + PHASE_GRAPHIC_UP_MS,
                3 => PHASE_TITLE_MS + PHASE_GRAPHIC_UP_MS + ANIMATION_MS,
                4 => PHASE_TITLE_MS + PHASE_GRAPHIC_UP_MS + ANIMATION_MS + PHASE_HOW_MS,
                5 => {
                    PHASE_TITLE_MS
                        + PHASE_GRAPHIC_UP_MS
                        + ANIMATION_MS
                        + PHASE_HOW_MS
                        + PHASE_GRAPHIC_DOWN_MS
                }
                6 => total_sequence_ms(),
                _ => 0,
            };
            if delay_ms > 0 {
                set_timeout(
                    move || phase.set(to),
                    std::time::Duration::from_millis(delay_ms),
                );
            }
        };

        advance(1);
        advance(2);
        advance(3);
        advance(4);
        advance(5);
        advance(6);
    });

    let on_download_click = move |_| {
        track_event(AnalyticsEvent::CtaPrimaryClicked);
    };

    view! {
        <div class="hero-demo-block" data-phase=move || phase.get().to_string()>
            <div class="hero-demo-title">
                <h1 class="hero-demo-title-text">
                    "New windows appear "
                    <span class="text-gradient">"under your mouse."</span>
                </h1>
            </div>

            <div class="hero-demo-graphic">
                {move || {
                    let _ = replay_key.get();
                    view! { <HeroAnimation show_footer=false /> }
                }}
            </div>

            <div class="hero-demo-how">
                <h2 class="hero-demo-how-title">"How it works"</h2>
                <div class="hero-demo-how-steps">
                    <div class="hero-demo-step">
                        <span class="hero-demo-step-num">"1"</span>
                        <span class="hero-demo-step-text">"Enable WindowDrop"</span>
                    </div>
                    <div class="hero-demo-step">
                        <span class="hero-demo-step-num">"2"</span>
                        <span class="hero-demo-step-text">"Position your cursor"</span>
                    </div>
                    <div class="hero-demo-step">
                        <span class="hero-demo-step-num">"3"</span>
                        <span class="hero-demo-step-text">"Press ⌘N"</span>
                    </div>
                    <div class="hero-demo-step">
                        <span class="hero-demo-step-num">"✓"</span>
                        <span class="hero-demo-step-text">"Window appears at cursor"</span>
                    </div>
                </div>
            </div>

            <div class="hero-demo-cta">
                <A
                    href="/download"
                    class="hero-demo-download"
                    on:click=on_download_click
                >
                    "Download Free"
                </A>
            </div>
        </div>
    }
}
