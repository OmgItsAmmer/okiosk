//! Shared helpers for integration tests.

pub fn set_test_env() {
    std::env::set_var("OPENAI_API_KEY", "sk-test-ci-key");
    std::env::set_var("OPENAI_MODEL", "gpt-4o-mini");
    std::env::set_var(
        "DATABASE_URL",
        "postgresql://postgres:postgres@localhost:5432/okiosk_test",
    );
    std::env::set_var("JWT_SECRET", "test-jwt-secret-for-ci-only-min-32-chars");
    std::env::set_var(
        "GOOGLE_CLIENT_ID",
        "test-client-id.apps.googleusercontent.com",
    );
    std::env::set_var("GOOGLE_CLIENT_SECRET", "test-client-secret");
    std::env::set_var(
        "GOOGLE_REDIRECT_URI",
        "http://localhost:3000/api/auth/google/callback",
    );
    std::env::set_var("APP_ENV", "test");
}
