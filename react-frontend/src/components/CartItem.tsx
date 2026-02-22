import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { Product, ProductVariation } from '../types/menu';
import defaultImage from '../assets/images/kks_new_logo_dark.png';
import './CartItem.css';

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
        <motion.div
            className="cart-item"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, scale: 0.95 }}
            layout
        >
            <div className="cart-item-image-container">
                <img
                src={imageSrc}
                alt={item.product.name}
                className="cart-item-image"
                onError={(e) => { (e.currentTarget as HTMLImageElement).src = defaultImage; }}
            />
            </div>

            <div className="cart-item-details">
                <div className="cart-item-header">
                    <div className="cart-item-title-area">
                        <h4 className="cart-item-name">{item.product.name}</h4>
                        {item.variant && (
                            <span className="cart-item-variant">
                                {item.variant.variant_name}
                            </span>
                        )}
                    </div>
                    <button
                        type="button"
                        className="remove-item-btn"
                        onClick={(e) => {
                            e.stopPropagation();
                            onRemove(item.product.product_id, variantId);
                        }}
                        aria-label="Remove item"
                    >
                        ×
                    </button>
                </div>

                <div className="cart-item-controls">
                    <div className="quantity-controls">
                        <button
                            type="button"
                            onClick={(e) => {
                                e.stopPropagation();
                                onUpdateQuantity(item.product.product_id, variantId, -1);
                            }}
                            disabled={item.quantity <= 1}
                            className="qty-btn"
                            aria-label="Decrease quantity"
                        >
                            −
                        </button>
                        <AnimatePresence mode="wait">
                            <motion.span
                                key={item.quantity}
                                initial={{ opacity: 0, y: -10 }}
                                animate={{ opacity: 1, y: 0 }}
                                exit={{ opacity: 0, y: 10 }}
                                className="quantity"
                            >
                                {item.quantity}
                            </motion.span>
                        </AnimatePresence>
                        <button
                            type="button"
                            onClick={(e) => {
                                e.stopPropagation();
                                onUpdateQuantity(item.product.product_id, variantId, 1);
                            }}
                            className="qty-btn"
                            aria-label="Increase quantity"
                        >
                            +
                        </button>
                    </div>
                    <div className="cart-item-price-info">
                        <span className="cart-item-subtotal">Rs. {subtotal.toLocaleString()}</span>
                    </div>
                </div>
            </div>
        </motion.div>
    );
};

export default CartItem;

