# QR Code Google Sign-In - Quick Start Guide

## Overview
This implementation provides a QR code-based Google Sign-In authentication system where users scan a QR code on the kiosk screen with their mobile device and authenticate via Google OAuth.

## Prerequisites

1. **Google OAuth Credentials** - Follow the [Google OAuth Setup Guide](./GOOGLE_OAUTH_SETUP.md) to obtain:
   - Google Client ID
   - Google Client Secret

2. **Database Setup** - Run the SQL migration to create required tables

## Setup Instructions

### 1. Database Migration

Run the SQL migration to create the `users` and `auth_sessions` tables:

```bash
# Option 1: Using psql (if you have direct database access)
psql $DATABASE_URL < kks_online_backend/migrations/auth_tables.sql

# Option 2: Using Supabase SQL Editor
# Copy the contents of kks_online_backend/migrations/auth_tables.sql
# and run it in the Supabase SQL Editor
```

### 2. Configure Backend Environment

Edit `kks_online_backend/.env` and add your Google OAuth credentials:

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/google/callback

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRATION=86400
```

### 3. Install Backend Dependencies

```bash
cd kks_online_backend
cargo build
```

### 4. Start the Backend Server

```bash
cd kks_online_backend
cargo run
```

The server will start on `http://localhost:3000`

### 5. Start the Frontend

```bash
cd react-frontend
npm run dev
```

The frontend will start on `http://localhost:5173` (or the port Vite assigns)

## How It Works

### Authentication Flow

1. **Kiosk displays QR code**
   - Frontend generates a unique session ID
   - QR code contains URL: `http://localhost:3000/api/auth/google?session_id=<uuid>`
   - WebSocket connection established to listen for auth events

2. **User scans QR code on mobile**
   - Mobile browser opens the URL
   - Backend redirects to Google OAuth consent screen

3. **User authenticates with Google**
   - User approves the OAuth consent
   - Google redirects back to backend callback URL

4. **Backend processes authentication**
   - Exchanges authorization code for access token
   - Fetches user info from Google
   - Creates/updates user in database
   - Generates JWT token
   - Emits `auth-success` event via WebSocket to the kiosk

5. **Kiosk receives authentication**
   - Frontend receives WebSocket event
   - Stores JWT token and user data in localStorage
   - Navigates to dashboard

## API Endpoints

### Authentication Endpoints

- `GET /api/auth/google?session_id=<id>` - Initiate Google OAuth flow
- `GET /api/auth/google/callback` - Handle Google OAuth callback
- `POST /api/auth/verify` - Verify JWT token

### WebSocket Events

- **Client → Server**
  - `join-session` - Join a session room to receive auth events

- **Server → Client**
  - `auth-success` - Authentication successful (includes token and user data)
  - `auth-error` - Authentication failed (includes error message)

## Testing

1. Open the frontend in your browser: `http://localhost:5173`
2. You should see the login page with a QR code
3. Scan the QR code with your mobile device
4. Authenticate with your Google account
5. The kiosk should automatically log you in and navigate to the dashboard

## Troubleshooting

### QR Code Not Displaying
- Check browser console for errors
- Verify `VITE_BACKEND_URL` in `react-frontend/.env`

### Google OAuth Errors
- See [Google OAuth Setup Guide](./GOOGLE_OAUTH_SETUP.md) troubleshooting section
- Verify redirect URI matches exactly in Google Cloud Console and `.env`

### WebSocket Connection Issues
- Check that backend is running on the correct port
- Verify CORS is properly configured
- Check browser console for WebSocket connection errors

### Database Errors
- Ensure migrations have been run
- Verify `DATABASE_URL` is correct in backend `.env`
- Check Supabase connection

## Security Notes

- **JWT Secret**: Change `JWT_SECRET` to a strong random value in production
- **HTTPS**: Use HTTPS in production for both frontend and backend
- **Redirect URI**: Update `GOOGLE_REDIRECT_URI` to your production domain
- **CORS**: Configure CORS to only allow your frontend domain in production

## File Structure

```
react-frontend/
├── src/
│   ├── pages/
│   │   ├── Login.tsx          # QR code login page
│   │   ├── Login.css
│   │   ├── Dashboard.tsx      # Post-login dashboard
│   │   └── Dashboard.css
│   ├── context/
│   │   └── AuthContext.tsx    # Auth state management
│   ├── hooks/
│   │   └── useAuth.ts         # Auth hook
│   ├── types/
│   │   └── auth.ts            # TypeScript types
│   └── App.tsx                # Main app with routing

kks_online_backend/
├── src/
│   ├── models/
│   │   └── auth.rs            # Auth data models
│   ├── database/
│   │   └── auth_queries.rs    # Database queries
│   ├── services/
│   │   └── auth_service.rs    # OAuth & JWT logic
│   ├── handlers/
│   │   └── auth_handlers.rs   # HTTP handlers
│   └── main.rs                # Server setup
└── migrations/
    └── auth_tables.sql        # Database schema
```
