use leptos::*;

#[component]
pub fn LiquidBackground() -> impl IntoView {
    view! {
        <div class="liquid-background">
            <div class="liquid-blob liquid-blob-1"></div>
            <div class="liquid-blob liquid-blob-2"></div>
            <div class="liquid-blob liquid-blob-3"></div>
            <style>
                "
                .liquid-background {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    z-index: -1;
                    overflow: hidden;
                    pointer-events: none;
                }

                .liquid-blob {
                    position: absolute;
                    border-radius: 50%;
                    filter: blur(80px);
                    opacity: 0.3;
                    mix-blend-mode: multiply;
                }

                .liquid-blob-1 {
                    width: 500px;
                    height: 500px;
                    top: -100px;
                    left: -100px;
                    background: radial-gradient(circle, #3B82F6 0%, transparent 70%);
                    animation: blobMove1 20s ease-in-out infinite;
                }

                .liquid-blob-2 {
                    width: 600px;
                    height: 600px;
                    top: 50%;
                    right: -150px;
                    background: radial-gradient(circle, #60A5FA 0%, transparent 70%);
                    animation: blobMove2 25s ease-in-out infinite reverse;
                }

                .liquid-blob-3 {
                    width: 450px;
                    height: 450px;
                    bottom: -100px;
                    left: 50%;
                    background: radial-gradient(circle, #93C5FD 0%, transparent 70%);
                    animation: blobMove3 30s ease-in-out infinite;
                }

                @keyframes blobMove1 {
                    0%, 100% {
                        transform: translate(0, 0) scale(1);
                    }
                    33% {
                        transform: translate(50px, 100px) scale(1.1);
                    }
                    66% {
                        transform: translate(-30px, 50px) scale(0.95);
                    }
                }

                @keyframes blobMove2 {
                    0%, 100% {
                        transform: translate(0, 0) scale(1);
                    }
                    33% {
                        transform: translate(-80px, -50px) scale(1.15);
                    }
                    66% {
                        transform: translate(40px, 80px) scale(0.9);
                    }
                }

                @keyframes blobMove3 {
                    0%, 100% {
                        transform: translate(-50%, 0) scale(1);
                    }
                    33% {
                        transform: translate(calc(-50% + 60px), -70px) scale(1.05);
                    }
                    66% {
                        transform: translate(calc(-50% - 40px), 30px) scale(1.1);
                    }
                }

                @media (prefers-reduced-motion: reduce) {
                    .liquid-blob {
                        animation: none;
                    }
                }
                "
            </style>
        </div>
    }
}
