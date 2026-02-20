import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from '../hooks/useAuth';
import * as cartService from '../services/cartService';
import type { CartItemType } from '../components/CartItem';
import type { Product, ProductVariation } from '../types/menu';

export interface SessionCartItem extends CartItemType {
    cartId: number;
    isKiosk: boolean;
}

interface CartContextType {
    cart: CartItemType[];
    cartCount: number;
    isLoading: boolean;
    addToCart: (variantId: number, quantity: number) => Promise<void>;
    removeFromCart: (productId: number, variantId: number | undefined) => Promise<void>;
    updateQuantity: (productId: number, variantId: number | undefined, delta: number) => Promise<void>;
    refreshCart: () => Promise<void>;
    clearCart: () => Promise<void>;
    onCheckoutSuccess: () => void;
    onLogout: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

function mapApiItemToCartItem(item: {
    cart_id: number;
    variant_id?: number;
    quantity: number;
    product_id: number;
    product_name: string;
    product_description?: string | null;
    base_price: string;
    sale_price: string;
    variant_name: string;
    sell_price: string | number;
    buy_price?: string | number | null;
    stock?: number;
    kiosk_session_id?: string | null;
}): SessionCartItem {
    const product: Product = {
        product_id: item.product_id,
        name: item.product_name,
        description: item.product_description ?? null,
        base_price: item.base_price,
        sale_price: item.sale_price,
        price_range: item.base_price,
        category_id: null,
        ispopular: false,
        stock_quantity: item.stock ?? 0,
        created_at: null,
        brandID: null,
        alert_stock: 0,
        isVisible: true,
        tag: null,
        image_url: null,
    };
    const variant: ProductVariation | undefined = item.variant_id
        ? {
              variant_id: item.variant_id,
              sell_price: String(item.sell_price),
              buy_price: String(item.buy_price ?? 0),
              product_id: item.product_id,
              variant_name: item.variant_name,
              stock: item.stock ?? 0,
              is_visible: true,
          }
        : undefined;
    return {
        product,
        variant,
        quantity: item.quantity,
        cartId: item.cart_id,
        isKiosk: !!item.kiosk_session_id,
    };
}

export const CartProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { user, sessionId } = useAuth();
    const [sessionItems, setSessionItems] = useState<SessionCartItem[]>([]);
    const [isLoading, setIsLoading] = useState(false);

    const customerId = user?.id ? parseInt(user.id, 10) : undefined;
    const kioskSessionId = sessionId || undefined;

    const fetchCart = useCallback(async () => {
        if (!customerId && !kioskSessionId) {
            setSessionItems([]);
            return;
        }
        try {
            const data = await cartService.getCart(customerId, kioskSessionId);
            const items = (data.items || []).map(mapApiItemToCartItem);
            setSessionItems(items);
        } catch (err) {
            console.error('Failed to fetch cart:', err);
            setSessionItems([]);
        }
    }, [customerId, kioskSessionId]);

    useEffect(() => {
        fetchCart();
    }, [fetchCart]);

    // Clear cart when user logs out (no user and no session)
    useEffect(() => {
        if (!customerId && !kioskSessionId) {
            setSessionItems([]);
        }
    }, [customerId, kioskSessionId]);

    const addToCart = useCallback(
        async (variantId: number, quantity: number) => {
            if (!customerId && !kioskSessionId) return;
            await cartService.addToCart(variantId, quantity, customerId, kioskSessionId);
            await fetchCart();
        },
        [customerId, kioskSessionId, fetchCart]
    );

    const removeFromCart = useCallback(
        async (productId: number, variantId: number | undefined) => {
            const item = sessionItems.find(
                (i) =>
                    i.product.product_id === productId &&
                    (i.variant?.variant_id ?? null) === (variantId ?? null)
            );
            if (!item) return;
            await cartService.removeFromCart(item.cartId, item.isKiosk);
            await fetchCart();
        },
        [sessionItems, fetchCart]
    );

    const updateQuantity = useCallback(
        async (productId: number, variantId: number | undefined, delta: number) => {
            const item = sessionItems.find(
                (i) =>
                    i.product.product_id === productId &&
                    (i.variant?.variant_id ?? null) === (variantId ?? null)
            );
            if (!item) return;
            const newQty = Math.max(1, item.quantity + delta);
            if (newQty === item.quantity) return;
            await cartService.updateCartQuantity(item.cartId, newQty, item.isKiosk);
            await fetchCart();
        },
        [sessionItems, fetchCart]
    );

    const clearCart = useCallback(async () => {
        if (!customerId && !kioskSessionId) return;
        await cartService.clearCart(customerId, kioskSessionId);
        setSessionItems([]);
    }, [customerId, kioskSessionId]);

    const onCheckoutSuccess = useCallback(() => {
        setSessionItems([]);
    }, []);

    const onLogout = useCallback(async () => {
        if (customerId || kioskSessionId) {
            try {
                await cartService.clearCart(customerId, kioskSessionId);
            } catch {
                // Ignore - user is logging out
            }
        }
        setSessionItems([]);
    }, [customerId, kioskSessionId]);

    const cart: CartItemType[] = sessionItems.map(({ product, variant, quantity }) => ({
        product,
        variant,
        quantity,
    }));
    const cartCount = cart.reduce((sum, i) => sum + i.quantity, 0);

    const value: CartContextType = {
        cart,
        cartCount,
        isLoading,
        addToCart,
        removeFromCart,
        updateQuantity,
        refreshCart: fetchCart,
        clearCart,
        onCheckoutSuccess,
        onLogout,
    };

    return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

export const useCart = (): CartContextType => {
    const ctx = useContext(CartContext);
    if (ctx === undefined) {
        throw new Error('useCart must be used within a CartProvider');
    }
    return ctx;
};
