-- Account Book Table
CREATE TABLE public.account_book (
    account_book_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_date date NOT NULL,
    reference character varying,
    amount numeric NOT NULL,
    entity_id bigint NOT NULL,
    description text NOT NULL,
    entity_type character varying NOT NULL,
    entity_name character varying NOT NULL,
    transaction_type character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- Account Book Summary Table
CREATE TABLE public.account_book_summary (
    latest_transaction date,
    max_amount numeric,
    min_amount numeric,
    average_amount numeric,
    total_amount numeric,
    transaction_count bigint,
    entity_type character varying,
    transaction_type character varying,
    earliest_transaction date
);

-- Addresses Table
CREATE TABLE public.addresses (
    address_id integer PRIMARY KEY,
    latitude numeric,
    longitude numeric,
    user_id integer,
    salesman_id integer,
    vendor_id integer,
    customer_id integer,
    shipping_address text DEFAULT ''::text,
    phone_number text DEFAULT ''::text,
    postal_code text DEFAULT ''::text,
    city text DEFAULT ''::text,
    country text DEFAULT ''::text,
    full_name text NOT NULL,
    place_id text,
    formatted_address text
);

-- App Versions Table
CREATE TABLE public.app_versions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    version text NOT NULL,
    app_locked boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    force_update boolean DEFAULT false NOT NULL,
    redirect_url text NOT NULL,
    description text
);

-- Brands Table
CREATE TABLE public.brands (
    brandID integer PRIMARY KEY,
    product_count bigint DEFAULT '0'::bigint NOT NULL,
    isVerified boolean DEFAULT false,
    isFeatured boolean,
    brandname text
);

-- Cart Table
CREATE TABLE public.cart (
    cart_id integer PRIMARY KEY,
    quantity text DEFAULT ''::text NOT NULL,
    customer_id integer,
    variant_id integer
);

-- Categories Table
CREATE TABLE public.categories (
    category_id integer PRIMARY KEY,
    isFeatured boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    category_name text NOT NULL,
    product_count integer
);

-- Collection Cart Table
CREATE TABLE public.collection_cart (
    collection_cart_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collection_id integer NOT NULL,
    customer_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Collection Cart Items Table
CREATE TABLE public.collection_cart_items (
    collection_cart_item_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    variant_id integer NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    collection_cart_id integer NOT NULL
);

-- Collection Items Table
CREATE TABLE public.collection_items (
    collection_item_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    collection_id integer NOT NULL,
    variant_id integer NOT NULL,
    default_quantity integer DEFAULT 1 NOT NULL,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

-- Collection Items Detail Table
CREATE TABLE public.collection_items_detail (
    sell_price numeric,
    product_name text,
    sku character varying,
    image_url text,
    variant_name text,
    product_description text,
    collection_item_id integer,
    collection_id integer,
    variant_id integer,
    default_quantity integer,
    sort_order integer,
    product_id integer,
    stock integer,
    is_visible boolean,
    featured_image_id integer
);

-- Collections Table
CREATE TABLE public.collections (
    collection_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    is_featured boolean DEFAULT false,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_premium boolean DEFAULT false,
    image_url text
);

-- Collections Summary Table
CREATE TABLE public.collections_summary (
    collection_id integer,
    description text,
    name text,
    image_url text,
    is_active boolean,
    is_featured boolean,
    is_premium boolean,
    item_count bigint,
    updated_at timestamp with time zone,
    created_at timestamp with time zone,
    display_order integer,
    total_price numeric
);

-- Customer Public Info Table
CREATE TABLE public.customer_public_info (
    customer_id integer,
    last_name text,
    first_name text
);

-- Customers Table
CREATE TABLE public.customers (
    customer_id integer PRIMARY KEY,
    auth_uid character varying DEFAULT auth.uid(),
    email text DEFAULT ''::text NOT NULL,
    cnic text DEFAULT ''::text,
    last_name text DEFAULT ''::text,
    phone_number text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    first_name text DEFAULT ''::text NOT NULL,
    dob timestamp with time zone,
    gender text,
    fcm_token text,
    token_version integer DEFAULT 0
);

-- Expenses Table
CREATE TABLE public.expenses (
    expense_id integer PRIMARY KEY,
    description text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    amount numeric DEFAULT 0.0
);

-- Extras Table
CREATE TABLE public.extras (
    extraId bigint PRIMARY KEY,
    AdminKey text
);

-- Guarantors Table
CREATE TABLE public.guarantors (
    guarantor_id integer PRIMARY KEY,
    cnic text DEFAULT ''::text NOT NULL,
    pfp text,
    first_name text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    last_name text DEFAULT ''::text,
    phone_number text DEFAULT ''::text,
    address text
);

-- Image Entity Table
CREATE TABLE public.image_entity (
    image_entity_id integer PRIMARY KEY,
    updated_at timestamp with time zone DEFAULT now(),
    entity_category text,
    image_id integer,
    entity_id integer,
    isFeatured boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Images Table
CREATE TABLE public.images (
    image_id integer PRIMARY KEY,
    folderType text,
    filename text,
    image_url text,
    created_at timestamp with time zone DEFAULT now()
);

-- Installment Payments Table
CREATE TABLE public.installment_payments (
    sequence_no integer NOT NULL,
    installment_plan_id integer NOT NULL,
    is_paid boolean DEFAULT false,
    paid_date timestamp with time zone,
    due_date timestamp with time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    paid_amount text,
    status text,
    amount_due text NOT NULL,
    PRIMARY KEY (installment_plan_id, sequence_no)
);

-- Installment Plans Table
CREATE TABLE public.installment_plans (
    installment_plans_id integer PRIMARY KEY,
    note text,
    total_amount text NOT NULL,
    status text DEFAULT 'active'::text,
    document_charges text,
    number_of_installments text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    order_id integer NOT NULL,
    guarantor1_id integer,
    down_payment text NOT NULL,
    margin text,
    first_installment_date timestamp with time zone,
    frequency_in_month text,
    other_charges text,
    duration text,
    guarantor2_id integer
);

-- Inventory Reservations Table
CREATE TABLE public.inventory_reservations (
    reservation_id character varying PRIMARY KEY,
    variant_id integer NOT NULL,
    quantity integer NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- Inventory Status Table
CREATE TABLE public.inventory_status (
    variant_id integer,
    product_name text,
    reserved_quantity bigint,
    sell_price numeric,
    total_stock integer,
    available_stock bigint,
    variant_name text
);

-- Invoice Coupons Table
CREATE TABLE public.invoice_coupons (
    coupon_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    discount_type text NOT NULL,
    coupon_code text NOT NULL,
    title text NOT NULL,
    amount numeric NOT NULL,
    usage_limit integer,
    used_count integer DEFAULT 0 NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);

-- Kiosk Cart Table
CREATE TABLE public.kiosk_cart (
    kiosk_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at timestamp without time zone DEFAULT now(),
    quantity integer NOT NULL,
    variant_id integer NOT NULL,
    kiosk_session_id uuid NOT NULL
);

-- Monthly Account Summary Table
CREATE TABLE public.monthly_account_summary (
    transaction_count bigint,
    transaction_type character varying,
    entity_type character varying,
    month timestamp with time zone,
    total_amount numeric
);

-- Notifications Table
CREATE TABLE public.notifications (
    notification_id integer PRIMARY KEY,
    product_id integer,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    isRead boolean DEFAULT false,
    expires_at timestamp with time zone DEFAULT (now() + '10 days'::interval),
    order_id integer,
    installment_plan_id integer,
    description text,
    sub_description text,
    NotificationType text
);

-- Order Addresses Table
CREATE TABLE public.order_addresses (
    order_address_id integer PRIMARY KEY,
    formatted_address text,
    place_id text,
    user_id integer,
    salesman_id integer,
    country text DEFAULT ''::text,
    city text DEFAULT ''::text,
    vendor_id integer,
    customer_id integer,
    longitude numeric,
    shipping_address text DEFAULT ''::text,
    postal_code text DEFAULT ''::text,
    full_name text NOT NULL,
    phone_number text DEFAULT ''::text,
    latitude numeric,
    address_id integer
);

-- Order Items Table
CREATE TABLE public.order_items (
    order_id integer NOT NULL,
    product_id integer NOT NULL,
    variant_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    unit character varying,
    total_buy_price numeric DEFAULT 0.0,
    quantity integer NOT NULL,
    price numeric NOT NULL,
    PRIMARY KEY (order_id, product_id, variant_id)
);

-- Orders Table
CREATE TABLE public.orders (
    order_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id integer,
    shipping_method text,
    idempotency_key character varying,
    buying_price numeric,
    discount numeric DEFAULT 0.0,
    tax numeric DEFAULT 0.0,
    shipping_fee numeric DEFAULT 0.0,
    customer_id integer,
    payment_method text DEFAULT 'cod',
    salesman_id integer,
    salesman_comission integer,
    sub_total numeric NOT NULL,
    status text NOT NULL,
    address_id integer,
    order_date date NOT NULL,
    paid_amount numeric,
    saletype text
);

-- Product Discounts Table
CREATE TABLE public.product_discounts (
    discount_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id integer NOT NULL,
    end_date timestamp with time zone NOT NULL,
    start_date timestamp with time zone NOT NULL,
    discount_type text NOT NULL,
    amount numeric NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);

-- Product Variants Table
CREATE TABLE public.product_variants (
    variant_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku character varying,
    alert_stock bigint DEFAULT '0'::bigint NOT NULL,
    stock integer DEFAULT 0,
    is_visible boolean DEFAULT true,
    updated_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    sell_price numeric NOT NULL,
    buy_price numeric NOT NULL,
    product_id integer NOT NULL,
    variant_name text NOT NULL
);

-- Products Table
CREATE TABLE public.products (
    product_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tag text,
    description text DEFAULT ''::text,
    name text DEFAULT ''::text NOT NULL,
    base_price text DEFAULT ''::text,
    sale_price text DEFAULT ''::text,
    price_range text DEFAULT '--'::text,
    isVisible boolean DEFAULT false,
    alert_stock integer,
    brandID integer DEFAULT 20,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    stock_quantity integer DEFAULT 0,
    ispopular boolean DEFAULT false,
    category_id integer DEFAULT 11
);

-- Purchase Items Table
CREATE TABLE public.purchase_items (
    purchase_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    unit character varying,
    purchase_id bigint NOT NULL,
    product_id bigint NOT NULL,
    variant_id bigint,
    price numeric NOT NULL,
    quantity integer DEFAULT 1 NOT NULL
);

-- Purchases Table
CREATE TABLE public.purchases (
    purchase_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipping_fee numeric DEFAULT 0.00,
    tax numeric DEFAULT 0.00,
    vendor_id bigint,
    sub_total numeric DEFAULT 0.00 NOT NULL,
    discount numeric DEFAULT 0.00,
    paid_amount numeric DEFAULT 0.00,
    purchase_date date DEFAULT CURRENT_DATE NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    address_id bigint,
    user_id integer,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);

-- Reviews Table
CREATE TABLE public.reviews (
    review_id bigint PRIMARY KEY,
    product_id integer,
    customer_id integer,
    rating numeric,
    review text DEFAULT ''::text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL
);

-- Salesman Table
CREATE TABLE public.salesman (
    salesman_id integer PRIMARY KEY,
    email text DEFAULT ''::text NOT NULL,
    pfp text,
    created_at timestamp with time zone DEFAULT now(),
    comission integer,
    phone_number text DEFAULT ''::text,
    last_name text DEFAULT ''::text,
    cnic text DEFAULT ''::text NOT NULL,
    city text DEFAULT ''::text NOT NULL,
    first_name text DEFAULT ''::text NOT NULL,
    area text DEFAULT ''::text NOT NULL
);

-- Security Audit Log Table
CREATE TABLE public.security_audit_log (
    log_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    timestamp timestamp with time zone DEFAULT now(),
    user_agent text,
    event_type character varying NOT NULL,
    severity character varying DEFAULT 'info'::character varying,
    event_data jsonb,
    customer_id integer,
    ip_address inet
);

-- Security Dashboard Table
CREATE TABLE public.security_dashboard (
    event_type character varying,
    severity character varying,
    unique_customers bigint,
    event_count bigint,
    date date
);

-- Shop Table
CREATE TABLE public.shop (
    shop_id integer PRIMARY KEY,
    max_allowed_item_quantity bigint DEFAULT '50'::bigint NOT NULL,
    software_website_link text,
    software_contact_no text,
    software_company_name text,
    shopname text NOT NULL,
    taxrate numeric NOT NULL,
    shipping_price numeric NOT NULL,
    threshold_free_shipping numeric,
    is_shipping_enable boolean DEFAULT false NOT NULL
);

-- Users Table
CREATE TABLE public.users (
    user_id integer PRIMARY KEY,
    first_name text DEFAULT ''::text NOT NULL,
    gender text,
    created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    dob timestamp with time zone,
    auth_uid character varying,
    email text DEFAULT ''::text NOT NULL,
    phone_number text DEFAULT ''::text,
    last_name text DEFAULT ''::text
);

-- Vendors Table
CREATE TABLE public.vendors (
    vendor_id integer PRIMARY KEY,
    phone_number text DEFAULT ''::text,
    last_name text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    email text DEFAULT ''::text NOT NULL,
    cnic text DEFAULT ''::text,
    first_name text DEFAULT ''::text NOT NULL
);

-- Wishlist Table
CREATE TABLE public.wishlist (
    wishlist_id bigint PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    product_id integer,
    customer_id integer
);