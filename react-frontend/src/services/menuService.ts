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
};

export const fetchProductVariants = async (productId: number): Promise<ProductVariation[]> => {
    const response = await fetch(`${API_BASE_URL}/api/products/${productId}/variations`);
    if (!response.ok) {
        throw new Error('Failed to fetch product variants');
    }
    return response.json();
};
