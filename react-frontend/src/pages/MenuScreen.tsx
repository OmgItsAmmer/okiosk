import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../hooks/useAuth';
import { useCart } from '../context/CartContext';
import './MenuScreen.css';
import type { Category, Product, ProductVariation } from '../types/menu';
import { fetchAllCategories, fetchAllProducts, fetchProductVariants } from '../services/menuService';
import CategorySection from '../components/CategorySection';
import CartPanel from '../components/CartPanel';
import ActiveProductOverlay from '../components/ActiveProductOverlay';
import Loader from '../components/Loader';

const MenuScreen: React.FC = () => {
    const navigate = useNavigate();
    const { logout } = useAuth();
    const { cart, addToCart, removeFromCart, updateQuantity, onLogout } = useCart();
    const [categories, setCategories] = useState<Category[]>([]);
    const [products, setProducts] = useState<Product[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [activeProduct, setActiveProduct] = useState<Product | null>(null);

    const handleLogout = async () => {
        await onLogout();
        await logout();
        navigate('/login');
    };

    // Initial Data Fetch
    useEffect(() => {
        const loadData = async () => {
            try {
                setIsLoading(true);
                const [categoriesData, productsData] = await Promise.all([
                    fetchAllCategories(),
                    fetchAllProducts()
                ]);
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

    const getProductsByCategory = (categoryId: number) => {
        return products.filter(p => p.category_id === categoryId);
    };

    const handleExpandProduct = (product: Product) => {
        setActiveProduct(product);
    };

    const handleAddToCart = async (product: Product, variant?: ProductVariation) => {
        if (variant) {
            await addToCart(variant.variant_id, 1);
        } else {
            const variants = await fetchProductVariants(product.product_id);
            if (variants.length > 0) {
                await addToCart(variants[0].variant_id, 1);
            }
        }
    };

    const handleUpdateQuantity = (productId: number, variantId: number | undefined, delta: number) => {
        updateQuantity(productId, variantId, delta);
    };

    const handleRemoveFromCart = (productId: number, variantId: number | undefined) => {
        removeFromCart(productId, variantId);
    };

    const handleCheckout = () => {
        if (cart.length === 0) return;
        navigate('/checkout');
    };

    const handleBack = () => {
        navigate('/order');
    };

    if (isLoading) {
        return <Loader text="Preparing the menu..." />;
    }

    if (error) {
        return (
            <div className="error-screen">
                <div className="error-screen-card">
                    <span className="error-icon" aria-hidden>!</span>
                    <h2 className="error-title">Something went wrong</h2>
                    <p className="error-message">{error}</p>
                    <button className="error-retry-btn" onClick={() => window.location.reload()}>
                        Retry
                    </button>
                </div>
            </div>
        );
    }

    return (
        <motion.div
            className="menu-screen-container"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
        >
            <div className="left-panel">
                <header className="menu-header">
                    <div className="header-left-group">
                        <button onClick={handleBack} className="back-btn-minimal">
                            <span>←</span> Back to Assistant
                        </button>
                        <h2>Explore Menu</h2>
                    </div>
                    <button
                        className="menu-logout-btn"
                        onClick={handleLogout}
                        title="Logout"
                        style={{
                            background: "var(--color-primary)",
                            color: "var(--color-on-primary, #fff)",
                            border: "none",
                            borderRadius: "8px",
                            padding: "8px 14px",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            transition: "background 0.2s, box-shadow 0.2s",
                            cursor: "pointer",
                            boxShadow: "0 2px 8px rgba(0,0,0,0.06)"
                        }}
                        onMouseOver={e => (e.currentTarget.style.background = "var(--color-primary-dark, #e43949)")}
                        onMouseOut={e => (e.currentTarget.style.background = "var(--color-primary)")}
                    >
                        <svg
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="2"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            className="btn-icon"
                            style={{ marginRight: 6, width: 20, height: 20, color: "var(--color-on-primary, #fff)" }}
                        >
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <polyline points="16 17 21 12 16 7"></polyline>
                            <line x1="21" y1="12" x2="9" y2="12"></line>
                        </svg>
                    </button>
                </header>

                <div className="menu-sections-scrollable">
                    {categories.map(category => {
                        const catProducts = getProductsByCategory(category.category_id);
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
            </div>

            <div className="right-panel-cart">
                <CartPanel
                    cartItems={cart}
                    onUpdateQuantity={(productId, variantId, delta) => handleUpdateQuantity(productId, variantId, delta)}
                    onRemove={handleRemoveFromCart}
                    onCheckout={handleCheckout}
                />
            </div>

            <AnimatePresence>
                {activeProduct && (
                    <ActiveProductOverlay
                        product={activeProduct}
                        onClose={() => setActiveProduct(null)}
                        onAddToCart={handleAddToCart}
                    />
                )}
            </AnimatePresence>
        </motion.div>
    );
};

export default MenuScreen;
