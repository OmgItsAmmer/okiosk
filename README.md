# 🌐 Okiosk — Next-Gen Intelligent Self-Service Kiosk

<p align="center">
  <img src="react-frontend/public/kks_new_logo_dark.png" alt="Okiosk Logo" width="180px" style="border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);"/>
</p>

<p align="center">
  <a href="#-architecture"><img src="https://img.shields.io/badge/Architecture-Clean_Rust_%2B_React-E63946?style=for-the-badge" alt="Architecture"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Backend-Rust_Axum-000000?style=for-the-badge&logo=rust" alt="Backend"/></a>
  <a href="#-tech-stack"><img src="https://img.shields.io/badge/Frontend-React_TypeScript-61DAFB?style=for-the-badge&logo=react" alt="Frontend"/></a>
  <a href="#-ai-orchestration"><img src="https://img.shields.io/badge/AI_Engine-Gemini_Cloud-0F9D58?style=for-the-badge&logo=google-gemini" alt="AI Engine"/></a>
</p>

---

**Okiosk** is a next-generation intelligent self-service kiosk system designed to automate ordering workflows with conversational AI. By combining a lightning-fast Rust backend with a modular React frontend, Okiosk processes voice and text commands in **Roman Urdu**, **Urdu**, and **English**, transforming natural speech into structured transactional cart operations.

> [!NOTE]
> This branch has been optimized to exclude legacy Flutter implementations and local LLM configurations. It utilizes **Gemini Cloud LLM** for natural language understanding and **React / Vite** for the frontend interfaces.

---

## ✨ Core Features

*   🗣️ **Multilingual AI Voice Assistant** — Real-time speech-to-text processing paired with dual Roman Urdu & English natural language understanding.
*   🤖 **Gemini Cloud LLM Parser** — Parses mixed-language instructions (e.g., *"2 zinger burger and 1 coke add karo aur bill bana do"*) directly into validated JSON action streams.
*   ⚡ **Sequential Queue Orchestration** — When multiple menu items require variant selection (e.g., size, attributes), the backend queues actions and guides the user sequentially, product-by-product.
*   🔐 **Secure Checkout System** — Optimistic inventory locking, server-side validation against tampering, and SHA-256 idempotency checks to avoid double-processing.
*   📱 **Real-Time WebSocket Sync** — Instant device pairing via QR code to complete Google OAuth authentication on a mobile browser and sync state back to the kiosk.

---

## 🏗️ System Architecture

The following diagram illustrates how the frontend components, the backend API layers, and the database/AI integration interact:

```mermaid
graph TD
    %% Define Styles
    classDef client fill:#1f2937,stroke:#3b82f6,stroke-width:2px,color:#fff;
    classDef api fill:#1f2937,stroke:#ec4899,stroke-width:2px,color:#fff;
    classDef data fill:#1f2937,stroke:#10b981,stroke-width:2px,color:#fff;
    classDef cloud fill:#1f2937,stroke:#eab308,stroke-width:2px,color:#fff;

    %% Nodes
    A[React Kiosk Frontend]:::client
    B[Mobile Auth Browser]:::client
    
    C{Axum API Gateway}:::api
    D[Socket.io Hub]:::api
    E[Command Executor]:::api
    F[In-Memory Queue Service]:::api
    
    G[(Postgres Database)]:::data
    H[Gemini Cloud API]:::cloud
    I[Google OAuth Server]:::cloud

    %% Relationships
    A -- REST HTTP requests --> C
    A -- WebSocket Sync --> D
    B -- Google Auth Callback --> C
    
    C -- Routes Command --> E
    E -- Checks State / Pop next --> F
    E -- Contextual Prompting --> H
    C -- OAuth Exchange --> I
    
    C -- Queries & Transactions --> G
    E -- Optimistic Locking --> G
```

---

## 🛠️ Tech Stack

### Backend (Rust)
*   **Web Framework:** [Axum](https://github.com/tokio-rs/axum) for concurrent, high-performance routing.
*   **Async Runtime:** [Tokio](https://github.com/tokio-rs/tokio) for non-blocking I/O.
*   **Database Client:** [SQLx](https://github.com/launchbadge/sqlx) with compiler-checked SQL queries using Rustls TLS.
*   **Real-time Layer:** [Socketioxide](https://github.com/Totodore/socketioxide) for high-frequency WebSocket messaging.

### Frontend (React)
*   **Core Framework:** [React 19](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/) + [Vite](https://vite.dev/).
*   **Animations:** [Framer Motion](https://www.framer.com/motion/) for fluid transitions.
*   **State & Sync:** [Socket.io Client](https://socket.io/docs/v4/client-api/) for live updates.

---

## 📂 Repository Directory Structure

```
okiosk/
├── backend/                  # Rust Axum Web API Crate
│   ├── src/
│   │   ├── config/           # Environment config parsing
│   │   ├── database/         # SQLx query abstraction (cart, products, checkout)
│   │   ├── handlers/         # HTTP Axum handlers (AI, cart, auth)
│   │   ├── models/           # Shared serializable models
│   │   ├── routes/           # Routing layers
│   │   ├── services/         # Business logic (Gemini API, Queue Service)
│   │   └── main.rs           # Server Entrypoint
│   └── Cargo.toml
├── react-frontend/           # React + TS Kiosk Application
│   ├── src/
│   │   ├── components/       # Reusable UI widgets
│   │   ├── context/          # Auth & Socket state providers
│   │   ├── pages/            # Menu, Assistant, Checkout, Login pages
│   │   ├── App.tsx           # Route definitions
│   │   └── main.tsx          # Frontend entrypoint
│   └── package.json
├── supabase/                 # Supabase configuration files
├── Dockerfile                # Root build blueprint
└── docker-compose.yml        # Orchestration script for database, backend & frontend
```

---

## ⚙️ Configuration & Setup

### Environment Variables (.env)

Configure a `.env` file in the `./backend/` directory with the following variables:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/okiosk` |
| `PORT` | Local port for Rust server | `3000` |
| `GEMINI_API_KEY` | Key to access Gemini model APIs | `AIzaSyD...` |
| `GEMINI_MODEL` | Cloud Model selection | `gemini-2.5-flash` |
| `GOOGLE_CLIENT_ID` | Client ID for Google Authentication | `your-id.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Client Secret for Google OAuth | `GOCSPX-your-secret` |
| `GOOGLE_REDIRECT_URI` | Auth callback endpoint | `http://localhost:3000/api/auth/google/callback` |
| `JWT_SECRET` | Secret token to sign user logins | `supersecretkey` |

---

## 🚀 Running the Project

### Running Locally

Ensure PostgreSQL is running and you have initialized the schema.

#### 1. Launch the Backend
```bash
cd backend
cargo run
```
The backend starts on `http://localhost:3000`.

#### 2. Launch the Frontend
```bash
cd react-frontend
npm install
npm run dev
```
The client dashboard opens on `http://localhost:5173`.

---

### Running with Docker

To build and run all services (PostgreSQL Database, Axum Backend, and React Frontend) together:

```bash
docker-compose up --build
```

---

## 💡 Conversational Workflow

> [!TIP]
> Try calling the AI endpoint using Roman Urdu! The engine understands verbs like *add*, *remove*, *bana do*, *nikal do*, and *show*.

```bash
# Add items and request checkout in one instruction
curl -X POST http://localhost:3000/api/ai/command \
     -H "Content-Type: application/json" \
     -d '{"prompt": "add 2 chicken zinger burger and checkout kar do", "session_id": "test_session"}'
```

---

## 🤝 Verification & Status Checks

You can check system components using our built-in test routes:
*   **System Status:** `GET http://localhost:3000/`
*   **Database Connectivity:** `GET http://localhost:3000/test-db`
*   **Popular Menu Products:** `GET http://localhost:3000/api/products/popular`
