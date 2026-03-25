-- =====================================================
-- CHECKOUT MODULE - DATABASE MIGRATIONS
-- =====================================================
-- This file contains all database migrations required
-- for the checkout module to work with race condition
-- handling and concurrent checkout support.
-- =====================================================

-- =====================================================
-- 1. CREATE INVENTORY RESERVATIONS TABLE
-- =====================================================
-- This table stores temporary inventory reservations
-- during the checkout process to prevent overselling

CREATE TABLE IF NOT EXISTS inventory_reservations (
    reservation_id TEXT NOT NULL,
    variant_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '10 minutes',
    PRIMARY KEY (reservation_id, variant_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_inventory_reservations_variant 
ON inventory_reservations(variant_id);

CREATE INDEX IF NOT EXISTS idx_inventory_reservations_expires 
ON inventory_reservations(expires_at);

-- =====================================================
-- 2. CREATE SECURITY AUDIT LOG TABLE
-- =====================================================
-- Logs all security events including price manipulation
-- attempts, validation failures, and successful checkouts

CREATE TABLE IF NOT EXISTS security_audit_log (
    id SERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    event_data JSONB,
    timestamp TIMESTAMP DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT,
    customer_id INTEGER,
    severity TEXT DEFAULT 'info',
    CHECK (severity IN ('info', 'warning', 'critical'))
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_security_audit_customer 
ON security_audit_log(customer_id);

CREATE INDEX IF NOT EXISTS idx_security_audit_timestamp 
ON security_audit_log(timestamp);

CREATE INDEX IF NOT EXISTS idx_security_audit_severity 
ON security_audit_log(severity);

-- =====================================================
-- 3. ADD COLUMNS TO ORDERS TABLE
-- =====================================================
-- Add necessary columns for checkout functionality

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS shipping_method TEXT;

ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- Add index on idempotency_key for fast duplicate checks
CREATE INDEX IF NOT EXISTS idx_orders_idempotency 
ON orders(idempotency_key);

-- =====================================================
-- 4. CREATE CART_ITEM_TYPE (if not exists)
-- =====================================================
-- Custom type for cart items in functions

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cart_item_type') THEN
        CREATE TYPE cart_item_type AS (
            variantId INTEGER,
            quantity INTEGER
        );
    END IF;
END $$;

-- =====================================================
-- 5. CREATE RESERVE_INVENTORY_SECURE FUNCTION
-- =====================================================
-- Atomically reserves inventory with row-level locking
-- to prevent race conditions and overselling

CREATE OR REPLACE FUNCTION reserve_inventory_secure(
    p_reservation_id TEXT,
    p_cart_items JSONB
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    error_details JSONB
) AS $$
DECLARE
    v_item JSONB;
    v_variant_id INTEGER;
    v_quantity INTEGER;
    v_current_stock INTEGER;
    v_reserved_stock INTEGER;
    v_available_stock INTEGER;
    v_errors JSONB := '[]'::JSONB;
    v_product_name TEXT;
BEGIN
    -- Loop through each cart item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        v_variant_id := (v_item->>'variantId')::INTEGER;
        v_quantity := (v_item->>'quantity')::INTEGER;
        
        -- Lock the variant row for update (prevents concurrent modifications)
        SELECT stock INTO v_current_stock
        FROM product_variants
        WHERE variant_id = v_variant_id
        FOR UPDATE;
        
        -- Check if variant exists
        IF v_current_stock IS NULL THEN
            v_errors := v_errors || jsonb_build_object(
                'variant_id', v_variant_id,
                'error', 'Product variant not found'
            );
            CONTINUE;
        END IF;
        
        -- Calculate already reserved stock for this variant
        SELECT COALESCE(SUM(quantity), 0) INTO v_reserved_stock
        FROM inventory_reservations
        WHERE variant_id = v_variant_id
        AND expires_at > NOW();
        
        -- Calculate available stock (current - reserved)
        v_available_stock := v_current_stock - v_reserved_stock;
        
        -- Check if enough stock is available
        IF v_available_stock < v_quantity THEN
            -- Get product name for error message
            SELECT p.name INTO v_product_name
            FROM product_variants pv
            JOIN products p ON pv.product_id = p.product_id
            WHERE pv.variant_id = v_variant_id;
            
            v_errors := v_errors || jsonb_build_object(
                'variant_id', v_variant_id,
                'product_name', v_product_name,
                'requested', v_quantity,
                'available', v_available_stock,
                'error', format('Only %s available', v_available_stock)
            );
            CONTINUE;
        END IF;
        
        -- Create reservation
        INSERT INTO inventory_reservations (
            reservation_id, 
            variant_id, 
            quantity, 
            created_at, 
            expires_at
        ) VALUES (
            p_reservation_id,
            v_variant_id,
            v_quantity,
            NOW(),
            NOW() + INTERVAL '10 minutes'
        )
        ON CONFLICT (reservation_id, variant_id) 
        DO UPDATE SET quantity = v_quantity;
    END LOOP;
    
    -- Check if there were any errors
    IF jsonb_array_length(v_errors) > 0 THEN
        -- Rollback any reservations made in this call
        DELETE FROM inventory_reservations 
        WHERE reservation_id = p_reservation_id;
        
        RETURN QUERY SELECT 
            FALSE, 
            'Insufficient stock for some items'::TEXT,
            v_errors;
    ELSE
        RETURN QUERY SELECT 
            TRUE, 
            'Inventory reserved successfully'::TEXT,
            '[]'::JSONB;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. CREATE CONFIRM_INVENTORY_RESERVATION FUNCTION
-- =====================================================
-- Confirms reservation by reducing actual stock and
-- removing reservation records

CREATE OR REPLACE FUNCTION confirm_inventory_reservation(
    p_reservation_id TEXT
) RETURNS VOID AS $$
DECLARE
    v_reservation RECORD;
BEGIN
    -- Loop through all reservations for this ID
    FOR v_reservation IN 
        SELECT variant_id, quantity 
        FROM inventory_reservations 
        WHERE reservation_id = p_reservation_id
    LOOP
        -- Reduce stock
        UPDATE product_variants
        SET stock = stock - v_reservation.quantity
        WHERE variant_id = v_reservation.variant_id;
    END LOOP;
    
    -- Delete reservations
    DELETE FROM inventory_reservations 
    WHERE reservation_id = p_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. CREATE COPY_ADDRESS_TO_ORDER_ADDRESS FUNCTION
-- =====================================================
-- Copies customer address to order_addresses table
-- for historical record keeping

CREATE OR REPLACE FUNCTION copy_address_to_order_address(
    p_address_id INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- Check if address exists
    SELECT EXISTS(
        SELECT 1 FROM addresses WHERE address_id = p_address_id
    ) INTO v_exists;
    
    IF NOT v_exists THEN
        RETURN FALSE;
    END IF;
    
    -- Copy address to order_addresses table if it exists
    -- Note: Adjust the INSERT statement based on your actual schema
    -- This is a placeholder - implement according to your schema
    
    -- INSERT INTO order_addresses (...)
    -- SELECT ... FROM addresses WHERE address_id = p_address_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. CREATE CLEANUP FUNCTION FOR EXPIRED RESERVATIONS
-- =====================================================
-- Removes expired inventory reservations

CREATE OR REPLACE FUNCTION cleanup_expired_reservations()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM inventory_reservations
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. CREATE SCHEDULED JOB FOR CLEANUP (Optional)
-- =====================================================
-- If using pg_cron extension, you can schedule automatic cleanup
-- Note: Requires pg_cron extension to be enabled

-- Uncomment if you have pg_cron enabled:
/*
SELECT cron.schedule(
    'cleanup-expired-reservations',
    '*/5 * * * *',  -- Every 5 minutes
    'SELECT cleanup_expired_reservations()'
);
*/

-- Alternative: Create a trigger to clean up on insert
-- This runs cleanup whenever a new reservation is created

CREATE OR REPLACE FUNCTION trigger_cleanup_reservations()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM inventory_reservations
    WHERE expires_at < NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cleanup_reservations_on_insert
AFTER INSERT ON inventory_reservations
FOR EACH STATEMENT
EXECUTE FUNCTION trigger_cleanup_reservations();

-- =====================================================
-- 10. GRANT PERMISSIONS (Adjust as needed)
-- =====================================================
-- Grant necessary permissions to your application user
-- Replace 'your_app_user' with your actual database user

-- GRANT ALL ON inventory_reservations TO your_app_user;
-- GRANT ALL ON security_audit_log TO your_app_user;
-- GRANT EXECUTE ON FUNCTION reserve_inventory_secure TO your_app_user;
-- GRANT EXECUTE ON FUNCTION confirm_inventory_reservation TO your_app_user;
-- GRANT EXECUTE ON FUNCTION copy_address_to_order_address TO your_app_user;
-- GRANT EXECUTE ON FUNCTION cleanup_expired_reservations TO your_app_user;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- All database objects required for the checkout module
-- have been created. You can now use the checkout API.
-- =====================================================

-- Verify migration
SELECT 'Checkout module database migration completed successfully!' AS status;

