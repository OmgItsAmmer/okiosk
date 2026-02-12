# Root Dockerfile
# This file is provided to fix the "open Dockerfile: no such file or directory" error.
# It defaults to building the Rust backend, which is common for multi-service repos on many platforms.

# Build stage
FROM rust:1.81-slim-bookworm as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy backend manifests
COPY kks_online_backend/Cargo.toml kks_online_backend/Cargo.lock ./
COPY kks_online_backend/migrations ./migrations

# Create a dummy src/main.rs to cache dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copy backend source code
COPY kks_online_backend/src ./src

# Build the actual application
RUN touch src/main.rs && cargo build --release

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
COPY kks_online_backend/.env.example .env

# Set default environment variables
ENV HOST=0.0.0.0
ENV PORT=3000

EXPOSE 3000

CMD ["./kks_online_backend"]
