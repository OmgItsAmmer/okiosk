import axios from 'axios';

import { API_BASE_URL as ROOT_URL } from '../config';
const API_BASE_URL = `${ROOT_URL}/api`;

export interface CartItemAddRequest {
    variant_id: number;
    quantity: number;
}

export interface VariantConfirmationRequest {
    action: string;
    status: string;
    product_name: string;
    variant_id?: number;
    quantity?: number;
    session_id?: string;
    customer_id?: number;
}

export interface VariantConfirmationResponse {
    success: boolean;
    message: string;
    has_more: boolean;
    next_action?: any;
    error?: string;
}

export const addToCart = async (
    variantId: number,
    quantity: number,
    customerId?: number,
    sessionId?: string
): Promise<any> => {
    try {
        if (customerId) {
            const response = await axios.post(`${API_BASE_URL}/cart/${customerId}/add`, {
                variant_id: variantId,
                quantity
            });
            return response.data;
        } else if (sessionId) {
            const response = await axios.post(`${API_BASE_URL}/cart/kiosk/add`, {
                variant_id: variantId,
                quantity,
                session_id: sessionId
            });
            return response.data;
        } else {
            throw new Error('No customer ID or session ID provided');
        }
    } catch (error) {
        console.error('Add to Cart Error:', error);
        throw error;
    }
};

export const getCart = async (
    customerId?: number,
    sessionId?: string
): Promise<any> => {
    try {
        const url = customerId
            ? `${API_BASE_URL}/cart/${customerId}`
            : `${API_BASE_URL}/cart/kiosk/${sessionId}`;
        const response = await axios.get(url);
        return response.data;
    } catch (error) {
        console.error('Get Cart Error:', error);
        throw error;
    }
};

export const updateCartQuantity = async (
    cartId: number,
    quantity: number,
    isKiosk: boolean = false,
    variantId?: number
): Promise<any> => {
    try {
        // Guest cart (cartId 0) uses variant-based API
        if (cartId === 0 && variantId !== undefined) {
            const response = await axios.put(`${API_BASE_URL}/cart/guest/item`, {
                variant_id: variantId,
                quantity,
            });
            return response.data;
        }
        const url = isKiosk
            ? `${API_BASE_URL}/cart/kiosk/item/${cartId}`
            : `${API_BASE_URL}/cart/item/${cartId}`;
        const response = await axios.put(url, { quantity });
        return response.data;
    } catch (error) {
        console.error('Update Cart Quantity Error:', error);
        throw error;
    }
};

export const removeFromCart = async (
    cartId: number,
    isKiosk: boolean = false,
    variantId?: number
): Promise<any> => {
    try {
        // Guest cart (cartId 0) uses variant-based API
        if (cartId === 0 && variantId !== undefined) {
            const response = await axios.delete(`${API_BASE_URL}/cart/guest/item/${variantId}`);
            return response.data;
        }
        const url = isKiosk
            ? `${API_BASE_URL}/cart/kiosk/item/${cartId}`
            : `${API_BASE_URL}/cart/item/${cartId}`;
        const response = await axios.delete(url);
        return response.data;
    } catch (error) {
        console.error('Remove from Cart Error:', error);
        throw error;
    }
};

export const clearCart = async (
    customerId?: number,
    sessionId?: string
): Promise<any> => {
    try {
        const url = customerId
            ? `${API_BASE_URL}/cart/${customerId}/clear`
            : `${API_BASE_URL}/cart/kiosk/${sessionId}/clear`;
        const response = await axios.delete(url);
        return response.data;
    } catch (error) {
        console.error('Clear Cart Error:', error);
        throw error;
    }
};

export const confirmVariant = async (request: VariantConfirmationRequest): Promise<VariantConfirmationResponse> => {
    try {
        const response = await axios.post<VariantConfirmationResponse>(`${API_BASE_URL}/ai/variant-confirm`, request);
        return response.data;
    } catch (error) {
        console.error('Confirm Variant Error:', error);
        throw error;
    }
};
