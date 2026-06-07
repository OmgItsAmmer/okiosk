# Makefile for Okiosk Project
# Development, CI, Docker, and fly.io deployment

BACKEND_DIR := backend
FRONTEND_DIR := react-frontend
TEST_DB_CONTAINER := okiosk-test-db
TEST_DATABASE_URL ?= postgresql://postgres:postgres@localhost:5432/okiosk_test

# Test/CI env vars (mirrors .github/workflows/backend-ci.yml)
export OPENAI_API_KEY ?= sk-test-ci-key-not-used
export OPENAI_MODEL ?= gpt-4o-mini
export JWT_SECRET ?= test-jwt-secret-for-ci-only-min-32-chars
export GOOGLE_CLIENT_ID ?= test-client-id.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET ?= test-client-secret
export GOOGLE_REDIRECT_URI ?= http://localhost:3000/api/auth/google/callback
export APP_ENV ?= test
export DATABASE_URL ?= $(TEST_DATABASE_URL)

.PHONY: help install run-backend run-frontend dev build-backend build-frontend \
	docker-up docker-down \
	backend-fmt backend-fmt-check backend-clippy \
	backend-test backend-test-integration backend-test-db-up backend-test-db-down backend-test-db-schema \
	backend-build backend-ci backend-docker backend-docker-fly \
	fly-deploy fly-checks fly-secrets

# Default target: display help instructions
help:
	@echo "================================================================"
	@echo "                     Okiosk Makefile Tool                       "
	@echo "================================================================"
	@echo "Development:"
	@echo "  make install              Install frontend dependencies"
	@echo "  make run-backend          Run Rust backend locally"
	@echo "  make run-frontend         Run React frontend locally"
	@echo "  make build-backend        Build backend (release)"
	@echo "  make build-frontend       Build frontend production assets"
	@echo ""
	@echo "Docker Compose:"
	@echo "  make docker-up            Start all services (backend + frontend + db)"
	@echo "  make docker-down          Stop Docker Compose stack"
	@echo ""
	@echo "Backend quality (local CI):"
	@echo "  make backend-fmt          Format Rust code"
	@echo "  make backend-fmt-check    Check Rust formatting (CI)"
	@echo "  make backend-clippy       Run clippy lints (CI)"
	@echo "  make backend-test         Run unit/feature tests (no DB integration)"
	@echo "  make backend-test-integration  Run all tests incl. HTTP/DB (needs Postgres)"
	@echo "  make backend-build        Release build (CI)"
	@echo "  make backend-ci           Full CI pipeline locally"
	@echo ""
	@echo "Backend test database:"
	@echo "  make backend-test-db-up     Start Postgres 15 container for tests"
	@echo "  make backend-test-db-schema Apply minimal test schema"
	@echo "  make backend-test-db-down   Stop/remove test Postgres container"
	@echo ""
	@echo "Backend Docker / fly.io:"
	@echo "  make backend-docker       Build backend/Dockerfile image"
	@echo "  make backend-docker-fly   Build root Dockerfile (fly.io image)"
	@echo "  make fly-deploy           Deploy backend to fly.io"
	@echo "  make fly-checks           List fly.io health checks"
	@echo "  make fly-secrets          Show fly.io secrets command hint"
	@echo "================================================================"

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------

install:
	@echo "Installing frontend dependencies..."
	cd $(FRONTEND_DIR) && npm install

run-backend:
	@echo "Starting Rust backend..."
	cd $(BACKEND_DIR) && cargo run

run-frontend:
	@echo "Starting React Vite frontend..."
	cd $(FRONTEND_DIR) && npm run dev

build-backend: backend-build

build-frontend:
	@echo "Building React frontend..."
	cd $(FRONTEND_DIR) && npm run build

docker-up:
	@echo "Spinning up Docker containers..."
	docker-compose up --build

docker-down:
	@echo "Spinning down Docker containers..."
	docker-compose down

# ---------------------------------------------------------------------------
# Backend CI (mirrors GitHub Actions backend-ci.yml)
# ---------------------------------------------------------------------------

backend-fmt:
	@echo "Formatting Rust backend..."
	cd $(BACKEND_DIR) && cargo fmt --all

backend-fmt-check:
	@echo "Checking Rust formatting..."
	cd $(BACKEND_DIR) && cargo fmt --all -- --check

backend-clippy:
	@echo "Running clippy..."
	cd $(BACKEND_DIR) && cargo clippy --all-targets --all-features

backend-test:
	@echo "Running backend tests (unit/feature; DB integration skipped unless RUN_DB_TESTS=1)..."
	cd $(BACKEND_DIR) && cargo test

backend-test-integration: export RUN_DB_TESTS=1
backend-test-integration: backend-test-db-schema
	@echo "Running backend tests with DB integration..."
	cd $(BACKEND_DIR) && cargo test --verbose

backend-build:
	@echo "Building Rust backend in release mode..."
	cd $(BACKEND_DIR) && cargo build --release

backend-ci: backend-fmt-check backend-clippy backend-test-integration backend-build backend-docker backend-docker-fly
	@echo "Backend CI completed successfully."

# ---------------------------------------------------------------------------
# Test Postgres (local mirror of CI service container)
# ---------------------------------------------------------------------------

backend-test-db-up:
	@echo "Starting test Postgres container ($(TEST_DB_CONTAINER))..."
	-docker rm -f $(TEST_DB_CONTAINER) 2>/dev/null
	docker run -d --name $(TEST_DB_CONTAINER) \
		-e POSTGRES_USER=postgres \
		-e POSTGRES_PASSWORD=postgres \
		-e POSTGRES_DB=okiosk_test \
		-p 5432:5432 \
		postgres:15-alpine
	@echo "Waiting for Postgres to become ready..."
	@sleep 3

backend-test-db-down:
	@echo "Stopping test Postgres container..."
	-docker rm -f $(TEST_DB_CONTAINER) 2>/dev/null

backend-test-db-schema:
	@echo "Applying test schema to $(TEST_DATABASE_URL)..."
	psql "$(TEST_DATABASE_URL)" -f $(BACKEND_DIR)/tests/fixtures/minimal_schema.sql

# ---------------------------------------------------------------------------
# Docker images
# ---------------------------------------------------------------------------

backend-docker:
	@echo "Building backend Docker image..."
	docker build -t okiosk-backend:local -f $(BACKEND_DIR)/Dockerfile $(BACKEND_DIR)

backend-docker-fly:
	@echo "Building fly.io Docker image (root Dockerfile)..."
	docker build -t okiosk-backend:fly -f Dockerfile .

# ---------------------------------------------------------------------------
# fly.io deployment (mirrors .github/workflows/backend-deploy.yml)
# ---------------------------------------------------------------------------

fly-deploy:
	@echo "Deploying backend to fly.io (sin, single machine, auto-sleep)..."
	cd $(BACKEND_DIR) && flyctl deploy --remote-only --ha=false --regions sin --config fly.toml --dockerfile Dockerfile

fly-checks:
	@echo "Listing fly.io health checks..."
	cd $(BACKEND_DIR) && flyctl checks list --config fly.toml

fly-secrets:
	@echo "Set production secrets on fly.io (run once, replace values):"
	@echo "  cd $(BACKEND_DIR) && fly secrets set \\"
	@echo "    DATABASE_URL=... OPENAI_API_KEY=... JWT_SECRET=... \\"
	@echo "    GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=... GOOGLE_REDIRECT_URI=..."
