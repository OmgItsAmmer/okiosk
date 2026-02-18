import type { CategoryListResponse, ProductListResponse, ProductVariation } from '../types/menu';
import { API_BASE_URL } from '../config';

export const fetchAllCategories = async (): Promise<CategoryListResponse> => {
    const response = await fetch(`${API_BASE_URL}/api/categories/all`);
    if (!response.ok) {
        throw new Error('Failed to fetch categories');
    }
    return response.json();
};

export const fetchAllProducts = async (): Promise<ProductListResponse> => {
    const response = await fetch(`${API_BASE_URL}/api/products/pos/all`);
    if (!response.ok) {
        throw new Error('Failed to fetch products');
    }
    return response.json();
    return response.json();
};

export const fetchProductVariants = async (productId: number): Promise<ProductVariation[]> => {
    // Try V1 endpoint first as it's the standard
    const response = await fetch(`${API_BASE_URL}/api/v1/products/${productId}/variants`);

    if (!response.ok) {
        // Fallback to legacy if V1 fails
        const legacyResponse = await fetch(`${API_BASE_URL}/api/products/${productId}/variations`);
        if (!legacyResponse.ok) {
            throw new Error('Failed to fetch product variants');
        }
        return legacyResponse.json();
    }
    return response.json();
};
