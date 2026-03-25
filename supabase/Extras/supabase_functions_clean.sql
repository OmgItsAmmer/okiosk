CREATE OR REPLACE FUNCTION public.http_set_curlopt(curlopt character varying, value character varying) RETURNS boolean
 LANGUAGE c
AS '$libdir/http', $function$http_set_curlopt$function$

CREATE OR REPLACE FUNCTION public.http_reset_curlopt() RETURNS boolean
 LANGUAGE c
AS '$libdir/http', $function$http_reset_curlopt$function$

CREATE OR REPLACE FUNCTION public.http_list_curlopt() RETURNS TABLE(curlopt text, value text)
 LANGUAGE c
AS '$libdir/http', $function$http_list_curlopt$function$

CREATE OR REPLACE FUNCTION public.http_header(field character varying, value character varying) RETURNS http_header
 LANGUAGE sql
AS $function$ SELECT $1, $2 $function$

CREATE OR REPLACE FUNCTION public.http(request http_request) RETURNS http_response
 LANGUAGE c
AS '$libdir/http', $function$http_request$function$

CREATE OR REPLACE FUNCTION public.http_get(uri character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('GET', $1, NULL, NULL, NULL)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_post(uri character varying, content character varying, content_type character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('POST', $1, NULL, $3, $2)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_put(uri character varying, content character varying, content_type character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('PUT', $1, NULL, $3, $2)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_patch(uri character varying, content character varying, content_type character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('PATCH', $1, NULL, $3, $2)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_delete(uri character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('DELETE', $1, NULL, NULL, NULL)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_delete(uri character varying, content character varying, content_type character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('DELETE', $1, NULL, $3, $2)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.http_head(uri character varying) RETURNS http_response
 LANGUAGE sql
AS $function$ SELECT public.http(('HEAD', $1, NULL, NULL, NULL)::public.http_request) $function$

CREATE OR REPLACE FUNCTION public.urlencode(string character varying) RETURNS text
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/http', $function$urlencode$function$

CREATE OR REPLACE FUNCTION public.urlencode(string bytea) RETURNS text
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/http', $function$urlencode$function$

CREATE OR REPLACE FUNCTION public.urlencode(data jsonb) RETURNS text
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/http', $function$urlencode_jsonb$function$

CREATE OR REPLACE FUNCTION public.http_get(uri character varying, data jsonb) RETURNS http_response
 LANGUAGE sql
AS $function$
        SELECT public.http(('GET', $1 || '?' || public.urlencode($2), NULL, NULL, NULL)::public.http_request)
    $function$

CREATE OR REPLACE FUNCTION public.update_collection_timestamp() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.http_post(uri character varying, data jsonb) RETURNS http_response
 LANGUAGE sql
AS $function$
        SELECT public.http(('POST', $1, NULL, 'application/x-www-form-urlencoded', public.urlencode($2))::public.http_request)
    $function$

CREATE OR REPLACE FUNCTION public.text_to_bytea(data text) RETURNS bytea
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/http', $function$text_to_bytea$function$

CREATE OR REPLACE FUNCTION public.bytea_to_text(data bytea) RETURNS text
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/http', $function$bytea_to_text$function$

CREATE OR REPLACE FUNCTION public.validate_admin_cart_stock(p_cart_items jsonb) RETURNS TABLE(is_valid boolean, error_message text, variant_id integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    item JSONB;
    v_variant_stock INTEGER;
    v_quantity INTEGER;
BEGIN
    -- Loop through each cart item (all products must have variants)
    FOR item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        v_quantity := (item->>'quantity')::INTEGER;
        
        -- Check variant stock (every product must have at least one variant)
        SELECT stock INTO v_variant_stock 
        FROM product_variants 
        WHERE variant_id = (item->>'variantId')::INTEGER 
        AND is_visible = true;
        
        IF v_variant_stock IS NULL THEN
            RETURN QUERY SELECT false, 'Product variant not found or not visible', 
                (item->>'variantId')::INTEGER;
            RETURN;
        END IF;
        
        IF v_variant_stock < v_quantity THEN
            RETURN QUERY SELECT false, 
                format('Insufficient stock for variant. Available: %s, Requested: %s', 
                       v_variant_stock, v_quantity),
                (item->>'variantId')::INTEGER;
            RETURN;
        END IF;
    END LOOP;
    
    -- If we get here, all validations passed
    RETURN QUERY SELECT true, 'Stock validation passed'::TEXT, NULL::INTEGER;
END;
$function$

CREATE OR REPLACE FUNCTION public.apply_admin_stock_changes(p_variant_changes jsonb) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    variant_entry RECORD;
BEGIN
    -- Apply variant stock changes (since every product must have variants)
    FOR variant_entry IN 
        SELECT key::INTEGER as variant_id, value::INTEGER as quantity_change
        FROM jsonb_each_text(p_variant_changes)
        WHERE value::INTEGER != 0
    LOOP
        -- For variants reducing stock, use the existing function
        IF variant_entry.quantity_change < 0 THEN
            PERFORM reduce_variant_stock(
                variant_entry.variant_id, 
                ABS(variant_entry.quantity_change)
            );
        ELSE
            -- For increasing stock, update directly
            UPDATE product_variants 
            SET stock = stock + variant_entry.quantity_change,
                updated_at = NOW()
            WHERE variant_id = variant_entry.variant_id;
        END IF;
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.calculate_admin_order_totals(p_cart_items jsonb, p_salesman_comission integer DEFAULT 0, p_discount_percent numeric DEFAULT 0, p_payment_method text DEFAULT 'cash'::text) RETURNS TABLE(subtotal numeric, tax numeric, shipping numeric, salesman_comission integer, discount numeric, total numeric, buying_price_total numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    item JSONB;
    v_subtotal NUMERIC := 0;
    v_buying_price_total NUMERIC := 0;
    v_tax NUMERIC := 0;
    v_shipping NUMERIC := 0;
    v_salesman_comission INTEGER := 0;
    v_discount NUMERIC := 0;
    v_total NUMERIC := 0;
    shop_settings RECORD;
BEGIN
    -- Calculate subtotal and buying price total
    FOR item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        v_subtotal := v_subtotal + ((item->>'sellPrice')::NUMERIC * (item->>'quantity')::NUMERIC);
        
        -- Calculate buying price (all products have variants, so multiply by quantity)
        v_buying_price_total := v_buying_price_total + 
            ((item->>'buyPrice')::NUMERIC * (item->>'quantity')::NUMERIC);
    END LOOP;
    
    -- Get shop settings
    SELECT taxrate, shipping_price INTO shop_settings
    FROM shop
    LIMIT 1;
    
    v_tax := COALESCE(shop_settings.taxrate, 0);
    
    -- For POS orders, shipping is always 0 (customer pickup)
    v_shipping := 0;
    
    -- Calculate salesman commission
    v_salesman_comission := ROUND((v_subtotal * p_salesman_comission) / 100);
    
    -- Calculate discount
    v_discount := (v_subtotal * p_discount_percent) / 100;
    
    -- Apply discount to subtotal
    v_subtotal := v_subtotal - v_discount;
    
    -- Calculate total
    v_total := v_subtotal + v_tax + v_shipping + v_salesman_comission;
    
    RETURN QUERY SELECT v_subtotal, v_tax, v_shipping, v_salesman_comission, 
                        v_discount, v_total, v_buying_price_total;
END;
$function$

CREATE OR REPLACE FUNCTION public.reserve_admin_inventory(p_reservation_id text, p_cart_items jsonb, p_expiry_minutes integer DEFAULT 10) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    item JSONB;
    v_expiry_time TIMESTAMP;
BEGIN
    v_expiry_time := NOW() + INTERVAL '1 minute' * p_expiry_minutes;
    
    -- Clean up any expired reservations first
    DELETE FROM inventory_reservations 
    WHERE expires_at < NOW();
    
    -- Reserve each item in the cart (only variant_id since every product must have variants)
    FOR item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        INSERT INTO inventory_reservations (
            reservation_id,
            variant_id,
            quantity,
            expires_at
        ) VALUES (
            p_reservation_id,
            (item->>'variantId')::INTEGER,
            (item->>'quantity')::INTEGER,
            v_expiry_time
        );
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Clean up any partial reservations
        DELETE FROM inventory_reservations 
        WHERE reservation_id = p_reservation_id;
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.add_to_cart_validation(p_variant_id_input integer, p_new_quantity_input integer) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_customer_id INT;
    v_current_stock INT := 0;
    v_customer_current_quantity INT := 0;
BEGIN
    -- Get customer ID from logged-in user
    SELECT customer_id INTO v_customer_id
    FROM customers
    WHERE auth_uid = auth.uid();

    IF v_customer_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Get stock
    SELECT COALESCE(stock, 0) INTO v_current_stock
    FROM product_variants
    WHERE variant_id = p_variant_id_input;

    IF v_current_stock <= 0 THEN
        RETURN FALSE;
    END IF;

    -- Get total quantity user already added
    SELECT COALESCE(SUM(
        CASE 
            WHEN quantity ~ '^[0-9]+$' THEN quantity::INT 
            ELSE 0 
        END
    ), 0) INTO v_customer_current_quantity
    FROM cart
    WHERE variant_id = p_variant_id_input
      AND customer_id = v_customer_id;

    -- Validate: not exceeding stock
    IF (v_customer_current_quantity + p_new_quantity_input) <= v_current_stock THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$function$

CREATE OR REPLACE FUNCTION public.validate_and_adjust_cart_stock(p_customer_id integer) RETURNS TABLE(cart_id integer, variant_id integer, product_name text, variant_name text, current_quantity integer, available_stock integer, suggested_quantity integer, needs_adjustment boolean, adjustment_reason text, should_remove boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    cart_item RECORD;
    v_available_stock INTEGER;
    v_current_qty INTEGER;
    v_suggested_qty INTEGER;
    v_needs_adjustment BOOLEAN;
    v_adjustment_reason TEXT;
    v_should_remove BOOLEAN;
BEGIN
    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer not found: %', p_customer_id;
    END IF;

    -- Loop through all cart items for this customer
    FOR cart_item IN 
        SELECT 
            c.cart_id,
            c.variant_id,
            c.quantity,
            pv.stock,
            pv.variant_name,
            p.name as product_name,
            pv.is_visible
        FROM cart c
        INNER JOIN product_variants pv ON c.variant_id = pv.variant_id
        INNER JOIN products p ON pv.product_id = p.product_id
        WHERE c.customer_id = p_customer_id
        ORDER BY c.cart_id
    LOOP
        -- Convert quantity to integer (cart stores as text)
        v_current_qty := COALESCE(NULLIF(cart_item.quantity, '')::INTEGER, 0);
        
        -- Get available stock (considering reservations)
        SELECT public.get_available_stock(cart_item.variant_id) INTO v_available_stock;
        
        -- Determine if adjustment is needed
        v_needs_adjustment := FALSE;
        v_should_remove := FALSE;
        v_suggested_qty := v_current_qty;
        v_adjustment_reason := '';
        
        -- Check if variant is still visible/available
        IF NOT cart_item.is_visible THEN
            v_should_remove := TRUE;
            v_needs_adjustment := TRUE;
            v_suggested_qty := 0;
            v_adjustment_reason := 'Product no longer available';
        
        -- Check if no stock available
        ELSIF v_available_stock <= 0 THEN
            v_should_remove := TRUE;
            v_needs_adjustment := TRUE;
            v_suggested_qty := 0;
            v_adjustment_reason := 'Out of stock';
        
        -- Check if requested quantity exceeds available stock
        ELSIF v_current_qty > v_available_stock THEN
            v_needs_adjustment := TRUE;
            v_suggested_qty := v_available_stock;
            v_adjustment_reason := format('Only %s items available', v_available_stock);
        
        -- Check for invalid quantities
        ELSIF v_current_qty <= 0 THEN
            v_should_remove := TRUE;
            v_needs_adjustment := TRUE;
            v_suggested_qty := 0;
            v_adjustment_reason := 'Invalid quantity';
        END IF;
        
        -- Return the validation result
        RETURN QUERY SELECT 
            cart_item.cart_id,
            cart_item.variant_id,
            cart_item.product_name,
            cart_item.variant_name,
            v_current_qty,
            v_available_stock,
            v_suggested_qty,
            v_needs_adjustment,
            v_adjustment_reason,
            v_should_remove;
            
    END LOOP;
    
    RETURN;
END;
$function$

CREATE OR REPLACE FUNCTION public.apply_cart_adjustments(p_customer_id integer, p_adjustments jsonb) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    adjustment_item JSONB;
    v_cart_id INTEGER;
    v_suggested_qty INTEGER;
    v_should_remove BOOLEAN;
BEGIN
    -- Validate customer exists
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer not found: %', p_customer_id;
    END IF;
    
    -- Process each adjustment
    FOR adjustment_item IN SELECT * FROM jsonb_array_elements(p_adjustments)
    LOOP
        v_cart_id := (adjustment_item->>'cart_id')::INTEGER;
        v_suggested_qty := (adjustment_item->>'suggested_quantity')::INTEGER;
        v_should_remove := (adjustment_item->>'should_remove')::BOOLEAN;
        
        -- Verify the cart item belongs to this customer
        IF NOT EXISTS (
            SELECT 1 FROM cart 
            WHERE cart_id = v_cart_id AND customer_id = p_customer_id
        ) THEN
            CONTINUE; -- Skip unauthorized items
        END IF;
        
        -- Apply the adjustment
        IF v_should_remove OR v_suggested_qty <= 0 THEN
            -- Remove the item
            DELETE FROM cart WHERE cart_id = v_cart_id;
        ELSE
            -- Update the quantity
            UPDATE cart 
            SET quantity = v_suggested_qty::TEXT
            WHERE cart_id = v_cart_id;
        END IF;
    END LOOP;
    
    -- Log the adjustment for audit purposes
    INSERT INTO security_audit_log (event_type, event_data, severity)
    VALUES (
        'cart_stock_adjustment',
        jsonb_build_object(
            'customer_id', p_customer_id,
            'adjustments', p_adjustments,
            'timestamp', NOW()
        ),
        'info'
    );
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.get_available_stock(variant_id_param integer) RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    total_stock BIGINT;
    reserved_stock BIGINT;
BEGIN
    SELECT stock INTO total_stock 
    FROM product_variants 
    WHERE variant_id = variant_id_param;

    RAISE NOTICE 'Total stock: %', total_stock;

    IF total_stock IS NULL THEN
        RETURN 0;
    END IF;

    SELECT COALESCE(SUM(quantity), 0) INTO reserved_stock
    FROM inventory_reservations 
    WHERE variant_id = variant_id_param 
    AND expires_at > NOW();

    RAISE NOTICE 'Reserved stock: %', reserved_stock;

    RETURN GREATEST(0, total_stock - reserved_stock);
END;
$function$

CREATE OR REPLACE FUNCTION public.reserve_inventory_secure(p_reservation_id character varying, p_cart_items jsonb) RETURNS TABLE(success boolean, message text, error_details jsonb)
 LANGUAGE plpgsql
AS $function$
DECLARE
    item jsonb;
    v_variant_id integer;
    v_quantity integer;
    v_total_stock integer;
    v_reserved_stock integer;
    v_available_stock integer;
    v_expires_at timestamp;
    v_error_details jsonb := '[]'::jsonb;
    v_product_name text;
BEGIN
    -- Set expiration time (5 minutes from now)
    v_expires_at := NOW() + INTERVAL '5 minutes';
    
    -- Clean up expired reservations first
    DELETE FROM inventory_reservations WHERE expires_at < NOW();
    
    -- Process each cart item with atomic stock checking
    FOR item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        v_variant_id := (item->>'variantId')::integer;
        v_quantity := (item->>'quantity')::integer;
        
        -- Lock the variant row and get current stock + product name
        SELECT pv.stock, p.name INTO v_total_stock, v_product_name
        FROM product_variants pv
        INNER JOIN products p ON pv.product_id = p.product_id
        WHERE pv.variant_id = v_variant_id
        FOR UPDATE; -- Critical: This locks the row to prevent race conditions
        
        IF v_total_stock IS NULL THEN
            v_error_details := v_error_details || jsonb_build_object(
                'variantId', v_variant_id,
                'error', 'Product variant not found',
                'requestedQuantity', v_quantity
            );
            CONTINUE;
        END IF;
        
        -- Get currently reserved stock for this variant (within the same transaction)
        SELECT COALESCE(SUM(quantity), 0) INTO v_reserved_stock
        FROM inventory_reservations
        WHERE variant_id = v_variant_id AND expires_at > NOW();
        
        -- Calculate available stock
        v_available_stock := v_total_stock - v_reserved_stock;
        
        -- Check if enough stock is available
        IF v_available_stock < v_quantity THEN
            v_error_details := v_error_details || jsonb_build_object(
                'variantId', v_variant_id,
                'productName', v_product_name,
                'error', format('%s - Only %s available', v_product_name, v_available_stock),
                'requestedQuantity', v_quantity,
                'availableStock', v_available_stock,
                'totalStock', v_total_stock,
                'reservedStock', v_reserved_stock
            );
        ELSE
            -- Reserve the stock (only if available)
            INSERT INTO inventory_reservations (
                reservation_id,
                variant_id,
                quantity,
                expires_at
            ) VALUES (
                p_reservation_id,
                v_variant_id,
                v_quantity,
                v_expires_at
            );
        END IF;
    END LOOP;
    
    -- If any items had errors, rollback ALL reservations for this reservation_id
    IF jsonb_array_length(v_error_details) > 0 THEN
        DELETE FROM inventory_reservations WHERE reservation_id = p_reservation_id;
        RETURN QUERY SELECT false, 'Insufficient stock for some items', v_error_details;
        RETURN;
    END IF;
    
    -- Log successful reservation
    INSERT INTO security_audit_log (event_type, event_data, severity)
    VALUES ('inventory_reserved', 
            jsonb_build_object(
                'reservation_id', p_reservation_id,
                'items_count', jsonb_array_length(p_cart_items)
            ), 
            'info');
    
    RETURN QUERY SELECT true, 'All items reserved successfully', '[]'::jsonb;
END;
$function$

CREATE OR REPLACE FUNCTION public.handle_order_ready() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  service_url TEXT := 'https://your-endpoint.com/your-path';  -- Replace with actual target URL
  service_key TEXT := 'Bearer YOUR_SERVICE_KEY_HERE';         -- Replace with your actual auth key if needed
BEGIN
  IF NEW.status = 'ready' THEN
    PERFORM http_post(
      service_url,
      json_build_object(
        'order_id', NEW.order_id,
        'customer_id', NEW.customer_id
      )::TEXT,
      ARRAY[
        http_header('Content-Type', 'application/json'),
        http_header('Authorization', service_key)
      ]
    );
  END IF;
  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.delete_customer_by_auth_uid(uid uuid) RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Delete from customers table where auth_uid matches
  DELETE FROM public.customers WHERE auth_uid = uid;
  
  -- You can add additional cleanup here if needed
  -- For example, delete related records from other tables
  
  -- Note: This function only deletes from the customers table
  -- The actual user deletion from Supabase Auth must be done via Admin API
END;
$function$

CREATE OR REPLACE FUNCTION public.set_updated_at_image_entity_table() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$

CREATE OR REPLACE FUNCTION public.apply_admin_stock_changes(p_product_changes jsonb, p_variant_changes jsonb) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    product_entry RECORD;
    variant_entry RECORD;
    v_current_stock INTEGER;
BEGIN
    -- Apply product stock changes
    FOR product_entry IN 
        SELECT key::INTEGER as product_id, value::INTEGER as quantity_change
        FROM jsonb_each_text(p_product_changes)
        WHERE value::INTEGER != 0
    LOOP
        -- Lock the row and get current stock
        SELECT stock_quantity INTO v_current_stock
        FROM products
        WHERE product_id = product_entry.product_id
        FOR UPDATE;
        
        -- Check if we have enough stock (only when reducing stock)
        IF product_entry.quantity_change < 0 AND 
           v_current_stock < ABS(product_entry.quantity_change) THEN
            RAISE EXCEPTION 'Insufficient product stock. Product ID: %, Available: %, Requested: %', 
                product_entry.product_id, v_current_stock, ABS(product_entry.quantity_change);
        END IF;
        
        -- Apply the change
        UPDATE products 
        SET stock_quantity = stock_quantity + product_entry.quantity_change,
            updated_at = NOW()
        WHERE product_id = product_entry.product_id;
    END LOOP;
    
    -- Apply variant stock changes
    FOR variant_entry IN 
        SELECT key::INTEGER as variant_id, value::INTEGER as quantity_change
        FROM jsonb_each_text(p_variant_changes)
        WHERE value::INTEGER != 0
    LOOP
        -- For variants reducing stock, use the existing function
        IF variant_entry.quantity_change < 0 THEN
            PERFORM reduce_variant_stock(
                variant_entry.variant_id, 
                ABS(variant_entry.quantity_change)
            );
        ELSE
            -- For increasing stock, update directly
            UPDATE product_variants 
            SET stock = stock + variant_entry.quantity_change,
                updated_at = NOW()
            WHERE variant_id = variant_entry.variant_id;
        END IF;
    END LOOP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.get_available_stock_for_admin(p_product_id integer, p_variant_id integer DEFAULT NULL::integer) RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_stock INTEGER;
    v_reserved_stock INTEGER := 0;
BEGIN
    -- Clean up expired reservations first
    DELETE FROM inventory_reservations WHERE expires_at < NOW();
    
    IF p_variant_id IS NOT NULL THEN
        -- Get variant stock
        SELECT stock INTO v_total_stock
        FROM product_variants
        WHERE variant_id = p_variant_id AND is_visible = true;
        
        -- Get reserved stock for this variant
        SELECT COALESCE(SUM(quantity), 0) INTO v_reserved_stock
        FROM inventory_reservations
        WHERE variant_id = p_variant_id AND expires_at > NOW();
    ELSE
        -- Get product stock
        SELECT stock_quantity INTO v_total_stock
        FROM products
        WHERE product_id = p_product_id;
        
        -- Get reserved stock for this product (non-variant reservations)
        SELECT COALESCE(SUM(quantity), 0) INTO v_reserved_stock
        FROM inventory_reservations
        WHERE product_id = p_product_id AND variant_id IS NULL AND expires_at > NOW();
    END IF;
    
    RETURN GREATEST(0, COALESCE(v_total_stock, 0) - v_reserved_stock);
END;
$function$

CREATE OR REPLACE FUNCTION public.update_admin_order_comprehensive(p_order_id integer, p_order_data jsonb, p_order_items jsonb) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_order_exists BOOLEAN := FALSE;
BEGIN
    -- Check if order exists
    SELECT EXISTS(SELECT 1 FROM orders WHERE order_id = p_order_id) INTO v_order_exists;
    
    IF NOT v_order_exists THEN
        RAISE EXCEPTION 'Order with ID % does not exist', p_order_id;
    END IF;
    
    -- Update the order
    UPDATE orders SET
        order_date = COALESCE((p_order_data->>'order_date')::DATE, order_date), -- DATE type, not TIMESTAMP
        sub_total = COALESCE((p_order_data->>'sub_total')::NUMERIC, sub_total),
        buying_price = COALESCE((p_order_data->>'buying_price')::NUMERIC, buying_price),
        status = COALESCE(p_order_data->>'status', status),
        saletype = COALESCE(p_order_data->>'saletype', saletype),
        address_id = COALESCE((p_order_data->>'address_id')::INTEGER, address_id),
        customer_id = COALESCE((p_order_data->>'customer_id')::INTEGER, customer_id),
        paid_amount = COALESCE((p_order_data->>'paid_amount')::NUMERIC, paid_amount),
        discount = COALESCE((p_order_data->>'discount')::NUMERIC, discount),
        tax = COALESCE((p_order_data->>'tax')::NUMERIC, tax),
        shipping_fee = COALESCE((p_order_data->>'shipping_fee')::NUMERIC, shipping_fee),
        salesman_comission = COALESCE((p_order_data->>'salesman_comission')::INTEGER, salesman_comission), -- INTEGER type
        payment_method = COALESCE(p_order_data->>'payment_method', payment_method),
        salesman_id = COALESCE((p_order_data->>'salesman_id')::INTEGER, salesman_id)
    WHERE order_id = p_order_id;
    
    -- Delete existing order items
    DELETE FROM order_items WHERE order_id = p_order_id;
    
    -- Insert new order items
    INSERT INTO order_items (
        order_id,
        product_id,
        quantity,
        price,
        unit,
        total_buy_price,
        variant_id
    )
    SELECT 
        p_order_id,
        (item->>'product_id')::INTEGER,
        (item->>'quantity')::INTEGER,
        (item->>'price')::NUMERIC,
        item->>'unit',
        (item->>'total_buy_price')::NUMERIC,
        (item->>'variant_id')::INTEGER -- Required since every product must have variants
    FROM jsonb_array_elements(p_order_items) item;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.transfer_cart_to_kiosk(p_customer_id integer, p_kiosk_session_id uuid) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_cart_count INTEGER;
    v_transferred_count INTEGER;
BEGIN
    -- Validate input parameters
    IF p_customer_id IS NULL OR p_customer_id <= 0 THEN
        RAISE EXCEPTION 'Invalid customer_id: %', p_customer_id;
    END IF;
    
    IF p_kiosk_session_id IS NULL THEN
        RAISE EXCEPTION 'Invalid kiosk_session_id: %', p_kiosk_session_id;
    END IF;
    
    -- Check if customer has any cart items
    SELECT COUNT(*)
    INTO v_cart_count
    FROM cart
    WHERE customer_id = p_customer_id;
    
    IF v_cart_count = 0 THEN
        RAISE EXCEPTION 'No cart items found for customer_id: %', p_customer_id;
    END IF;
    
    -- Clear any existing kiosk cart items for this session (in case of retry)
    DELETE FROM kiosk_cart
    WHERE kiosk_session_id = p_kiosk_session_id;
    
    -- Transfer cart items to kiosk_cart
    INSERT INTO kiosk_cart (
        kiosk_session_id,
        variant_id,
        quantity,
        created_at
    )
    SELECT 
        p_kiosk_session_id,
        c.variant_id,
        CAST(c.quantity AS INTEGER), -- Convert text quantity to integer
        NOW()
    FROM cart c
    WHERE c.customer_id = p_customer_id
      AND c.variant_id IS NOT NULL
      AND c.quantity ~ '^\d+$' -- Ensure quantity is numeric
      AND CAST(c.quantity AS INTEGER) > 0; -- Ensure quantity is positive
    
    -- Get count of transferred items
    GET DIAGNOSTICS v_transferred_count = ROW_COUNT;
    
    -- Verify transfer was successful
    IF v_transferred_count = 0 THEN
        RAISE EXCEPTION 'Failed to transfer cart items for customer_id: %', p_customer_id;
    END IF;
    
    -- Log the transfer (optional, for audit purposes)
    RAISE NOTICE 'Successfully transferred % cart items from customer_id % to kiosk_session_id %', 
                  v_transferred_count, p_customer_id, p_kiosk_session_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error
        RAISE NOTICE 'Error in transfer_cart_to_kiosk: %', SQLERRM;
        RETURN FALSE;
END;
$function$

CREATE OR REPLACE FUNCTION public.insert_customer(p_phone_number text DEFAULT ''::text, p_first_name text DEFAULT ''::text, p_last_name text DEFAULT ''::text, p_cnic text DEFAULT ''::text, p_email text DEFAULT ''::text, p_dob timestamp with time zone DEFAULT NULL::timestamp with time zone, p_gender gender DEFAULT NULL::gender, p_auth_uid uuid DEFAULT auth.uid(), p_fcm_token text DEFAULT NULL::text) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_success BOOLEAN := FALSE;
BEGIN
  -- Insert customer data
  INSERT INTO public.customers (
    phone_number,
    first_name,
    last_name,
    cnic,
    email,
    dob,
    gender,
    auth_uid,
    fcm_token
  ) VALUES (
    p_phone_number,
    p_first_name,
    p_last_name,
    p_cnic,
    p_email,
    p_dob,
    p_gender,
    p_auth_uid,
    p_fcm_token
  );
  
  -- If we reach here, insert was successful
  v_success := TRUE;
  
  RETURN v_success;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log error (optional - you can remove this if you don't want logging)
    RAISE LOG 'Error inserting customer: %', SQLERRM;
    RETURN FALSE;
END;
$function$

CREATE OR REPLACE FUNCTION public.get_available_stock_for_admin(p_variant_id integer) RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_total_stock INTEGER;
    v_reserved_stock INTEGER := 0;
BEGIN
    -- Clean up expired reservations first
    DELETE FROM inventory_reservations WHERE expires_at < NOW();
    
    -- Get variant stock (since every product must have variants)
    SELECT stock INTO v_total_stock
    FROM product_variants
    WHERE variant_id = p_variant_id AND is_visible = true;
    
    -- Get reserved stock for this variant
    SELECT COALESCE(SUM(quantity), 0) INTO v_reserved_stock
    FROM inventory_reservations
    WHERE variant_id = p_variant_id AND expires_at > NOW();
    
    RETURN GREATEST(0, COALESCE(v_total_stock, 0) - v_reserved_stock);
END;
$function$

CREATE OR REPLACE FUNCTION public.insert_customer_simple(p_phone_number text DEFAULT ''::text, p_first_name text DEFAULT ''::text, p_last_name text DEFAULT ''::text, p_cnic text DEFAULT ''::text, p_email text DEFAULT ''::text, p_dob timestamp with time zone DEFAULT NULL::timestamp with time zone, p_gender text DEFAULT NULL::text, p_auth_uid uuid DEFAULT auth.uid(), p_fcm_token text DEFAULT NULL::text) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_success BOOLEAN := FALSE;
  v_user_exists BOOLEAN := FALSE;
  v_gender_enum public.gender := NULL;
BEGIN
  -- First check if user exists in auth.users table
  SELECT EXISTS(
    SELECT 1 FROM auth.users WHERE id = p_auth_uid
  ) INTO v_user_exists;
  
  -- If user doesn't exist in auth.users, return false
  IF NOT v_user_exists THEN
    RAISE LOG 'User with auth_uid % does not exist in auth.users table', p_auth_uid;
    RETURN FALSE;
  END IF;
  
  -- Check if customer already exists
  IF EXISTS(SELECT 1 FROM public.customers WHERE auth_uid = p_auth_uid) THEN
    RAISE LOG 'Customer with auth_uid % already exists in customers table', p_auth_uid;
    RETURN FALSE;
  END IF;
  
  -- Convert gender text to enum if provided
  IF p_gender IS NOT NULL AND p_gender != '' THEN
    BEGIN
      v_gender_enum := p_gender::public.gender;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE LOG 'Invalid gender value: %', p_gender;
        v_gender_enum := NULL;
    END;
  END IF;
  
  -- Insert customer data
  INSERT INTO public.customers (
    phone_number,
    first_name,
    last_name,
    cnic,
    email,
    dob,
    gender,
    auth_uid,
    fcm_token
  ) VALUES (
    p_phone_number,
    p_first_name,
    p_last_name,
    p_cnic,
    p_email,
    p_dob,
    v_gender_enum,
    p_auth_uid,
    p_fcm_token
  );
  
  -- If we reach here, insert was successful
  v_success := TRUE;
  
  RETURN v_success;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log error (optional - you can remove this if you don't want logging)
    RAISE LOG 'Error inserting customer: %', SQLERRM;
    RETURN FALSE;
END;
$function$

CREATE OR REPLACE FUNCTION public.validate_add_to_cart_shop_limit(p_customer_id integer, p_variant_id integer, p_new_quantity integer) RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_max_allowed bigint;
  v_current_quantity integer;
  v_total integer;
  v_remaining integer;
begin
  select coalesce(max_allowed_item_quantity, 50)
    into v_max_allowed
  from shop
  order by shop_id
  limit 1;

  select coalesce((quantity)::integer, 0)
    into v_current_quantity
  from cart
  where customer_id = p_customer_id
    and variant_id = p_variant_id
  limit 1;

  v_current_quantity := coalesce(v_current_quantity, 0);
  v_total := v_current_quantity + greatest(p_new_quantity, 0);
  v_remaining := greatest(v_max_allowed - v_current_quantity, 0);

  if v_total <= v_max_allowed then
    return json_build_object(
      'allowed', true,
      'can_add_quantity', greatest(p_new_quantity, 0),
      'max_allowed_quantity', v_max_allowed,
      'current_quantity', v_current_quantity,
      'remaining_quantity', v_remaining
    );
  else
    return json_build_object(
      'allowed', false,
      'can_add_quantity', v_remaining,
      'max_allowed_quantity', v_max_allowed,
      'current_quantity', v_current_quantity,
      'remaining_quantity', v_remaining
    );
  end if;
end;
$function$

CREATE OR REPLACE FUNCTION public.reduce_variant_stock(variant_id_param integer, quantity_param integer) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_stock INTEGER;
BEGIN
    -- Lock the row for update to prevent race conditions
    SELECT stock INTO current_stock 
    FROM product_variants 
    WHERE variant_id = variant_id_param 
    FOR UPDATE;
    
    -- Check if sufficient stock is available
    IF current_stock IS NULL THEN
        RAISE EXCEPTION 'Product variant not found: %', variant_id_param;
    END IF;
    
    IF current_stock < quantity_param THEN
        RAISE EXCEPTION 'Insufficient stock. Available: %, Requested: %', current_stock, quantity_param;
    END IF;
    
    -- Reduce the stock
    UPDATE product_variants 
    SET stock = stock - quantity_param,
        updated_at = NOW()
    WHERE variant_id = variant_id_param;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error and re-raise
        RAISE;
END;
$function$

CREATE OR REPLACE FUNCTION public.cleanup_expired_reservations() RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM inventory_reservations
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log the cleanup activity
    INSERT INTO security_audit_log (event_type, event_data, severity)
    VALUES ('reservation_cleanup', 
            jsonb_build_object('deleted_count', deleted_count), 
            'info');
    
    RETURN deleted_count;
END;
$function$

CREATE OR REPLACE FUNCTION public.log_price_changes() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Log price changes in product_variants
    IF OLD.sell_price IS DISTINCT FROM NEW.sell_price THEN
        INSERT INTO security_audit_log (event_type, event_data, severity)
        VALUES ('price_change',
                jsonb_build_object(
                    'variant_id', NEW.variant_id,
                    'old_price', OLD.sell_price,
                    'new_price', NEW.sell_price,
                    'change_amount', NEW.sell_price - OLD.sell_price
                ),
                'warning');
    END IF;
    
    RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.validate_order_integrity(order_id_param integer) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    order_total DECIMAL;
    calculated_total DECIMAL;
    item_count INTEGER;
BEGIN
    -- Get order total from orders table
    SELECT paid_amount INTO order_total
    FROM orders
    WHERE order_id = order_id_param;
    
    -- Calculate total from order items
    SELECT COUNT(*), COALESCE(SUM(price * quantity), 0)
    INTO item_count, calculated_total
    FROM order_items
    WHERE order_id = order_id_param;
    
    -- Validate totals match (allow small rounding differences)
    IF ABS(order_total - calculated_total) > 0.01 THEN
        INSERT INTO security_audit_log (event_type, event_data, severity)
        VALUES ('order_integrity_violation',
                jsonb_build_object(
                    'order_id', order_id_param,
                    'order_total', order_total,
                    'calculated_total', calculated_total,
                    'difference', order_total - calculated_total
                ),
                'critical');
        RETURN FALSE;
    END IF;
    
    -- Validate order has items
    IF item_count = 0 THEN
        INSERT INTO security_audit_log (event_type, event_data, severity)
        VALUES ('empty_order_detected',
                jsonb_build_object('order_id', order_id_param),
                'error');
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$function$

CREATE OR REPLACE FUNCTION public.trigger_cleanup_reservations() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Cleanup expired reservations on insert (during new reservations)
    DELETE FROM inventory_reservations
    WHERE expires_at < NOW() - INTERVAL '1 hour'; -- Keep some buffer
    
    RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.copy_address_to_order_address(p_address_id integer) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_success BOOLEAN := FALSE;
BEGIN
    INSERT INTO public.order_addresses (
        shipping_address,
        phone_number,
        postal_code,
        city,
        country,
        full_name,
        customer_id,
        vendor_id,
        salesman_id,
        user_id,
        address_id
    )
    SELECT
        shipping_address,
        phone_number,
        postal_code,
        city,
        country,
        full_name,
        customer_id,
        vendor_id,
        salesman_id,
        user_id,
        address_id
    FROM
        public.addresses
    WHERE
        address_id = p_address_id;

    IF FOUND THEN
        v_success := TRUE;
    END IF;

    RETURN v_success;
END;
$function$

CREATE OR REPLACE FUNCTION public.update_variant_stock_with_validation(p_variant_id_input integer, p_new_stock_value_input integer, p_customer_id_input integer) RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_stock_in_db INT;
    v_current_cart_items_total INT;
    v_customer_cart_quantity INT;
    v_debug_message TEXT;
BEGIN
    -- Initialize debug message
    v_debug_message := 'Starting validation for variant: ' || p_variant_id_input || 
                      ', new stock: ' || p_new_stock_value_input || 
                      ', customer: ' || p_customer_id_input;
    RAISE NOTICE '%', v_debug_message;

    -- 1. Lock and get current stock
    BEGIN
        SELECT stock INTO v_current_stock_in_db
        FROM public.product_variants
        WHERE variant_id = p_variant_id_input
        FOR UPDATE;
        
        IF NOT FOUND THEN
            v_debug_message := 'Variant not found in database';
            RAISE NOTICE '%', v_debug_message;
            RETURN FALSE;
        END IF;
        
        RAISE NOTICE 'Current stock: %', v_current_stock_in_db;
    EXCEPTION WHEN OTHERS THEN
        v_debug_message := 'Failed to read stock: ' || SQLERRM;
        RAISE NOTICE '%', v_debug_message;
        RETURN FALSE;
    END;

    -- 2. Get cart quantities
    BEGIN
        -- Global cart quantity
        SELECT COALESCE(SUM(NULLIF(quantity, '')::INT), 0)
        INTO v_current_cart_items_total
        FROM public.cart
        WHERE variant_id = p_variant_id_input;
        
        RAISE NOTICE 'Total in all carts: %', v_current_cart_items_total;

        -- Customer-specific quantity
        SELECT COALESCE(SUM(NULLIF(quantity, '')::INT), 0)
        INTO v_customer_cart_quantity
        FROM public.cart
        WHERE variant_id = p_variant_id_input
        AND customer_id = p_customer_id_input;
        
        RAISE NOTICE 'In customer cart: %', v_customer_cart_quantity;
    EXCEPTION WHEN OTHERS THEN
        v_debug_message := 'Failed to read cart quantities: ' || SQLERRM;
        RAISE NOTICE '%', v_debug_message;
        RETURN FALSE;
    END;

    -- 3. Validate stock
    IF (p_new_stock_value_input + v_current_cart_items_total) <= v_current_stock_in_db AND
       (p_new_stock_value_input + v_customer_cart_quantity) <= v_current_stock_in_db THEN
        
        -- Update stock
        UPDATE public.product_variants
        SET stock = p_new_stock_value_input,
            updated_at = NOW()
        WHERE variant_id = p_variant_id_input;
        
        v_debug_message := 'SUCCESS: Stock updated to ' || p_new_stock_value_input || 
                          ' (Was: ' || v_current_stock_in_db || 
                          ', All carts: ' || v_current_cart_items_total || 
                          ', Customer cart: ' || v_customer_cart_quantity || ')';
        RAISE NOTICE '%', v_debug_message;
        RETURN TRUE;
    ELSE
        v_debug_message := 'FAILED: Cannot update stock. Requested: ' || p_new_stock_value_input || 
                          ' + Existing carts: ' || v_current_cart_items_total || 
                          ' + Customer cart: ' || v_customer_cart_quantity || 
                          ' > Current stock: ' || v_current_stock_in_db;
        RAISE NOTICE '%', v_debug_message;
        RETURN FALSE;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        v_debug_message := 'UNEXPECTED ERROR: ' || SQLERRM;
        RAISE NOTICE '%', v_debug_message;
        RETURN FALSE;
END;
$function$

CREATE OR REPLACE FUNCTION public.notify_order_ready() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  IF NEW.status = 'ready' AND OLD.status IS DISTINCT FROM NEW.status THEN
    RAISE NOTICE '✅ Trigger fired: order_id = %, status = %', NEW.order_id, NEW.status;
    
    -- Edge function call (commented to isolate problem)
    -- PERFORM http_post(
    --   url := 'https://jjxqwtltkepeajwtcish.functions.supabase.co/notify-ready',
    --   headers := json_build_object('Content-Type', 'application/json'),
    --   body := json_build_object('new', row_to_json(NEW))
    -- );

  END IF;
  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.copy_address_to_order_addresses(p_address_id integer) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    address_record RECORD;
BEGIN
    -- Get address details from existing addresses table
    SELECT a.*
    INTO address_record
    FROM addresses a
    WHERE a.address_id = p_address_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Insert into order_addresses using existing structure
    INSERT INTO order_addresses (
        customer_id,
        full_name,
        phone_number,
        shipping_address,  -- Using existing column name
        city,
        country,
        postal_code,
        vendor_id,
        salesman_id,
        user_id,
        address_id
    ) VALUES (
        address_record.customer_id,  -- Use customer_id from address record
        address_record.full_name,
        address_record.phone_number,
        address_record.shipping_address,
        address_record.city,
        address_record.country,
        address_record.postal_code,
        address_record.vendor_id,
        address_record.salesman_id,
        address_record.user_id,
        address_record.address_id
    );
    
    RETURN TRUE;
END;
$function$

CREATE OR REPLACE FUNCTION public.calculate_admin_order_totals(p_cart_items jsonb, p_salesman_comission numeric DEFAULT 0, p_discount_percent numeric DEFAULT 0, p_payment_method text DEFAULT 'cash'::text) RETURNS TABLE(subtotal numeric, tax numeric, shipping numeric, salesman_comission numeric, discount numeric, total numeric, buying_price_total numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    item JSONB;
    v_subtotal NUMERIC := 0;
    v_buying_price_total NUMERIC := 0;
    v_tax NUMERIC := 0;
    v_shipping NUMERIC := 0;
    v_salesman_comission NUMERIC := 0;
    v_discount NUMERIC := 0;
    v_total NUMERIC := 0;
    shop_settings RECORD;
BEGIN
    -- Calculate subtotal and buying price total
    FOR item IN SELECT * FROM jsonb_array_elements(p_cart_items)
    LOOP
        v_subtotal := v_subtotal + ((item->>'sellPrice')::NUMERIC * (item->>'quantity')::NUMERIC);
        
        -- Calculate buying price (all products have variants, so multiply by quantity)
        v_buying_price_total := v_buying_price_total + 
            ((item->>'buyPrice')::NUMERIC * (item->>'quantity')::NUMERIC);
    END LOOP;
    
    -- Get shop settings
    SELECT taxrate, shipping_price INTO shop_settings
    FROM shop
    LIMIT 1;
    
    v_tax := COALESCE(shop_settings.taxrate, 0);
    
    -- For POS orders, shipping is always 0 (customer pickup)
    v_shipping := 0;
    
    -- Calculate salesman commission
    v_salesman_comission := (v_subtotal * p_salesman_comission) / 100;
    
    -- Calculate discount
    v_discount := (v_subtotal * p_discount_percent) / 100;
    
    -- Apply discount to subtotal
    v_subtotal := v_subtotal - v_discount;
    
    -- Calculate total
    v_total := v_subtotal + v_tax + v_shipping + v_salesman_comission;
    
    RETURN QUERY SELECT v_subtotal, v_tax, v_shipping, v_salesman_comission, 
                        v_discount, v_total, v_buying_price_total;
END;
$function$

CREATE OR REPLACE FUNCTION public.confirm_inventory_reservation(p_reservation_id character varying) RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    reservation_record RECORD;
    success BOOLEAN := TRUE;
BEGIN
    -- Process each reservation
    FOR reservation_record IN 
        SELECT variant_id, quantity 
        FROM inventory_reservations 
        WHERE reservation_id = p_reservation_id
    LOOP
        -- Use existing reduce_variant_stock function
        BEGIN
            PERFORM reduce_variant_stock(reservation_record.variant_id, reservation_record.quantity);
        EXCEPTION WHEN OTHERS THEN
            success := FALSE;
            EXIT; -- Exit loop on first failure
        END;
    END LOOP;
    
    -- If successful, remove all reservations
    IF success THEN
        DELETE FROM inventory_reservations 
        WHERE reservation_id = p_reservation_id;
    END IF;
    
    RETURN success;
END;
$function$

CREATE OR REPLACE FUNCTION public.update_brand_product_count() RETURNS trigger
 LANGUAGE plpgsql
AS $function$BEGIN
  -- Handle INSERT operation
  IF TG_OP = 'INSERT' THEN
    UPDATE brands
    SET product_count = product_count + 1
    WHERE "brandID" = NEW."brandID";
  END IF;

  -- Handle DELETE operation
  IF TG_OP = 'DELETE' THEN
    UPDATE brands
    SET product_count = product_count - 1
    WHERE "brandID" = OLD."brandID";
  END IF;

  RETURN NULL;
END;$function$

CREATE OR REPLACE FUNCTION public.update_inventory_after_order() RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE product_variants
  SET stock_quantity = stock_quantity - NEW.quantity
  WHERE variant_id = NEW.variant_id;
  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION public.insert_order_with_items(p_order_date timestamp with time zone, p_sub_total numeric, p_status text, p_address_id integer, p_paid_amount numeric, p_customer_id integer, p_user_id integer, p_order_items jsonb[]) RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_order_id INTEGER;
  v_item JSONB;
BEGIN
  -- Insert the order
  INSERT INTO public.orders (
    order_date,
    total_price,
    status,
    address_id,
    paid_amount,
    customer_id,
    user_id
  ) VALUES (
    COALESCE(p_order_date, NOW()),
    p_sub_total,
    p_status,
    p_address_id,
    p_paid_amount,
    p_customer_id,
    p_user_id
  ) RETURNING order_id INTO v_order_id;

  -- Insert order items
  FOREACH v_item IN ARRAY p_order_items
  LOOP
    INSERT INTO public.order_items (
      order_id,
      product_id,
      quantity,
      price,
      unit,
      total_buy_price,
      variant_id
    ) VALUES (
      v_order_id,
      (v_item->>'product_id')::INTEGER,
      (v_item->>'quantity')::INTEGER,
      (v_item->>'price')::NUMERIC(10, 2),
      v_item->>'unit',
      (v_item->>'total_buy_price')::NUMERIC(10, 2),
      (v_item->>'variant_id')::INTEGER
    );
  END LOOP;

  RETURN v_order_id;
END;
$function$