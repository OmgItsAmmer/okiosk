export interface Product {
    product_id: number;
    name: string;
    description: string | null;
    price_range: string;
    base_price: string;
    sale_price: string;
    category_id: number | null;
    ispopular: boolean;
    stock_quantity: number;
    created_at: string | null;
    brandID: number | null;
    alert_stock: number | null;
    isVisible: boolean;
    tag: string | null;
    image_url: string | null;
}

export interface Category {
    category_id: number;
    category_name: string;
    isFeatured: boolean | null;
    created_at: string | null;
    product_count: number | null;
}

export interface ProductListResponse {
    products: Product[];
    total_count: number | null;
    fetched_count: number;
    offset: number | null;
    has_more: boolean;
}

export interface CategoryListResponse {
    categories: Category[];
    total_count: number;
    status: string;
}

export interface ProductVariation {
    variant_id: number;
    sell_price: string;
    buy_price: string;
    product_id: number;
    variant_name: string;
    stock: number;
    is_visible: boolean;
}
