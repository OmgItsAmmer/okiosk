import React, { useState, useEffect } from 'react';
import type { Product, ProductVariation } from '../types/menu';
import { fetchProductVariants } from '../services/menuService';
import defaultImage from '../assets/images/kks_new_logo_dark.png';

interface ActiveProductOverlayProps {
    product: Product;
    onClose: () => void;
    onAddToCart: (product: Product, variant?: ProductVariation) => void;
}

const ActiveProductOverlay: React.FC<ActiveProductOverlayProps> = ({ product, onClose, onAddToCart }) => {
    const [isFlipped, setIsFlipped] = useState(false);
    const [variants, setVariants] = useState<ProductVariation[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [selectedVariant, setSelectedVariant] = useState<ProductVariation | null>(null);
    const [isClosing, setIsClosing] = useState(false);

    useEffect(() => {
        let isMounted = true;

        const loadVariants = async () => {
            try {
                // Determine if we need to fetch variants
                // If the product seems to have no variants logic in DB (simple product), we might skip
                // But generally we check.
                const data = await fetchProductVariants(product.product_id);
                if (isMounted) {
                    setVariants(data);
                    setIsLoading(false);
                    // Flip automatically after a short delay for zoom to finish
                    setTimeout(() => {
                        if (isMounted) setIsFlipped(true);
                    }, 400);
                }
            } catch (error) {
                console.error("Error fetching variants", error);
                if (isMounted) {
                    setIsLoading(false);
                    // If error, maybe just flip to show error or stay on front?
                    // User requirement: "Fetch... Display all variants on back... Error state"
                    // We'll flip anyway to show error/empty state
                    setTimeout(() => {
                        if (isMounted) setIsFlipped(true);
                    }, 400);
                }
            }
        };

        loadVariants();

        return () => { isMounted = false; };
    }, [product.product_id]);

    const handleClose = () => {
        setIsFlipped(false);
        // Wait for flip back then close
        setTimeout(() => {
            setIsClosing(true);
            setTimeout(onClose, 300); // Wait for fadeOut
        }, 300); // Wait for half flip or full flip? User: "Flips the card back. Animates it back."
        // Let's do: Flip back (0.6s) -> Then Zoom Out/Close.
        // Actually, user said: "Clicking anywhere... Flips the card back. Animates it back."
        // So flip back, then close.
    };

    const handleAddToCartClick = () => {
        if (selectedVariant) {
            onAddToCart(product, selectedVariant);
        } else if (variants.length === 0 && !isLoading) {
            // Fallback for no variants found
            onAddToCart(product);
        }
        handleClose();
    };

    const imageSrc = product.image_url || defaultImage;

    return (
        <div className={`product-card-overlay ${isClosing ? 'closing' : ''}`} onClick={handleClose}>
            <div className="zoomed-card-container" onClick={(e) => e.stopPropagation()}>
                <div className={`card-flipper ${isFlipped ? 'flipped' : ''}`}>
                    {/* Front Side */}
                    <div className="card-front">
                        {isLoading && (
                            <div className="card-front-loading" aria-live="polite">
                                <div className="card-front-loading-spinner" />
                                <span className="card-front-loading-text">Loading options...</span>
                            </div>
                        )}
                        <div className="product-image-container" style={{ height: '250px' }}>
                            <img src={imageSrc} alt={product.name} className="product-image" />
                        </div>
                        <div className="product-info">
                            <h3 className="product-name" style={{ fontSize: '1.5rem', whiteSpace: 'normal' }}>{product.name}</h3>
                            <p className="product-description" style={{ fontSize: '1rem', lineClamp: 3, WebkitLineClamp: 3 }}>
                                {product.description || 'No description available'}
                            </p>
                            <div className="product-footer">
                                <span className="product-price" style={{ fontSize: '1.2rem' }}>
                                    Rs. {parseFloat(product.base_price).toLocaleString()}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Back Side */}
                    <div className="card-back">
                        <div className="card-back-header">
                            <h3 className="card-back-title">Select Option</h3>
                        </div>

                        <div className="card-back-content">
                            {isLoading ? (
                                <div style={{ textAlign: 'center', padding: 20 }}>Loading options...</div>
                            ) : variants.length > 0 ? (
                                <div className="variant-list">
                                    {variants.map(v => {
                                        const isOutOfStock = v.stock <= 0;
                                        return (
                                            <div
                                                key={v.variant_id}
                                                className={`variant-item ${selectedVariant?.variant_id === v.variant_id ? 'selected' : ''} ${isOutOfStock ? 'disabled' : ''}`}
                                                onClick={() => !isOutOfStock && setSelectedVariant(v)}
                                            >
                                                <div className="variant-info">
                                                    <span className="variant-name">{v.variant_name}</span>
                                                    <span className="variant-stock">
                                                        {isOutOfStock ? 'Out of Stock' : `In Stock: ${v.stock}`}
                                                    </span>
                                                </div>
                                                <div className="variant-price">
                                                    Rs. {parseFloat(v.sell_price).toLocaleString()}
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            ) : (
                                <div style={{ textAlign: 'center', padding: 20, color: '#aaa' }}>
                                    No options available. <br />
                                    Add standard item?
                                </div>
                            )}
                        </div>

                        <div className="card-back-footer">
                            <button className="cancel-btn" onClick={handleClose}>Cancel</button>
                            <button
                                className="confirm-add-btn"
                                onClick={handleAddToCartClick}
                                disabled={variants.length > 0 && !selectedVariant}
                            >
                                Add to Cart
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ActiveProductOverlay;
