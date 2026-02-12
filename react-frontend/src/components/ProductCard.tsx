import React from 'react';
import type { Product } from '../types/menu';
import defaultImage from '../assets/images/kks_new_logo_dark.png';

interface ProductCardProps {
    product: Product;
    onExpand: (product: Product) => void;
}

const ProductCard: React.FC<ProductCardProps> = ({ product, onExpand }) => {
    // Always show the default fallback image as per user request
    const imageSrc = defaultImage;

    return (
        <div className="product-card">
            <div className="product-image-container">
                <img src={imageSrc} alt={product.name} className="product-image" loading="lazy" />
            </div>
            <div className="product-info">
                <h3 className="product-name" title={product.name}>{product.name}</h3>
                <p className="product-description" title={product.description || ''}>
                    {product.description || 'No description available'}
                </p>
                <div className="product-footer">
                    <span className="product-price">Rs. {parseFloat(product.base_price).toLocaleString()}</span>
                    <div className="product-actions">
                        <button
                            className="product-info-btn"
                            onClick={() => onExpand(product)}
                            aria-label={`View details for ${product.name}`}
                        >
                            <span>i</span>
                        </button>
                        <button
                            className="add-to-cart-btn"
                            onClick={() => onExpand(product)}
                            aria-label={`Select ${product.name}`}
                        >
                            Add <span>+</span>
                        </button>
                    </div>
                </div>

            </div>
        </div>
    );
};

export default ProductCard;
