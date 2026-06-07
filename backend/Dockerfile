# Build stage
FROM rust:1.92-slim-bookworm AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml Cargo.lock ./
COPY migrations ./migrations

# Dummy sources for dependency layer caching (must match [lib] + [[bin]] in Cargo.toml)
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    echo "// dependency cache stub" > src/lib.rs
RUN cargo build --release
RUN rm -rf src

# Copy source code
COPY src ./src

# Rebuild application (touch sources so Cargo recompiles the crate, not just deps)
RUN touch src/main.rs src/lib.rs && cargo build --release

# Final stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /app/target/release/kks_online_backend .

# Copy env file example
# COPY .env.example .env

# Set default environment variables
ENV HOST=0.0.0.0
ENV PORT=3000

EXPOSE 3000

CMD ["./kks_online_backend"]
