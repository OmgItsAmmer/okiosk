import React from 'react';
import type { Product } from '../types/menu';
import defaultImage from '../assets/images/kks_new_logo_dark.png';

interface ProductCardProps {
    product: Product;
    onExpand: (product: Product) => void;
}

const ProductCard: React.FC<ProductCardProps> = ({ product, onExpand }) => {
    const imageSrc = product.image_url || defaultImage;

    const handleCardClick = () => onExpand(product);

    const handleButtonClick = (e: React.MouseEvent) => {
        e.stopPropagation();
        onExpand(product);
    };

    return (
        <div
            className="product-card"
            onClick={handleCardClick}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => e.key === 'Enter' && handleCardClick()}
            aria-label={`View ${product.name}`}
        >
            <div className="product-image-container">
                <img
                    src={imageSrc}
                    alt={product.name}
                    className="product-image"
                    loading="lazy"
                    onError={(e) => { (e.currentTarget as HTMLImageElement).src = defaultImage; }}
                />
            </div>
            <div className="product-info">
                <h3 className="product-name" title={product.name}>{product.name}</h3>
                <p className="product-description" title={product.description || ''}>
                    {product.description || 'No description available'}
                </p>
                <div className="product-footer">
                    <span className="product-price">Rs. {parseFloat(product.base_price).toLocaleString()}</span>
                    <div className="product-actions" onClick={(e) => e.stopPropagation()}>
                     
                        <button
                            className="add-to-cart-btn"
                            onClick={handleButtonClick}
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
