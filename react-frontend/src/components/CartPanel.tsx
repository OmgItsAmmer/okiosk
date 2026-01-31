import React from 'react';
import CartItem, { type CartItemType } from './CartItem';

interface CartPanelProps {
    cartItems: CartItemType[];
    onUpdateQuantity: (productId: number, variantId: number | undefined, delta: number) => void;
    onRemove: (productId: number, variantId: number | undefined) => void;
    onCheckout: () => void;
}

const CartPanel: React.FC<CartPanelProps> = ({ cartItems, onUpdateQuantity, onRemove, onCheckout }) => {
    const netTotal = cartItems.reduce((sum, item) => {
        const price = item.variant
            ? parseFloat(item.variant.sell_price)
            : parseFloat(item.product.base_price);
        return sum + (price * item.quantity);
    }, 0);

    return (
        <div className="cart-panel">
            <div className="cart-header">
                <h2>Current Order</h2>
                <span className="cart-count">{cartItems.length} Items</span>
            </div>

            <div className="cart-items-list">
                {cartItems.length === 0 ? (
                    <div className="empty-cart-message">
                        Your cart is empty. <br /> Add items from the menu!
                    </div>
                ) : (
                    cartItems.map(item => (
                        <CartItem
                            key={`${item.product.product_id}-${item.variant?.variant_id || 'base'}`}
                            item={item}
                            onUpdateQuantity={onUpdateQuantity}
                            onRemove={onRemove}
                        />
                    ))
                )}
            </div>

            <div className="cart-footer">
                <div className="net-total-container">
                    <span className="net-total-label">Net Total</span>
                    <span className="net-total-amount">Rs. {netTotal.toLocaleString()}</span>
                </div>
                <button
                    className="checkout-btn"
                    onClick={onCheckout}
                    disabled={cartItems.length === 0}
                >
                    Checkout
                </button>
            </div>
        </div>
    );
};

export default CartPanel;
