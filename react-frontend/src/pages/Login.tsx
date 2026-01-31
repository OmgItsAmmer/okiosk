import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import QRCode from 'qrcode';
import { useAuth } from '../hooks/useAuth';
import { AuthState } from '../types/auth';
import { colors } from '../constants/colors';
import './Login.css';

const Login = () => {
    const navigate = useNavigate();
    const {
        authState,
        qrSession,
        initiateLogin,
        loginAsGuest,
        cancelLogin,
        isAuthenticated
    } = useAuth();

    const [qrCodeUrl, setQrCodeUrl] = useState<string>('');
    const [isGeneratingQR, setIsGeneratingQR] = useState(false);
    const [error, setError] = useState<string>('');
    const [isDarkMode, setIsDarkMode] = useState(false);
    const [timeRemaining, setTimeRemaining] = useState<number>(0);
    const [isGuestLoading, setIsGuestLoading] = useState(false);

    // Redirect if already authenticated
    useEffect(() => {
        if (isAuthenticated) {
            navigate('/order');
        }
    }, [isAuthenticated, navigate]);

    // Generate QR code when session is available
    useEffect(() => {
        if (!qrSession) {
            setQrCodeUrl('');
            return;
        }

        setIsGeneratingQR(true);
        QRCode.toDataURL(qrSession.qrUrl, {
            width: 250,
            margin: 2,
            color: {
                dark: isDarkMode ? colors.dark.text : colors.light.text,
                light: isDarkMode ? colors.dark.secondary : colors.light.secondary,
            },
        })
            .then((url) => {
                setQrCodeUrl(url);
                setIsGeneratingQR(false);
            })
            .catch((err) => {
                console.error('Error generating QR code:', err);
                setError('Failed to generate QR code');
                setIsGeneratingQR(false);
            });
    }, [qrSession, isDarkMode]);

    // Countdown timer for QR session
    useEffect(() => {
        if (!qrSession) {
            setTimeRemaining(0);
            return;
        }

        const updateTimer = () => {
            const remaining = Math.max(0, qrSession.expiresAt.getTime() - Date.now());
            setTimeRemaining(Math.ceil(remaining / 1000));
        };

        updateTimer();
        const interval = setInterval(updateTimer, 1000);

        return () => clearInterval(interval);
    }, [qrSession]);

    // Handle login button click
    const handleLoginClick = useCallback(async () => {
        setError('');
        try {
            await initiateLogin();
        } catch (err) {
            setError('Failed to start login session');
        }
    }, [initiateLogin]);

    // Handle guest login
    const handleGuestLogin = useCallback(async () => {
        setError('');
        setIsGuestLoading(true);
        try {
            await loginAsGuest();
            navigate('/order');
        } catch (err) {
            setError('Failed to create guest session');
        } finally {
            setIsGuestLoading(false);
        }
    }, [loginAsGuest, navigate]);

    // Handle cancel
    const handleCancel = useCallback(() => {
        cancelLogin();
        setQrCodeUrl('');
        setError('');
    }, [cancelLogin]);

    // Toggle theme
    const toggleTheme = () => {
        setIsDarkMode(!isDarkMode);
    };

    const theme = isDarkMode ? colors.dark : colors.light;

    // Format time remaining
    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    };

    // Render based on auth state
    const renderContent = () => {
        // Initial state - show login buttons
        if (authState === AuthState.INITIAL) {
            return (
                <div className="login-buttons-container">
                    <h2 className="login-title" style={{ color: theme.text }}>
                        Welcome to OKiosk
                    </h2>
                    <p className="login-subtitle" style={{ color: theme.text, opacity: 0.7 }}>
                        Sign in to access all features
                    </p>

                    <button
                        className="login-button primary-button"
                        onClick={handleLoginClick}
                        style={{
                            background: theme.primary,
                            color: '#FFFFFF',
                        }}
                    >
                        <span className="button-icon">🔐</span>
                        Login with Google
                    </button>

                    <div className="divider">
                        <span style={{ background: theme.secondary, color: theme.text }}>or</span>
                    </div>

                    <button
                        className="login-button guest-button"
                        onClick={handleGuestLogin}
                        disabled={isGuestLoading}
                        style={{
                            background: 'transparent',
                            color: theme.text,
                            border: `2px solid ${theme.text}`,
                        }}
                    >
                        {isGuestLoading ? (
                            <span className="button-loading">Loading...</span>
                        ) : (
                            <>
                                <span className="button-icon">👤</span>
                                Continue as Guest
                            </>
                        )}
                    </button>

                    {error && (
                        <div className="error-message" style={{ color: theme.primary }}>
                            {error}
                        </div>
                    )}
                </div>
            );
        }

        // QR Generated state - show QR code
        if (authState === AuthState.QR_GENERATED || authState === AuthState.PENDING) {
            return (
                <div className="qr-content">
                    <h2 className="qr-title" style={{ color: theme.text }}>
                        Scan to Login
                    </h2>
                    <p className="qr-subtitle" style={{ color: theme.text, opacity: 0.7 }}>
                        Use your mobile device to scan the QR code
                    </p>

                    {isGeneratingQR ? (
                        <div className="qr-loading">
                            <div
                                className="spinner"
                                style={{
                                    borderColor: `${theme.primary}33`,
                                    borderTopColor: theme.primary,
                                }}
                            ></div>
                            <p style={{ color: theme.text, opacity: 0.7 }}>Generating QR Code...</p>
                        </div>
                    ) : error ? (
                        <div className="qr-error">
                            <div className="error-icon" style={{ color: theme.primary }}>⚠️</div>
                            <p style={{ color: theme.primary }}>{error}</p>
                            <button
                                className="retry-button"
                                onClick={handleLoginClick}
                                style={{
                                    background: theme.primary,
                                    color: '#FFFFFF',
                                }}
                            >
                                Retry
                            </button>
                        </div>
                    ) : (
                        <div className="qr-code-wrapper">
                            <div
                                className="qr-code-container"
                                style={{
                                    background: isDarkMode ? colors.dark.secondary : colors.light.secondary,
                                    boxShadow: isDarkMode
                                        ? '0 10px 40px rgba(0, 0, 0, 0.5)'
                                        : '0 10px 40px rgba(0, 0, 0, 0.1)',
                                }}
                            >
                                <img
                                    src={qrCodeUrl}
                                    alt="QR Code for login"
                                    className="qr-code-image"
                                />
                            </div>

                            {/* Timer */}
                            <div className="qr-timer" style={{ color: timeRemaining < 60 ? theme.primary : theme.text }}>
                                <span className="timer-icon">⏱️</span>
                                <span>Expires in {formatTime(timeRemaining)}</span>
                            </div>

                            <div className="qr-instructions">
                                <div className="instruction-step">
                                    <span
                                        className="step-number"
                                        style={{
                                            background: theme.primary,
                                            color: '#FFFFFF',
                                        }}
                                    >
                                        1
                                    </span>
                                    <span style={{ color: theme.text }}>Open camera on your phone</span>
                                </div>
                                <div className="instruction-step">
                                    <span
                                        className="step-number"
                                        style={{
                                            background: theme.accentOrange,
                                            color: '#FFFFFF',
                                        }}
                                    >
                                        2
                                    </span>
                                    <span style={{ color: theme.text }}>Scan the QR code</span>
                                </div>
                                <div className="instruction-step">
                                    <span
                                        className="step-number"
                                        style={{
                                            background: theme.accentYellow,
                                            color: '#FFFFFF',
                                        }}
                                    >
                                        3
                                    </span>
                                    <span style={{ color: theme.text }}>Sign in with Google</span>
                                </div>
                            </div>

                            {/* Cancel button */}
                            <button
                                className="cancel-button"
                                onClick={handleCancel}
                                style={{
                                    color: theme.text,
                                    opacity: 0.7,
                                }}
                            >
                                ← Back to options
                            </button>
                        </div>
                    )}

                    <div className="qr-footer">
                        <p style={{ color: theme.text, opacity: 0.6 }}>
                            {authState === AuthState.PENDING
                                ? 'Processing authentication...'
                                : 'Waiting for authentication...'}
                        </p>
                        <div className="pulse-indicator">
                            <span
                                className="pulse-dot"
                                style={{
                                    background: theme.primary,
                                }}
                            ></span>
                        </div>
                    </div>
                </div>
            );
        }

        // Default fallback
        return null;
    };

    return (
        <div
            className="login-container"
            style={{
                background: theme.background,
                color: theme.text,
            }}
        >
            {/* Theme Toggle */}
            <button
                className="theme-toggle"
                onClick={toggleTheme}
                style={{
                    background: theme.secondary,
                    color: theme.text,
                }}
                aria-label="Toggle theme"
            >
                {isDarkMode ? '☀️' : '🌙'}
            </button>

            <div className="login-content">
                {/* Left Side - Branding */}
                <div className="login-branding">
                    <div className="brand-content">
                        <h1 className="brand-title" style={{ color: theme.primary }}>
                            OKiosk
                        </h1>
                        <p className="brand-subtitle" style={{ color: theme.text }}>
                            Your Smart Kiosk Solution
                        </p>
                        <div className="brand-features">
                            <div className="feature-item">
                                <span className="feature-icon" style={{ color: theme.accentOrange }}>⚡</span>
                                <span style={{ color: theme.text }}>Fast & Secure</span>
                            </div>
                            <div className="feature-item">
                                <span className="feature-icon" style={{ color: theme.accentYellow }}>🔒</span>
                                <span style={{ color: theme.text }}>QR Code Login</span>
                            </div>
                            <div className="feature-item">
                                <span className="feature-icon" style={{ color: theme.primary }}>🚀</span>
                                <span style={{ color: theme.text }}>Easy to Use</span>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Right Side - Login/QR Section */}
                <div
                    className="login-qr-section"
                    style={{
                        background: theme.secondary,
                    }}
                >
                    {renderContent()}
                </div>
            </div>
        </div>
    );
};

export default Login;
