import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import './CheckoutScreen.css';
import type { CartItemType } from '../components/CartItem';
import SuccessModal from '../components/SuccessModal';

interface CheckoutState {
    cart: CartItemType[];
}

const CheckoutScreen: React.FC = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { user } = useAuth();
    const { cart } = (location.state as CheckoutState) || { cart: [] };

    // Redirect if empty cart (unless debugging)
    if (!cart || cart.length === 0) {
        // You might want to useEffect and navigate back, but inline return is safer for rendering
        return (
            <div className="checkout-screen">
                <div className="empty-cart-warning">
                    <h2>Your cart is empty</h2>
                    <button onClick={() => navigate('/menu')}>Back to Menu</button>
                </div>
            </div>
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
                customerId: parseInt(user.id) || 1, // Use user id from auth context
                addressId: -1, // Pickup
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
        <div className="checkout-screen">
            <header className="checkout-header">
                <button className="back-btn" onClick={() => navigate(-1)}>
                    ← Back
                </button>
                <h1>Checkout</h1>
            </header>

            <div className="checkout-content">
                {/* Invoice Section */}
                <div className="invoice-section">
                    <h2>Order Summary</h2>
                    <div className="invoice-table-container">
                        <table className="invoice-table">
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th>Qty</th>
                                    <th>Price</th>
                                    <th>Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                {cart.map((item, index) => {
                                    const price = item.variant
                                        ? parseFloat(item.variant.sell_price)
                                        : parseFloat(item.product.base_price);
                                    const itemTotal = price * item.quantity;

                                    return (
                                        <tr key={index}>
                                            <td>
                                                <div className="item-name">{item.product.name}</div>
                                                {item.variant && <div className="item-variant">{item.variant.variant_name}</div>}
                                            </td>
                                            <td>{item.quantity}</td>
                                            <td>Rs. {price.toLocaleString()}</td>
                                            <td>Rs. {itemTotal.toLocaleString()}</td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                </div>

                {/* Details & Confirmation Section */}
                <div className="details-section">
                    <div className="summary-card">
                        <h2>Payment Details</h2>

                        <div className="detail-row">
                            <span>Subtotal</span>
                            <span>Rs. {subtotal.toLocaleString()}</span>
                        </div>
                        <div className="detail-row">
                            <span>Shipping (Pickup)</span>
                            <span>Rs. {shippingFee.toLocaleString()}</span>
                        </div>
                        <div className="detail-row total-row">
                            <span>Total</span>
                            <span>Rs. {total.toLocaleString()}</span>
                        </div>

                        <div className="info-group">
                            <label>Payment Method</label>
                            <div className="static-field">Cash on Delivery (COD)</div>
                        </div>

                        <div className="info-group">
                            <label>Shipping Method</label>
                            <div className="static-field">Pickup from Store</div>
                        </div>

                        {error && <div className="error-message">{error}</div>}

                        <button
                            className="confirm-order-btn"
                            onClick={handleConfirmOrder}
                            disabled={isProcessing}
                        >
                            {isProcessing ? 'Processing...' : 'Confirm Order'}
                        </button>
                    </div>
                </div>
            </div>

            {showSuccessModal && (
                <SuccessModal
                    orderId={lastOrderId}
                    isLoggedIn={user?.userType === 'authenticated'}
                    onLogout={handleLogout}
                    onClose={handleCloseModal}
                />
            )}
        </div>
    );
};

export default CheckoutScreen;
