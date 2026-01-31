import React from 'react';
import type { Product, ProductVariation } from '../types/menu';
import defaultImage from '../assets/images/kks_new_logo_dark.png';

export interface CartItemType {
    product: Product;
    variant?: ProductVariation;
    quantity: number;
}

interface CartItemProps {
    item: CartItemType;
    onUpdateQuantity: (productId: number, variantId: number | undefined, delta: number) => void;
    onRemove: (productId: number, variantId: number | undefined) => void;
}

const CartItem: React.FC<CartItemProps> = ({ item, onUpdateQuantity, onRemove }) => {
    const price = item.variant
        ? parseFloat(item.variant.sell_price)
        : parseFloat(item.product.base_price);

    const subtotal = price * item.quantity;
    const imageSrc = item.product.image_url || defaultImage;
    const variantId = item.variant?.variant_id;

    return (
        <div className="cart-item">
            <img src={imageSrc} alt={item.product.name} className="cart-item-image" />
            <div className="cart-item-details">
                <div className="cart-item-header">
                    <h4 className="cart-item-name">
                        {item.product.name}
                        {item.variant && <span className="cart-item-variant"> ({item.variant.variant_name})</span>}
                    </h4>
                    <button
                        className="remove-item-btn"
                        onClick={() => onRemove(item.product.product_id, variantId)}
                        aria-label="Remove item"
                    >
                        ×
                    </button>
                </div>
                <div className="cart-item-controls">
                    <div className="quantity-controls">
                        <button
                            onClick={() => onUpdateQuantity(item.product.product_id, variantId, -1)}
                            disabled={item.quantity <= 1}
                            className="qty-btn"
                        >
                            -
                        </button>
                        <span className="quantity">{item.quantity}</span>
                        <button
                            onClick={() => onUpdateQuantity(item.product.product_id, variantId, 1)}
                            className="qty-btn"
                        >
                            +
                        </button>
                    </div>
                    <span className="cart-item-subtotal">Rs. {subtotal.toLocaleString()}</span>
                </div>
            </div>
        </div>
    );
};

export default CartItem;
