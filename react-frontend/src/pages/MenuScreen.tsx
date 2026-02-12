import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import './MenuScreen.css';
import type { Category, Product, ProductVariation } from '../types/menu';
import { fetchAllCategories, fetchAllProducts } from '../services/menuService';
import CategorySection from '../components/CategorySection';
import CartPanel from '../components/CartPanel';
import { type CartItemType } from '../components/CartItem';
import ActiveProductOverlay from '../components/ActiveProductOverlay';
import Loader from '../components/Loader';

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

    const handleAddToCart = (product: Product, variant?: ProductVariation) => {
        setCart(prevCart => {
            const existingItem = prevCart.find(item =>
                item.product.product_id === product.product_id &&
                item.variant?.variant_id === variant?.variant_id
            );

            if (existingItem) {
                return prevCart.map(item =>
                    (item.product.product_id === product.product_id && item.variant?.variant_id === variant?.variant_id)
                        ? { ...item, quantity: item.quantity + 1 }
                        : item
                );
            } else {
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
        if (cart.length === 0) return;
        navigate('/checkout', { state: { cart } });
    };

    const handleBack = () => {
        navigate('/order');
    };

    if (isLoading) {
        return <Loader text="Preparing the menu..." />;
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
        <motion.div
            className="menu-screen-container"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
        >
            <div className="left-panel">
                <header className="menu-header">
                    <button onClick={handleBack} className="back-btn-minimal">
                        <span>←</span> Back to Assistant
                    </button>
                    <h1>Explore Menu</h1>
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
                    onUpdateQuantity={handleUpdateQuantity}
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
