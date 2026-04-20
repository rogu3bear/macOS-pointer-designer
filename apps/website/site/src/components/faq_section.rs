//! FAQ section component.
//!
//! Common questions answered without pricing or feature tier mentions.

use leptos::*;

/// A single FAQ item.
struct FaqItem {
    question: &'static str,
    answer: &'static str,
}

const FAQ_ITEMS: [FaqItem; 4] = [
    FaqItem {
        question: "What does WindowDrop do?",
        answer: "WindowDrop changes where new windows appear. When you press ⌘N in Finder or Safari, the new window opens under your mouse cursor instead of in the default position.",
    },
    FaqItem {
        question: "Which apps work with WindowDrop?",
        answer: "Currently, WindowDrop works with Finder and Safari. Support for more apps is planned.",
    },
    FaqItem {
        question: "Does WindowDrop access my data?",
        answer: "No. WindowDrop uses macOS Accessibility to move windows. It does not read or access page content, files, or any personal data.",
    },
    FaqItem {
        question: "What macOS versions are supported?",
        answer: "WindowDrop requires macOS 11 (Big Sur) or later.",
    },
];

/// FAQ section component.
#[component]
pub fn FaqSection() -> impl IntoView {
    view! {
        <section class="section faq-section" id="faq">
            <div class="container container-narrow">
                <h2 class="section-title">"Questions"</h2>
                <div class="faq-list">
                    {FAQ_ITEMS.iter().map(|item| {
                        view! {
                            <div class="faq-item">
                                <h3 class="faq-question">{item.question}</h3>
                                <p class="faq-answer">{item.answer}</p>
                            </div>
                        }
                    }).collect::<Vec<_>>()}
                </div>
            </div>
        </section>
    }
}
