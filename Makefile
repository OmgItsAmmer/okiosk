# Makefile for Okiosk Project
# Handles development, build, and docker tasks

.PHONY: help install run-backend run-frontend dev build docker-up docker-down

# Default target: display help instructions
help:
	@echo "================================================================"
	@echo "                     Okiosk Makefile Tool                       "
	@echo "================================================================"
	@echo "Available commands:"
	@echo "  make install         - Install all frontend dependencies"
	@echo "  make run-backend     - Run the Rust backend service locally"
	@echo "  make run-frontend    - Run the React frontend service locally"
	@echo "  make build-backend   - Build the backend in release mode"
	@echo "  make build-frontend  - Build the frontend production assets"
	@echo "  make docker-up       - Run all services using Docker Compose"
	@echo "  make docker-down     - Stop and clean up Docker Compose containers"
	@echo "================================================================"

# Install dependencies
install:
	@echo "Installing frontend dependencies..."
	cd react-frontend && npm install

# Run services locally
run-backend:
	@echo "Starting Rust backend..."
	cd backend && cargo run

frontend:
	@echo "Starting React Vite frontend..."
	cd react-frontend && npm run dev

# Build projects
build-backend:
	@echo "Building Rust backend in release mode..."
	cd backend && cargo build --release

build-frontend:
	@echo "Building React frontend..."
	cd react-frontend && npm run build

# Docker Orchestration
docker-up:
	@echo "Spinning up Docker containers..."
	docker-compose up --build

docker-down:
	@echo "Spinning down Docker containers..."
	docker-compose down
