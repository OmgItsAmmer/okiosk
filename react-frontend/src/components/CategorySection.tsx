import React, { useState } from 'react';
import type { Category, Product } from '../types/menu';
import ProductCard from './ProductCard';

interface CategorySectionProps {
    category: Category;
    products: Product[];
    onExpandProduct: (product: Product) => void;
}

const CategorySection: React.FC<CategorySectionProps> = ({ category, products, onExpandProduct }) => {
    const [isExpanded, setIsExpanded] = useState(true);

    if (products.length === 0) return null;

    return (
        <div className="category-section">
            <div
                className="category-header"
                onClick={() => setIsExpanded(!isExpanded)}
                role="button"
                tabIndex={0}
                aria-expanded={isExpanded}
            >
                <h2 className="category-title">{category.category_name} ({products.length})</h2>
                <span className={`expand-icon ${isExpanded ? 'expanded' : ''}`}>▼</span>
            </div>

            {isExpanded && (
                <div className="product-grid">
                    {products.map(product => (
                        <ProductCard
                            key={product.product_id}
                            product={product}
                            onExpand={onExpandProduct}
                        />
                    ))}
                </div>
            )}
        </div>
    );
};

export default CategorySection;
