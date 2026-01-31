import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import './MenuScreen.css';
import type { Category, Product, ProductVariation } from '../types/menu';
import { fetchAllCategories, fetchAllProducts } from '../services/menuService';
import CategorySection from '../components/CategorySection';
import CartPanel from '../components/CartPanel';
import { type CartItemType } from '../components/CartItem';
import ActiveProductOverlay from '../components/ActiveProductOverlay';

const MenuScreen: React.FC = () => {
    const navigate = useNavigate();
    const [categories, setCategories] = useState<Category[]>([]);
    const [products, setProducts] = useState<Product[]>([]);
    const [cart, setCart] = useState<CartItemType[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [activeProduct, setActiveProduct] = useState<Product | null>(null);

    // Initial Data Fetch
    useEffect(() => {
        const loadData = async () => {
            try {
                setIsLoading(true);
                // Fetch in parallel
                const [categoriesData, productsData] = await Promise.all([
                    fetchAllCategories(),
                    fetchAllProducts()
                ]);

                // Filter out non-visible products/categories if API doesn't already
                setCategories(categoriesData.categories);
                setProducts(productsData.products);
            } catch (err) {
                console.error("Failed to load menu data:", err);
                setError("Failed to load menu. Please try again.");
            } finally {
                setIsLoading(false);
            }
        };

        loadData();
    }, []);

    // Helper: Get products for a specific category
    const getProductsByCategory = (categoryId: number) => {
        return products.filter(p => p.category_id === categoryId);
    };

    const handleExpandProduct = (product: Product) => {
        setActiveProduct(product);
    };

    // Cart Actions
    const handleAddToCart = (product: Product, variant?: ProductVariation) => {
        setCart(prevCart => {
            const existingItem = prevCart.find(item =>
                item.product.product_id === product.product_id &&
                item.variant?.variant_id === variant?.variant_id
            );

            if (existingItem) {
                // Increment quantity
                return prevCart.map(item =>
                    (item.product.product_id === product.product_id && item.variant?.variant_id === variant?.variant_id)
                        ? { ...item, quantity: item.quantity + 1 }
                        : item
                );
            } else {
                // Add new item
                return [...prevCart, { product, variant, quantity: 1 }];
            }
        });
    };

    const handleUpdateQuantity = (productId: number, variantId: number | undefined, delta: number) => {
        setCart(prevCart => {
            return prevCart.map(item => {
                if (item.product.product_id === productId && item.variant?.variant_id === variantId) {
                    const newQuantity = Math.max(1, item.quantity + delta);
                    return { ...item, quantity: newQuantity };
                }
                return item;
            });
        });
    };

    const handleRemoveFromCart = (productId: number, variantId: number | undefined) => {
        setCart(prevCart => prevCart.filter(item =>
            !(item.product.product_id === productId && item.variant?.variant_id === variantId)
        ));
    };

    const handleCheckout = () => {
        if (cart.length === 0) {
            alert("Your cart is empty!");
            return;
        }
        navigate('/checkout', { state: { cart } });
    };

    const handleBack = () => {
        navigate('/order'); // Go back to Order Assistant
    };

    if (isLoading) {
        return <div className="loading-screen">Loading Menu...</div>;
    }

    if (error) {
        return (
            <div className="error-screen" style={{ padding: 20, textAlign: 'center', color: 'white' }}>
                <h2>Error</h2>
                <p>{error}</p>
                <button onClick={() => window.location.reload()} style={{ marginTop: 20 }}>Retry</button>
            </div>
        );
    }

    return (
        <div className="menu-screen-container">
            {/* Left Panel: Categories & Products */}
            <div className="left-panel">
                <header style={{ marginBottom: 20, display: 'flex', alignItems: 'center', gap: 10 }}>
                    <button onClick={handleBack} style={{ padding: '4px 8px', background: 'transparent', border: '1px solid #555', color: '#ccc' }}>
                        ← Back
                    </button>
                    <h1 style={{ margin: 0, fontSize: '2rem' }}>Explore Menu</h1>
                </header>

                {categories.map(category => {
                    const catProducts = getProductsByCategory(category.category_id);
                    // Only render category if it has products
                    if (catProducts.length === 0) return null;

                    return (
                        <CategorySection
                            key={category.category_id}
                            category={category}
                            products={catProducts}
                            onExpandProduct={handleExpandProduct}
                        />
                    );
                })}
            </div>

            {/* Right Panel: Cart */}
            <div className="right-panel-cart">
                <CartPanel
                    cartItems={cart}
                    onUpdateQuantity={handleUpdateQuantity}
                    onRemove={handleRemoveFromCart}
                    onCheckout={handleCheckout}
                />
            </div>

            {/* Active Product Overlay */}
            {activeProduct && (
                <ActiveProductOverlay
                    product={activeProduct}
                    onClose={() => setActiveProduct(null)}
                    onAddToCart={handleAddToCart}
                />
            )}
        </div>
    );
};

export default MenuScreen;
