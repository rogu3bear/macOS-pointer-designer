//! Value section component for framing product benefits.
//!
//! Communicates value units (time saved, reduced frustration, predictable behavior)
//! without mentioning pricing or features.

use leptos::*;

/// A single value proposition.
struct ValueProp {
    headline: &'static str,
    description: &'static str,
}

const VALUE_PROPS: [ValueProp; 3] = [
    ValueProp {
        headline: "Your windows appear where you are",
        description: "No more hunting across screens. New windows open right at your cursor.",
    },
    ValueProp {
        headline: "Stay in your flow",
        description: "Stop interrupting your work to drag windows. Stay focused on what matters.",
    },
    ValueProp {
        headline: "Works the way you expect",
        description: "Simple, predictable behavior. Press ⌘N and your window is there.",
    },
];

/// Value section displaying core benefits.
#[component]
pub fn ValueSection() -> impl IntoView {
    view! {
        <section class="section value-section" id="value">
            <div class="container">
                <h2 class="section-title">"Why WindowDrop?"</h2>
                <div class="value-grid">
                    {VALUE_PROPS.iter().map(|prop| {
                        view! {
                            <div class="value-card">
                                <h3 class="value-card-headline">{prop.headline}</h3>
                                <p class="value-card-description">{prop.description}</p>
                            </div>
                        }
                    }).collect::<Vec<_>>()}
                </div>
            </div>
        </section>
    }
}
