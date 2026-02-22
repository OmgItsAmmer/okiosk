import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../hooks/useAuth';
import { API_BASE_URL } from '../config';
import './CheckoutScreen.css';
import { useCart } from '../context/CartContext';
import SuccessModal from '../components/SuccessModal';

const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
        opacity: 1,
        transition: {
            staggerChildren: 0.1
        }
    }
};

const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
        opacity: 1,
        y: 0,
        transition: {
            duration: 0.5
        }
    }
};


const CheckoutScreen: React.FC = () => {
    const navigate = useNavigate();
    const { user, logout } = useAuth();
    const { cart, onCheckoutSuccess, onLogout } = useCart();
    const [isProcessing, setIsProcessing] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [lastOrderId, setLastOrderId] = useState<string | number>('');

    // Show empty-cart message only when not in success state (avoid hiding SuccessModal after checkout)
    if ((!cart || cart.length === 0) && !showSuccessModal) {
        return (
            <motion.div
                className="checkout-screen"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
            >
                <div className="empty-cart-warning">
                    <h2>Your cart is empty</h2>
                    <button onClick={() => navigate('/menu')}>Back to Menu</button>
                </div>
            </motion.div>
        );
    }

    // Calculations
    const subtotal = cart.reduce((sum, item) => {
        const price = item.variant
            ? parseFloat(item.variant.sell_price)
            : parseFloat(item.product.base_price);
        return sum + (price * item.quantity);
    }, 0);

    const shippingFee = 0; // Pickup
    const tax = 0; // Assuming inclusive or 0 for now
    const total = subtotal + shippingFee + tax;

    const handleConfirmOrder = async () => {
        if (!user) {
            setError('User session not found. Please log in again.');
            return;
        }

        setIsProcessing(true);
        setError(null);

        try {
            const checkoutPayload = {
                customerId: parseInt(user.id) || 1,
                addressId: -1,
                shippingMethod: "pickup",
                paymentMethod: "cod",
                cartItems: cart.map(item => ({
                    variantId: item.variant?.variant_id || 0,
                    quantity: item.quantity,
                    sellPrice: item.variant ? parseFloat(item.variant.sell_price) : parseFloat(item.product.base_price),
                    buyPrice: item.variant ? parseFloat(item.variant.buy_price) : 0
                }))
            };

            const response = await fetch(`${API_BASE_URL}/api/checkout`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(checkoutPayload),
            });

            const data = await response.json();

            if (data.success) {
                setLastOrderId(data.orderId);
                onCheckoutSuccess();
                setShowSuccessModal(true);
            } else {
                setError(data.message || 'Checkout failed');
            }
        } catch (err) {
            console.error(err);
            setError('An error occurred during checkout.');
        } finally {
            setIsProcessing(false);
        }
    };

    const handleLogout = async () => {
        await onLogout();
        logout();
        navigate('/login');
    };

    const handleCloseModal = () => {
        navigate('/menu');
    };

    return (
        <motion.div
            className="checkout-screen"
            initial="hidden"
            animate="visible"
            variants={containerVariants}
        >
            <motion.header className="checkout-header" variants={itemVariants}>
                <button className="back-btn" onClick={() => navigate(-1)}>
                    <span>←</span> Back
                </button>
                <div className="header-title-area">
                    <h1>Checkout Order</h1>
                    <p className="header-subtitle">Review your items and confirm your order</p>
                </div>
            </motion.header>

            <div className="checkout-content">
                {/* Invoice Section */}
                <motion.div className="invoice-section" variants={itemVariants}>
                    <div className="section-header">
                        <h2>Order Summary</h2>
                        <span className="item-count-badge">{cart.length} items</span>
                    </div>
                    {/* Order items - card list works on all screen sizes */}
                    <div className="invoice-items-list">
                        {cart.map((item, index) => {
                            const price = item.variant
                                ? parseFloat(item.variant.sell_price)
                                : parseFloat(item.product.base_price);
                            const itemTotal = price * item.quantity;
                            return (
                                <motion.div
                                    key={`${item.product.product_id}-${item.variant?.variant_id || 'base'}`}
                                    className="invoice-card-item"
                                    initial={{ opacity: 0, y: 10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    transition={{ delay: 0.1 + index * 0.05 }}
                                >
                                    <div className="invoice-card-main">
                                        <div className="item-name">{item.product.name}</div>
                                        {item.variant && <div className="item-variant">{item.variant.variant_name}</div>}
                                    </div>
                                    <div className="invoice-card-row">
                                        <span>Qty: {item.quantity}</span>
                                        <span>Rs. {price.toLocaleString()} × {item.quantity}</span>
                                    </div>
                                    <div className="invoice-card-total">Rs. {itemTotal.toLocaleString()}</div>
                                </motion.div>
                            );
                        })}
                    </div>
                </motion.div>

                {/* Details & Confirmation Section */}
                <motion.div className="details-section" variants={itemVariants}>
                    <div className="summary-card">
                        <h2>Payment Details</h2>

                        <div className="payment-summary-rows">
                            <div className="detail-row">
                                <span>Subtotal</span>
                                <span>Rs. {subtotal.toLocaleString()}</span>
                            </div>
                            <div className="detail-row">
                                <span>Shipping Fee</span>
                                <span className="free-badge">FREE</span>
                            </div>
                            <div className="detail-row total-row">
                                <span>Net Amount</span>
                                <span>Rs. {total.toLocaleString()}</span>
                            </div>
                        </div>

                        <div className="checkout-info-cards">
                            <div className="info-group">
                                <label>Payment Method</label>
                                <div className="static-field-mini">
                                    <span className="icon">💵</span>
                                    <span>Cash on Delivery</span>
                                </div>
                            </div>

                            <div className="info-group">
                                <label>Delivery Type</label>
                                <div className="static-field-mini">
                                    <span className="icon">🏪</span>
                                    <span>Store Pickup</span>
                                </div>
                            </div>
                        </div>

                        {error && (
                            <motion.div
                                className="error-message"
                                initial={{ opacity: 0, scale: 0.9 }}
                                animate={{ opacity: 1, scale: 1 }}
                            >
                                {error}
                            </motion.div>
                        )}

                        <motion.button
                            className="confirm-order-btn"
                            onClick={handleConfirmOrder}
                            disabled={isProcessing}
                            whileHover={{ scale: 1.02 }}
                            whileTap={{ scale: 0.98 }}
                        >
                            {isProcessing ? (
                                <span className="loader-container">
                                    <span className="dot-loader"></span>
                                    Processing...
                                </span>
                            ) : 'Confirm Order'}
                        </motion.button>
                    </div>
                </motion.div>
            </div>

            {showSuccessModal && (
                <SuccessModal
                    orderId={lastOrderId}
                    isLoggedIn={user?.userType === 'authenticated'}
                    onLogout={handleLogout}
                    onClose={handleCloseModal}
                />
            )}
        </motion.div>
    );
};

export default CheckoutScreen;

