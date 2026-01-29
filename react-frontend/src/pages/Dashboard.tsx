import React, { useState, useEffect } from 'react';
import { useAuth } from '../hooks/useAuth';
import { AuthState } from '../types/auth';
import QRCode from 'qrcode';
import { colors } from '../constants/colors';
import './Dashboard.css';

const Dashboard: React.FC = () => {
    const {
        user,
        logout,
        authState,
        qrSession,
        upgradeToAuth,
        cancelLogin
    } = useAuth();

    const [showUpgradeModal, setShowUpgradeModal] = useState(false);
    const [qrCodeUrl, setQrCodeUrl] = useState<string>('');
    const [timeRemaining, setTimeRemaining] = useState<number>(0);

    const isGuest = user?.userType === 'guest';

    // Generate QR code for upgrade flow
    useEffect(() => {
        if (!qrSession || authState !== AuthState.UPGRADE_PENDING) {
            setQrCodeUrl('');
            return;
        }

        QRCode.toDataURL(qrSession.qrUrl, {
            width: 250,
            margin: 2,
            color: {
                dark: colors.light.text,
                light: colors.light.secondary,
            },
        })
            .then((url) => {
                setQrCodeUrl(url);
                setShowUpgradeModal(true);
            })
            .catch((err) => {
                console.error('Error generating QR code:', err);
            });
    }, [qrSession, authState]);

    // Timer for upgrade QR session
    useEffect(() => {
        if (!qrSession || authState !== AuthState.UPGRADE_PENDING) {
            setTimeRemaining(0);
            return;
        }

        const updateTimer = () => {
            const remaining = Math.max(0, qrSession.expiresAt.getTime() - Date.now());
            setTimeRemaining(Math.ceil(remaining / 1000));

            if (remaining <= 0) {
                setShowUpgradeModal(false);
            }
        };

        updateTimer();
        const interval = setInterval(updateTimer, 1000);

        return () => clearInterval(interval);
    }, [qrSession, authState]);

    // Close modal when auth state changes from UPGRADE_PENDING
    useEffect(() => {
        if (authState !== AuthState.UPGRADE_PENDING) {
            setShowUpgradeModal(false);
        }
    }, [authState]);

    const handleUpgradeClick = async () => {
        try {
            await upgradeToAuth();
        } catch (err) {
            console.error('Failed to start upgrade:', err);
        }
    };

    const handleCancelUpgrade = () => {
        cancelLogin();
        setShowUpgradeModal(false);
        setQrCodeUrl('');
    };

    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    };

    return (
        <div className="dashboard-container">
            <div className="dashboard-header">
                <div className="header-left">
                    <h1>Welcome, {user?.name || 'User'}!</h1>
                    {isGuest && (
                        <span className="guest-badge">Guest Session</span>
                    )}
                </div>
                <div className="header-actions">
                    {isGuest && (
                        <button
                            onClick={handleUpgradeClick}
                            className="upgrade-btn"
                            disabled={authState === AuthState.UPGRADE_PENDING}
                        >
                            🔐 Upgrade to Google Account
                        </button>
                    )}
                    <button onClick={logout} className="logout-btn">
                        Logout
                    </button>
                </div>
            </div>

            <div className="dashboard-content">
                <div className="user-info-card">
                    {user?.picture ? (
                        <img src={user.picture} alt={user.name} className="user-avatar" />
                    ) : (
                        <div className="user-avatar-placeholder">
                            {isGuest ? '👤' : user?.name?.charAt(0) || '?'}
                        </div>
                    )}
                    <h2>{user?.name}</h2>
                    {user?.email && <p>{user.email}</p>}
                    <div className="user-type-badge" data-type={user?.userType}>
                        {isGuest ? '👤 Guest' : '✓ Authenticated'}
                    </div>
                </div>

                <div className="welcome-message">
                    {isGuest ? (
                        <>
                            <h3>👋 Welcome, Guest!</h3>
                            <p>You're using a temporary guest session.</p>
                            <p className="info-text">
                                To save your data and access all features, upgrade to a Google account.
                            </p>
                        </>
                    ) : (
                        <>
                            <h3>🎉 Authentication Successful!</h3>
                            <p>You've successfully logged in using Google Sign-In via QR code.</p>
                            <p className="info-text">
                                Your session is now active. You can start using the kiosk.
                            </p>
                        </>
                    )}
                </div>
            </div>

            {/* Upgrade Modal */}
            {showUpgradeModal && (
                <div className="modal-overlay" onClick={handleCancelUpgrade}>
                    <div className="upgrade-modal" onClick={e => e.stopPropagation()}>
                        <button className="modal-close" onClick={handleCancelUpgrade}>
                            ✕
                        </button>

                        <h2>Upgrade to Google Account</h2>
                        <p className="modal-subtitle">
                            Scan the QR code with your phone to sign in with Google
                        </p>

                        {qrCodeUrl ? (
                            <div className="qr-container">
                                <img src={qrCodeUrl} alt="QR Code" className="upgrade-qr" />
                                <div className="qr-timer" style={{
                                    color: timeRemaining < 60 ? colors.light.primary : 'inherit'
                                }}>
                                    ⏱️ Expires in {formatTime(timeRemaining)}
                                </div>
                            </div>
                        ) : (
                            <div className="qr-loading">
                                <div className="spinner"></div>
                                <p>Generating QR Code...</p>
                            </div>
                        )}

                        <div className="modal-instructions">
                            <p>1. Open camera on your phone</p>
                            <p>2. Scan the QR code</p>
                            <p>3. Sign in with your Google account</p>
                        </div>

                        <button className="cancel-upgrade-btn" onClick={handleCancelUpgrade}>
                            Cancel
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Dashboard;
