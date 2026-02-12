import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../hooks/useAuth';
import './CheckoutScreen.css';
import type { CartItemType } from '../components/CartItem';
import SuccessModal from '../components/SuccessModal';

interface CheckoutState {
    cart: CartItemType[];
}

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
    const location = useLocation();
    const navigate = useNavigate();
    const { user } = useAuth();
    const { cart } = (location.state as CheckoutState) || { cart: [] };

    // Redirect if empty cart (unless debugging)
    if (!cart || cart.length === 0) {
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

    const [isProcessing, setIsProcessing] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showSuccessModal, setShowSuccessModal] = useState(false);
    const [lastOrderId, setLastOrderId] = useState<string | number>('');

    const { logout } = useAuth();

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

            const response = await fetch('http://localhost:3000/api/checkout', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(checkoutPayload),
            });

            const data = await response.json();

            if (data.success) {
                setLastOrderId(data.orderId);
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

    const handleLogout = () => {
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
                    <div className="invoice-table-container">
                        <table className="invoice-table">
                            <thead>
                                <tr>
                                    <th>Item Details</th>
                                    <th className="text-center">Qty</th>
                                    <th className="text-right">Price</th>
                                    <th className="text-right">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                <AnimatePresence>
                                    {cart.map((item, index) => {
                                        const price = item.variant
                                            ? parseFloat(item.variant.sell_price)
                                            : parseFloat(item.product.base_price);
                                        const itemTotal = price * item.quantity;

                                        return (
                                            <motion.tr
                                                key={`${item.product.product_id}-${item.variant?.variant_id || 'base'}`}
                                                initial={{ opacity: 0, x: -20 }}
                                                animate={{ opacity: 1, x: 0 }}
                                                transition={{ delay: 0.2 + (index * 0.05) }}
                                                viewport={{ once: true }}
                                            >
                                                <td>
                                                    <div className="item-name">{item.product.name}</div>
                                                    {item.variant && <div className="item-variant">{item.variant.variant_name}</div>}
                                                </td>
                                                <td className="text-center quantity-cell">{item.quantity}</td>
                                                <td className="text-right">Rs. {price.toLocaleString()}</td>
                                                <td className="text-right font-bold">Rs. {itemTotal.toLocaleString()}</td>
                                            </motion.tr>
                                        );
                                    })}
                                </AnimatePresence>
                            </tbody>
                        </table>
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

