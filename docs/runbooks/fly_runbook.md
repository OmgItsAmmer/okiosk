# fly.io Deployment Runbook — Okiosk Backend

This runbook covers deploying the **Rust Axum API** to [fly.io](https://fly.io). The React frontend stays on **Vercel**; only the backend runs on fly.io.

## Architecture

```
┌─────────────────┐     HTTPS      ┌──────────────────┐     SQL      ┌─────────────┐
│  Vercel         │ ──────────────▶│  fly.io          │ ────────────▶│  Supabase   │
│  react-frontend │   REST + WS    │  okiosk-api      │  DATABASE_URL│  PostgreSQL │
└─────────────────┘                └──────────────────┘              └─────────────┘
        │                                    │
        │  VITE_BACKEND_URL                  │  OpenAI, Google OAuth
        └────────────────────────────────────┘
```

| Component | Host | Config file |
| :--- | :--- | :--- |
| Backend API | fly.io | `backend/fly.toml` |
| Frontend | Vercel (unchanged) | `react-frontend/vercel.json` |
| Database | Supabase | `DATABASE_URL` secret on fly.io |

---

## Prerequisites

Before you start, confirm you have:

- [ ] A [fly.io account](https://fly.io/app/sign-up) with billing enabled (free tier is enough to start)
- [ ] [flyctl](https://fly.io/docs/hands-on/install-flyctl/) installed locally
- [ ] A Supabase project with the schema applied (`supabase/migrations/`)
- [ ] OpenAI API key
- [ ] Google OAuth credentials (Cloud Console → APIs & Services → Credentials)
- [ ] GitHub repo access (for automated deploys)

Install flyctl (if needed):

```bash
# macOS / Linux
curl -L https://fly.io/install.sh | sh

# Windows (PowerShell)
powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

Log in:

```bash
fly auth login
```

---

## One-time setup

### 1. Choose app name and region

The default app name in `backend/fly.toml` is **`okiosk-api`**, region **`sin`** (Singapore). Deploy commands pin `--regions sin` so machines are never spread to other regions (avoids extra billing).

Change the app name or region in `backend/fly.toml` if needed, and update `--regions` in `Makefile` / `.github/workflows/backend-deploy.yml` to match.

```toml
# backend/fly.toml
app = "okiosk-api"
primary_region = "sin"
```

List available regions:

```bash
fly platform regions
```

### 1b. Cost-optimized defaults (auto-sleep, single machine)

Production is configured for the **cheapest viable** fly.io setup:

| Setting | Value | Why |
| :--- | :--- | :--- |
| `primary_region` | `sin` | Singapore — closest to Supabase/Vercel users in APAC |
| `min_machines_running` | `0` | Machines **auto-sleep** when idle (no CPU/RAM charges while stopped) |
| `auto_stop_machines` | `"stop"` | Fully stop idle machines (cheaper than always-on) |
| `auto_start_machines` | `true` | Fly Proxy wakes the machine on the next HTTP request |
| VM | 512 MB, 1 shared CPU | Smallest practical size for the Rust runtime |
| Deploy | `--ha=false` | One machine only — no HA spare (default fly deploy creates two) |
| Regions | `--regions sin` | Single region — no duplicate machines elsewhere |

**Trade-off:** After idle sleep, the first request may take a few seconds (cold start) while the machine boots.

If the app already has more than one machine from an earlier deploy, scale down once:

```bash
fly scale count 1 --region sin -a okiosk-api
```

### 2. Create the fly.io app

From the repo root:

```bash
cd backend
fly apps create okiosk-api
```

If the name is taken, pick another and update `app` in `backend/fly.toml`.

Alternatively, let the first deploy create the app:

```bash
make fly-deploy
```

### 3. Set production secrets

Secrets are **not** read from `.env` on fly.io. The backend detects production via `APP_ENV=production` (set in `fly.toml`) and `FLY_APP_NAME` (injected automatically).

Required secrets:

| Secret | Description |
| :--- | :--- |
| `DATABASE_URL` | Supabase PostgreSQL connection string (Session pooler or direct) |
| `OPENAI_API_KEY` | OpenAI API key |
| `JWT_SECRET` | Long random string for signing JWTs |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |
| `GOOGLE_REDIRECT_URI` | Production OAuth callback (see below) |

Optional secrets:

| Secret | Default | Description |
| :--- | :--- | :--- |
| `OPENAI_MODEL` | `gpt-4o-mini` | LLM model name |
| `JWT_EXPIRATION` | `86400` | Token lifetime in seconds |

Set secrets (replace values):

```bash
cd backend

fly secrets set \
  DATABASE_URL="postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres" \
  OPENAI_API_KEY="sk-..." \
  JWT_SECRET="your-long-random-production-secret" \
  GOOGLE_CLIENT_ID="....apps.googleusercontent.com" \
  GOOGLE_CLIENT_SECRET="GOCSPX-..." \
  GOOGLE_REDIRECT_URI="https://okiosk-api.fly.dev/api/auth/google/callback"
```

Or use the Makefile hint:

```bash
make fly-secrets
```

**Supabase `DATABASE_URL` tips:**

- Use the **session pooler** URL (port `5432`, host `*.pooler.supabase.com`) — required for SQLx, which uses named prepared statements incompatible with the transaction pooler (port `6543`).
- Example: `postgresql://postgres.[ref]:[password]@aws-0-[region].pooler.supabase.com:5432/postgres`
- If your secret still uses port `6543`, the backend auto-rewrites it to `5432` at startup.
- Append `?connect_timeout=10` if connections hang at startup (also added automatically by the backend).
- Ensure Supabase allows connections from fly.io (default pooler is open; restrict by IP only if you use direct connections).

Verify secrets (names only, values are hidden):

```bash
fly secrets list
```

### 4. Configure Google OAuth for production

In [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

1. Open your OAuth 2.0 Client ID.
2. Add **Authorized redirect URI**:
   ```
   https://<your-fly-app>.fly.dev/api/auth/google/callback
   ```
   Example: `https://okiosk-api.fly.dev/api/auth/google/callback`
3. If the frontend uses a custom domain on Vercel, add that origin under **Authorized JavaScript origins** as needed.

Set `GOOGLE_REDIRECT_URI` on fly.io to the **exact same** callback URL.

### 5. Point Vercel at the fly.io API

In the Vercel project for `react-frontend`, set environment variables (Production):

| Variable | Example |
| :--- | :--- |
| `VITE_BACKEND_URL` | `https://okiosk-api.fly.dev` |
| `VITE_PUBLIC_URL` | `https://your-vercel-domain.vercel.app` (for kiosk QR codes; must be reachable from phones) |

Redeploy the Vercel frontend after changing env vars so Vite picks them up at build time.

---

## Deploy

### Option A — Makefile (manual)

From repo root:

```bash
# Optional: build image locally first
make backend-docker

# Deploy (remote build on fly.io)
make fly-deploy

# Verify health checks
make fly-checks
```

Equivalent commands:

```bash
cd backend
flyctl deploy --remote-only --ha=false --regions sin --config fly.toml --dockerfile Dockerfile
flyctl checks list --config fly.toml
```

### Option B — GitHub Actions (automated)

Pushes to **`main`** that touch `backend/**`, `Dockerfile`, or `backend/fly.toml` trigger `.github/workflows/backend-deploy.yml`.

**One-time GitHub setup:**

1. Create a fly.io deploy token:
   ```bash
   fly tokens create deploy -x 999999h
   ```
2. Add it to GitHub → **Settings → Secrets and variables → Actions** as `FLY_API_TOKEN`.
3. (Recommended) Create a **`production`** environment in GitHub for approval gates.

Manual trigger: **Actions → Backend Deploy (fly.io) → Run workflow**.

### What happens during deploy

1. fly.io builds `backend/Dockerfile` (multi-stage Rust compile → Debian slim).
2. A new machine starts with secrets injected as environment variables.
3. The app runs DB health check (`SELECT COUNT(*) FROM orders`) before serving traffic.
4. HTTP health check polls `GET /` every 15s (see `[checks.health]` in `fly.toml`).

---

## Post-deploy verification

### Health and logs

```bash
# App URL (after first deploy)
fly open -a okiosk-api

# Health checks
fly checks list -a okiosk-api

# Live logs
fly logs -a okiosk-api

# Machine status
fly status -a okiosk-api
```

### Smoke tests

Replace `https://okiosk-api.fly.dev` with your app URL:

```bash
# Root / health
curl https://okiosk-api.fly.dev/

# Popular products (requires DB + schema)
curl "https://okiosk-api.fly.dev/api/products/popular?limit=5"
```

Expected root response:

```
🚀 KKS Online Backend - E-commerce & Kiosk API
```

### End-to-end

1. Open the Vercel frontend with `VITE_BACKEND_URL` set to fly.io.
2. Log in with Google OAuth.
3. Send a chat command and confirm cart/checkout flows.

---

## Operations

### Scale

```bash
# Show current scale
fly scale show -a okiosk-api

# Ensure only one machine in Singapore (cheapest)
fly scale count 1 --region sin -a okiosk-api

# Add memory (if OOM at runtime after cold start)
fly scale memory 1024 -a okiosk-api
```

Default in `fly.toml`: **512 MB**, **1 shared CPU**, **`min_machines_running = 0`** (auto-sleep when idle). Deploy uses **`--ha=false`** so fly.io does not provision a second HA machine.

To keep one machine always running (faster response, higher cost):

```bash
# fly.toml: set min_machines_running = 1, then redeploy
make fly-deploy
```

### Update secrets

```bash
cd backend
fly secrets set OPENAI_API_KEY="sk-new-key"
```

Updating secrets triggers a rolling restart automatically.

### Rollback

```bash
fly releases list -a okiosk-api
fly deploy --image <previous-image-ref> -a okiosk-api
```

Or redeploy a known-good git tag locally:

```bash
git checkout v1.2.3
make fly-deploy
```

### SSH into a machine (debugging)

```bash
fly ssh console -a okiosk-api
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
| :--- | :--- | :--- |
| Deploy fails at build | Rust compile OOM | `fly scale memory 1024` before redeploy, or use `--remote-only` (default) |
| App crashes on startup: `DATABASE_URL must be set` | Missing secret | `fly secrets set DATABASE_URL=...` |
| `DB health check FAILED` | Wrong URL, firewall, or missing `orders` table | Verify Supabase URL; apply migrations |
| `OPENAI_API_KEY must be set` | Missing secret | `fly secrets set OPENAI_API_KEY=...` |
| OAuth redirect mismatch | `GOOGLE_REDIRECT_URI` ≠ Google Console URI | Align both to `https://<app>.fly.dev/api/auth/google/callback` |
| Frontend can't reach API | CORS or wrong `VITE_BACKEND_URL` | Set Vercel env to `https://<app>.fly.dev`; redeploy frontend |
| WebSocket auth fails on kiosk | `VITE_PUBLIC_URL` wrong | Set to a URL phones can open (not `localhost`) |
| Health check failing | App not listening on `0.0.0.0:3000` | Confirm `HOST`/`PORT` in `fly.toml` `[env]` |
| Slow first request after idle | Auto-sleep cold start | Expected with `min_machines_running = 0`; machine wakes on first request |
| Two machines billing | Default HA from earlier deploy | `fly scale count 1 --region sin -a okiosk-api` then deploy with `--ha=false` |
| CI deploy fails | Invalid/expired `FLY_API_TOKEN` | Regenerate token and update GitHub secret |

Useful debug commands:

```bash
fly logs -a okiosk-api
fly machine list -a okiosk-api
fly config validate -c backend/fly.toml
```

---

## Local parity before deploy

Run the same checks CI runs:

```bash
make backend-test-db-up
make backend-ci
make backend-test-db-down
```

Build the production Docker image locally:

```bash
make backend-docker
docker run --rm -p 3000:3000 --env-file backend/.env okiosk-backend:local
```

---

## Quick reference

| Task | Command |
| :--- | :--- |
| Deploy | `make fly-deploy` |
| Health checks | `make fly-checks` |
| View logs | `fly logs -a okiosk-api` |
| Set secrets | `fly secrets set KEY=value ...` |
| Open in browser | `fly open -a okiosk-api` |
| CI locally | `make backend-ci` |

**Config files:** `backend/fly.toml`, `backend/Dockerfile`, `.github/workflows/backend-deploy.yml`, `Makefile`

**Do not commit** `backend/.env` — use fly secrets for production and `.env.example` as a template for local dev.
