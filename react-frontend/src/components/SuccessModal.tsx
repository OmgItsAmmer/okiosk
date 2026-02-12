import React, { useState, useEffect } from 'react';
import './SuccessModal.css';

interface SuccessModalProps {
    orderId: string | number;
    isLoggedIn: boolean;
    onClose: () => void;
    onLogout: () => void;
}

const SuccessModal: React.FC<SuccessModalProps> = ({ orderId, isLoggedIn, onClose, onLogout }) => {
    const [countdown, setCountdown] = useState(30);

    useEffect(() => {
        if (countdown <= 0) {
            onLogout();
            return;
        }

        const timer = setInterval(() => {
            setCountdown(prev => prev - 1);
        }, 1000);

        return () => clearInterval(timer);
    }, [countdown, onLogout]);

    return (
        <div className="success-modal-overlay">
            <div className="success-modal-content">
                <div className="success-icon-container">
                    <span className="success-icon">✓</span>
                </div>

                <h2>Order Successful!</h2>
                <div className="order-id-badge">Order ID: #{orderId}</div>

                <p className="success-message">
                    Thank you for your purchase. Your order has been placed successfully and is being processed.
                </p>

                <div className="countdown-container">
                    <div className="countdown-text">Automatically logging out in {countdown}s</div>
                    <div className="countdown-bar-bg">
                        <div
                            className="countdown-bar-fill"
                            style={{ width: `${(countdown / 30) * 100}%` }}
                        ></div>
                    </div>
                </div>

                <div className="modal-actions">
                    <button className="modal-btn btn-logout" onClick={onLogout}>
                        Okay and Logout
                    </button>
                    {isLoggedIn && (
                        <button className="modal-btn btn-menu" onClick={onClose}>
                            Okay
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default SuccessModal;
