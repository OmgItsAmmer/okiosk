-- Migration: Add authentication tables for Google OAuth QR code login
-- Created: 2026-01-29
-- Note: Creates separate oauth_users table to avoid conflicts with existing users table

-- Create oauth_users table for Google authenticated users
CREATE TABLE IF NOT EXISTS oauth_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    google_id VARCHAR UNIQUE NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR NOT NULL,
    picture VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create auth_sessions table for QR code login flow
CREATE TABLE IF NOT EXISTS auth_sessions (
    session_id VARCHAR PRIMARY KEY,
    user_id UUID REFERENCES oauth_users(id),
    status VARCHAR NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() + INTERVAL '10 minutes' NOT NULL
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_oauth_users_google_id ON oauth_users(google_id);
CREATE INDEX IF NOT EXISTS idx_oauth_users_email ON oauth_users(email);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_status ON auth_sessions(status);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expires_at ON auth_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user_id ON auth_sessions(user_id);

-- Add comments for documentation
COMMENT ON TABLE oauth_users IS 'Stores Google OAuth authenticated users for kiosk login';
COMMENT ON TABLE auth_sessions IS 'Stores temporary authentication sessions for QR code login flow';
COMMENT ON COLUMN oauth_users.google_id IS 'Google OAuth user ID (unique identifier from Google)';
COMMENT ON COLUMN oauth_users.picture IS 'Google profile picture URL';
COMMENT ON COLUMN auth_sessions.status IS 'Session status: pending, authenticated, or expired';

