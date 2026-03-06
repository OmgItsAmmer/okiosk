<p align="center">
  <img src="https://img.shields.io/badge/okiosk-E-Commerce_Kiosk-7C3AED?style=for-the-badge&logo=flutter&logoColor=white" alt="okiosk" />
</p>

<h1 align="center">🛒 okiosk</h1>
<p align="center">
  <strong>Modern E-Commerce & Kiosk Platform</strong> — Flutter + Rust Backend + Supabase
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Rust-Axum-DEA584?style=flat-square&logo=rust&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/React-61DAFB?style=flat-square&logo=react&logoColor=black" />
  <img src="https://img.shields.io/badge/GetX-8B5CF6?style=flat-square" />
  <img src="https://img.shields.io/badge/AI-Powered-10B981?style=flat-square&logo=openai&logoColor=white" />
</p>

---

## ✨ What is okiosk?

**okiosk** is a full-stack e-commerce and kiosk platform. It combines a **Flutter app** (mobile, web, desktop) and **React web kiosk** with a dedicated **Rust backend** (`kks_online_backend`) that powers products, cart, checkout, AI voice commands, and auth. The backend connects to **Supabase** (PostgreSQL) for data storage.

---

## 🏗️ Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Flutter App       │     │   React Frontend    │
│   (Mobile/Desktop)  │     │   (Web Kiosk)      │
└─────────┬───────────┘     └─────────┬───────────┘
          │                           │
          │    HTTP / WebSocket       │
          └─────────────┬─────────────┘
                        │
                        ▼
          ┌─────────────────────────┐
          │   kks_online_backend     │
          │   (Rust / Axum)          │
          │   • Products, Cart       │
          │   • Checkout, Auth       │
          │   • AI Commands          │
          │   • Whisper (STT)        │
          └─────────────┬─────────────┘
                        │
                        ▼
          ┌─────────────────────────┐
          │   Supabase (PostgreSQL)  │
          └─────────────────────────┘
```

---

## 🚀 Features

| Feature | Description |
|---------|-------------|
| 🤖 **AI Voice Commands** | Natural language commands via local LLM (add to cart, search, etc.) |
| 🎤 **Speech-to-Text** | Whisper.cpp for voice input and transcription |
| 🛍️ **Product Catalog** | Products, categories, brands, variations, search |
| 🛒 **Smart Cart** | Customer cart + kiosk session cart, stock validation |
| 💳 **Checkout** | Checkout API with race-condition handling |
| 🔐 **Auth** | Google OAuth, JWT, guest sessions, QR login |
| 📡 **WebSocket** | Real-time updates via Socket.IO |
| 📱 **Cross-Platform** | Flutter (iOS, Android, Web, Windows) + React web |
| ☁️ **Supabase** | PostgreSQL database used by the backend |

---

## 🛠️ Tech Stack

| Layer | Technologies |
|-------|--------------|
| **Backend** | Rust, Axum, SQLx, Socket.IO, Reqwest |
| **Database** | Supabase (PostgreSQL) |
| **AI** | Local LLM (chat completions), Whisper.cpp |
| **Auth** | Google OAuth, JWT, OAuth2 |
| **Flutter** | GetX, Lottie, Shimmer, Firebase Core |
| **React** | Vite, TypeScript, Axios |

---

## 📁 Project Structure

```
okiosk/
├── kks_online_backend/     # Rust backend (okiosk API)
│   ├── src/
│   │   ├── handlers/       # Products, cart, checkout, AI, auth, transcribe
│   │   ├── services/       # AI, auth, queue, command executor
│   │   ├── database/        # SQLx queries (products, cart, orders, etc.)
│   │   └── models/
│   └── Dockerfile
├── lib/                    # Flutter app
│   ├── features/           # Cart, checkout, products, POS, voice, etc.
│   ├── data/backend/       # API client, services, repositories
│   └── ...
├── react-frontend/         # React web kiosk (Vite + TS)
└── assets/
```

---

## 🏃 Getting Started

### 1. Backend (kks_online_backend)

```bash
cd kks_online_backend

# Create .env with DATABASE_URL, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET,
# GOOGLE_REDIRECT_URI, JWT_SECRET, LLM_API_URL, etc.

cargo run
# Server runs on http://localhost:3000
```

### 2. Flutter App

```bash
flutter pub get
flutter run
# Configure BackendConfig.baseUrl if backend is not on localhost:3000
```

### 3. React Frontend (optional, for web kiosk)

```bash
cd react-frontend
npm install
npm run dev
# Runs on http://localhost:5173
# Set VITE_BACKEND_URL to backend URL (default: http://localhost:3000)
```

---

## 📄 License

This project is available for use under the terms of its license.

---

<p align="center">
  <strong>Developed with ❤️ by</strong><br/>
  <a href="mailto:ammersaeed21@gmail.com"><b>Ammer Saeed</b></a><br/>
  <a href="mailto:ammersaeed21@gmail.com">ammersaeed21@gmail.com</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-7C3AED?style=flat-square" />
</p>
