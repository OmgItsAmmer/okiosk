use crate::models::{AuthSession, User};
use chrono::{Duration, Utc};
use sqlx::{PgPool, Result};
use uuid::Uuid;

pub struct AuthQueries;

impl AuthQueries {
    /// Create or update a user from Google OAuth data
    pub async fn upsert_user(
        pool: &PgPool,
        google_id: &str,
        email: &str,
        name: &str,
        picture: Option<&str>,
    ) -> Result<User> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO oauth_users (google_id, email, name, picture, created_at, updated_at)
            VALUES ($1, $2, $3, $4, NOW(), NOW())
            ON CONFLICT (google_id) 
            DO UPDATE SET 
                email = EXCLUDED.email,
                name = EXCLUDED.name,
                picture = EXCLUDED.picture,
                updated_at = NOW()
            RETURNING *
            "#,
        )
        .bind(google_id)
        .bind(email)
        .bind(name)
        .bind(picture)
        .fetch_one(pool)
        .await?;

        Ok(user)
    }

    /// Create a new authentication session
    pub async fn create_session(pool: &PgPool, session_id: &str) -> Result<AuthSession> {
        let expires_at = Utc::now() + Duration::minutes(10);

        let session = sqlx::query_as::<_, AuthSession>(
            r#"
            INSERT INTO auth_sessions (session_id, status, created_at, expires_at)
            VALUES ($1, 'pending', NOW(), $2)
            RETURNING *
            "#,
        )
        .bind(session_id)
        .bind(expires_at)
        .fetch_one(pool)
        .await?;

        Ok(session)
    }

    /// Get session by ID
    pub async fn get_session(pool: &PgPool, session_id: &str) -> Result<Option<AuthSession>> {
        let session = sqlx::query_as::<_, AuthSession>(
            r#"
            SELECT * FROM auth_sessions
            WHERE session_id = $1
            "#,
        )
        .bind(session_id)
        .fetch_optional(pool)
        .await?;

        Ok(session)
    }

    /// Update session with user_id and mark as authenticated
    pub async fn complete_session(
        pool: &PgPool,
        session_id: &str,
        user_id: Uuid,
    ) -> Result<AuthSession> {
        let session = sqlx::query_as::<_, AuthSession>(
            r#"
            UPDATE auth_sessions
            SET user_id = $2, status = 'authenticated'
            WHERE session_id = $1
            RETURNING *
            "#,
        )
        .bind(session_id)
        .bind(user_id)
        .fetch_one(pool)
        .await?;

        Ok(session)
    }

    /// Mark session as expired
    pub async fn expire_session(pool: &PgPool, session_id: &str) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE auth_sessions
            SET status = 'expired'
            WHERE session_id = $1
            "#,
        )
        .bind(session_id)
        .execute(pool)
        .await?;

        Ok(())
    }

    /// Get user by ID
    pub async fn get_user_by_id(pool: &PgPool, user_id: Uuid) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM oauth_users
            WHERE id = $1
            "#,
        )
        .bind(user_id)
        .fetch_optional(pool)
        .await?;

        Ok(user)
    }

    /// Get user by Google ID
    pub async fn get_user_by_google_id(pool: &PgPool, google_id: &str) -> Result<Option<User>> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM oauth_users
            WHERE google_id = $1
            "#,
        )
        .bind(google_id)
        .fetch_optional(pool)
        .await?;

        Ok(user)
    }

    /// Clean up expired sessions (should be run periodically)
    pub async fn cleanup_expired_sessions(pool: &PgPool) -> Result<u64> {
        let result = sqlx::query(
            r#"
            DELETE FROM auth_sessions
            WHERE expires_at < NOW() OR (status = 'pending' AND created_at < NOW() - INTERVAL '1 hour')
            "#,
        )
        .execute(pool)
        .await?;

        Ok(result.rows_affected())
    }
}
