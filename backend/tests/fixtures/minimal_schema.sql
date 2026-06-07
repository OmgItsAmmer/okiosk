-- Minimal schema for CI integration tests (orders table required by health check)
CREATE TABLE IF NOT EXISTS orders (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER,
    shipping_method TEXT,
    idempotency_key VARCHAR,
    buying_price NUMERIC,
    discount NUMERIC DEFAULT 0.0,
    tax NUMERIC DEFAULT 0.0,
    shipping_fee NUMERIC DEFAULT 0.0,
    customer_id INTEGER,
    payment_method TEXT DEFAULT 'cod',
    salesman_id INTEGER,
    salesman_comission INTEGER,
    sub_total NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending',
    address_id INTEGER,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    paid_amount NUMERIC,
    saletype TEXT
);
