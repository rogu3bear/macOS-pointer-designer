FROM rust:1-bookworm AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    nodejs npm \
    pkg-config \
    libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN rustup target add wasm32-unknown-unknown
RUN CARGO_PROFILE_RELEASE_LTO=off CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 cargo install trunk --locked

WORKDIR /src
COPY site ./site

# Build SPA assets and SSR server
RUN cd site \
  && ./scripts/build-release.sh

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates libssl3 curl \
  && rm -rf /var/lib/apt/lists/* \
  && useradd -r -u 10001 -g nogroup app

WORKDIR /app

COPY --from=builder /src/site/target/release/windowdrop-server /app/windowdrop-server
COPY --from=builder /src/site/dist /app/dist

RUN chown -R app:nogroup /app
USER app

ENV PORT=3410 \
    # Runtime configuration is provided via environment variables (e.g. docker-compose `env_file`).
    # Do not bake secrets into the image.
    RUST_LOG=info

EXPOSE 3410
CMD ["/app/windowdrop-server"]
