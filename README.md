# Okiosk — Agentic Ordering

<p align="center">
  <img src="react-frontend/public/kks_new_logo_dark.png" alt="Okiosk Logo" width="180px" style="border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);"/>
</p>

<p align="center">
  <a href="#-what-it-is"><img src="https://img.shields.io/badge/Architecture-Rust_%2B_React-E63946?style=for-the-badge" alt="Architecture"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Backend-Rust_Axum-000000?style=for-the-badge&logo=rust" alt="Backend"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Frontend-React_TypeScript-61DAFB?style=for-the-badge&logo=react" alt="Frontend"/></a>
  <a href="#-core-features"><img src="https://img.shields.io/badge/AI-OpenAI_GPT--4o_mini-412991?style=for-the-badge&logo=openai" alt="AI"/></a>
</p>

---

## What It Is

**Okiosk** is one ordering product — one React app, one Rust API. Customers chat in **Roman Urdu**, **Urdu**, or **English**; the backend turns that text into cart and checkout operations.

**What “agentic” means here:** the LLM does not run the store. It parses intent into a fixed set of typed actions (`add_to_cart`, `view_cart`, `checkout`, …). A Rust `CommandExecutor` runs those actions against PostgreSQL — including stock checks, cart writes, and checkout with inventory reservation. That split (probabilistic parse, deterministic execute) is the core design.

It runs in two contexts without separate codebases:

| Context | Who uses it | What happens |
| :--- | :--- | :--- |
| **Web** | Customer at home or on their phone | Browse and order through the chatbot like any e-commerce site. |
| **Kiosk** | Customer at a shared screen in a restaurant | Same chatbot on a fixed display; QR login on their phone keeps the line moving. |

For kiosk use, the display creates a `session_id`, renders it as a QR code, and joins a Socket.io room. The customer scans, completes Google OAuth on their phone (`state=session_id`), and the backend emits `auth-success` to that room so the shared screen can proceed without typing on the kiosk.

Production is containerized (root `Dockerfile`) and deployed on **[fly.io](https://fly.io)**.

---

## Core Features

* **Chat-driven ordering** — Add, remove, view cart, search menu, and checkout via natural language (`POST /api/ai/command`).
* **Structured LLM output** — [GPT-4o mini](https://platform.openai.com/docs/models/gpt-4o-mini) returns JSON matching a Rust `Action` enum; invalid or empty parses fail closed with a user-facing error.
* **Sequential variant queue** — Multi-item orders with ambiguous variants are serialized: the first product is returned immediately, the rest sit in an in-memory `QueueService` until the client confirms each via `POST /api/ai/variant-confirm`.
* **Checkout safety** — Inventory reservation before order commit, server-side cart validation, and SHA-256 idempotency keys to block duplicate orders.
* **Dual cart model** — Authenticated users use `/api/cart/:customer_id`; kiosk/guest flows use `/api/cart/kiosk/:session_id` keyed by session.
* **QR auth handoff** — Kiosk display ↔ phone OAuth over Google + Socket.io (`join-session` → `auth-success`).

---

## How a Command Runs

```
User message
    → OpenAI (system prompt → JSON actions[])
    → CommandExecutor (per-action DB work: search product, resolve variant, mutate cart, checkout)
    → [if variants pending] in-memory queue + variant-confirm loop
    → OpenAI (optional confirmation message in user's language)
    → JSON response to React chat UI
```

| Step | Endpoint / component | Responsibility |
| :--- | :--- | :--- |
| 1 | `POST /api/ai/command` | Parse prompt; execute immediate actions |
| 2 | `CommandExecutor` | Map each `Action` to SQLx queries (products, cart, orders) |
| 3 | `QueueService` | Hold remaining variant picks per `{session_id}_{customer_id}` |
| 4 | `POST /api/ai/variant-confirm` | Advance queue after user picks a variant |
| 5 | `POST /api/checkout` | Reserve stock, write order, idempotency check |

The queue is an in-process `HashMap` (5-minute TTL), not Redis — fine for single-instance kiosk deploys; swap for shared state if you scale horizontally.

---

## System Architecture

```mermaid
graph TD
    classDef client fill:#1f2937,stroke:#3b82f6,stroke-width:2px,color:#fff;
    classDef api fill:#1f2937,stroke:#ec4899,stroke-width:2px,color:#fff;
    classDef data fill:#1f2937,stroke:#10b981,stroke-width:2px,color:#fff;
    classDef cloud fill:#1f2937,stroke:#eab308,stroke-width:2px,color:#fff;

    A[React App — web or kiosk display]:::client
    B[Mobile Auth Browser]:::client

    C{Axum API Gateway}:::api
    D[Socket.io Hub]:::api
    E[Command Executor]:::api
    F[In-Memory Queue Service]:::api

    G[(Postgres / Supabase)]:::data
    H[OpenAI API]:::cloud
    I[Google OAuth]:::cloud

    A -- REST --> C
    A -- WebSocket --> D
    B -- OAuth callback --> C

    C -- Routes command --> E
    E -- State / queue --> F
    E -- JSON action parse --> H
    C -- Token exchange --> I

    C -- Queries & transactions --> G
    E -- Cart / checkout --> G
```

Axum mounts separate routers for products, cart (customer + kiosk), auth, AI, and checkout. Socket.io shares the same process for auth events only (`join-session`, `auth-success`, `auth-error`).

---

## Tech Stack

### Backend (Rust)
* **Web framework:** [Axum](https://github.com/tokio-rs/axum)
* **Async runtime:** [Tokio](https://github.com/tokio-rs/tokio)
* **Database:** [SQLx](https://github.com/launchbadge/sqlx) + PostgreSQL (Supabase)
* **Real-time:** [Socketioxide](https://github.com/Totodore/socketioxide)
* **AI:** OpenAI Chat Completions API (`gpt-4o-mini` by default)

### Frontend (React)
* **Core:** [React 19](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/) + [Vite](https://vite.dev/)
* **UI motion:** [Framer Motion](https://www.framer.com/motion/)
* **Live updates:** [Socket.io Client](https://socket.io/docs/v4/client-api/)

### Infrastructure
* **Hosting:** [fly.io](https://fly.io) (Docker image from root `Dockerfile`)
* **Database:** Supabase (PostgreSQL via `DATABASE_URL`)
* **Testing:** Rust unit tests (`cargo test`); API integration via Postman collections in `backend/tests/postman/`

---

## Repository Layout

```
okiosk/
├── backend/                  # Rust Axum API
│   ├── src/
│   │   ├── config/           # Environment config
│   │   ├── database/         # SQLx queries (cart, products, checkout)
│   │   ├── handlers/         # HTTP handlers (AI, cart, auth)
│   │   ├── models/           # Shared serializable models
│   │   ├── routes/           # Route definitions
│   │   ├── services/         # AI, queue, and business logic
│   │   └── main.rs
│   └── tests/postman/        # Integration test collections
├── react-frontend/           # React + TypeScript web app
│   ├── src/
│   │   ├── components/
│   │   ├── context/          # Auth & cart providers
│   │   ├── pages/            # Login, OrderAssistant, Menu, Checkout
│   │   └── services/         # API clients
│   └── package.json
├── supabase/                 # Migrations and Supabase config
├── Dockerfile
└── docker-compose.yml
```

---

## Configuration

Create a `.env` file in `./backend/`:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/okiosk` |
| `PORT` | Backend listen port | `3000` |
| `OPENAI_API_KEY` | OpenAI API key | `sk-...` |
| `OPENAI_MODEL` | Model for NLU and confirmations | `gpt-4o-mini` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | `your-id.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | `GOCSPX-...` |
| `GOOGLE_REDIRECT_URI` | OAuth callback URL | `http://localhost:3000/api/auth/google/callback` |
| `JWT_SECRET` | Secret for signing session tokens | `supersecretkey` |

---

## Running Locally

Ensure PostgreSQL is running and the schema is applied.

### Backend
```bash
cd backend
cargo run
```
Server: `http://localhost:3000`

### Frontend
```bash
cd react-frontend
npm install
npm run dev
```
App: `http://localhost:5173`

### Docker
```bash
docker-compose up --build
```

---

## Chatbot Workflow

```bash
curl -X POST http://localhost:3000/api/ai/command \
     -H "Content-Type: application/json" \
     -d '{"prompt": "add 2 chicken zinger burger and checkout kar do", "session_id": "test_session", "customer_id": null}'
```

The model maps Urdu/English phrasing (*add*, *karo*, *bana do*, *dikha do*) to actions defined in the system prompt. If a product has multiple variants and none was specified, the response includes a `variant_selection` payload instead of adding to cart immediately — the UI then calls `/api/ai/variant-confirm` to drain the queue.

---

## Testing

| Layer | What runs | Command / location |
| :--- | :--- | :--- |
| **Unit** | Queue service, handler logic | `cd backend && cargo test` |
| **Integration** | Product/cart HTTP contracts | Import `backend/tests/postman/KKS_Products_API.postman_collection.json` |
| **Manual E2E** | React + backend locally | `docker-compose up` or split `cargo run` + `npm run dev` |

Health checks:
* **Status:** `GET http://localhost:3000/`
* **Database:** `GET http://localhost:3000/test-db`
* **Popular products:** `GET http://localhost:3000/api/products/popular`

---

## Deployment

Build the backend image from the root `Dockerfile` (multi-stage Rust compile → Debian slim). Deploy to **fly.io** with env vars from the Configuration table (`OPENAI_API_KEY`, `DATABASE_URL`, Google OAuth, `JWT_SECRET`).
