| table_name             | column_name               | data_type                |
| ---------------------- | ------------------------- | ------------------------ |
| addresses              | address_id                | integer                  |
| addresses              | latitude                  | numeric                  |
| addresses              | longitude                 | numeric                  |
| addresses              | user_id                   | integer                  |
| addresses              | salesman_id               | integer                  |
| addresses              | vendor_id                 | integer                  |
| addresses              | customer_id               | integer                  |
| addresses              | shipping_address          | text                     |
| addresses              | phone_number              | text                     |
| addresses              | postal_code               | text                     |
| addresses              | city                      | text                     |
| addresses              | country                   | text                     |
| addresses              | full_name                 | text                     |
| addresses              | place_id                  | text                     |
| addresses              | formatted_address         | text                     |
| auth_sessions          | session_id                | character varying        |
| auth_sessions          | user_id                   | uuid                     |
| auth_sessions          | status                    | character varying        |
| auth_sessions          | created_at                | timestamp with time zone |
| auth_sessions          | expires_at                | timestamp with time zone |
| brands                 | brandname                 | text                     |
| brands                 | isVerified                | boolean                  |
| brands                 | isFeatured                | boolean                  |
| brands                 | brandID                   | integer                  |
| brands                 | product_count             | bigint                   |
| cart                   | cart_id                   | integer                  |
| cart                   | quantity                  | text                     |
| cart                   | customer_id               | integer                  |
| cart                   | variant_id                | integer                  |
| categories             | category_id               | integer                  |
| categories             | category_name             | text                     |
| categories             | isFeatured                | boolean                  |
| categories             | created_at                | timestamp with time zone |
| categories             | product_count             | integer                  |
| customer_public_info   | customer_id               | integer                  |
| customer_public_info   | first_name                | text                     |
| customer_public_info   | last_name                 | text                     |
| customers              | customer_id               | integer                  |
| customers              | auth_uid                  | character varying        |
| customers              | email                     | text                     |
| customers              | cnic                      | text                     |
| customers              | last_name                 | text                     |
| customers              | phone_number              | text                     |
| customers              | created_at                | timestamp with time zone |
| customers              | first_name                | text                     |
| customers              | dob                       | timestamp with time zone |
| customers              | gender                    | text                     |
| customers              | fcm_token                 | text                     |
| customers              | token_version             | integer                  |
| extras                 | extraid                   | bigint                   |
| extras                 | adminkey                  | text                     |
| image_entity           | image_entity_id           | integer                  |
| image_entity           | updated_at                | timestamp with time zone |
| image_entity           | entity_category           | text                     |
| image_entity           | image_id                  | integer                  |
| image_entity           | entity_id                 | integer                  |
| image_entity           | isFeatured                | boolean                  |
| image_entity           | created_at                | timestamp with time zone |
| images                 | image_id                  | integer                  |
| images                 | folderType                | text                     |
| images                 | filename                  | text                     |
| images                 | created_at                | timestamp with time zone |
| inventory_reservations | reservation_id            | character varying        |
| inventory_reservations | variant_id                | integer                  |
| inventory_reservations | quantity                  | integer                  |
| inventory_reservations | expires_at                | timestamp with time zone |
| inventory_reservations | created_at                | timestamp with time zone |
| inventory_status       | variant_id                | integer                  |
| inventory_status       | product_name              | text                     |
| inventory_status       | reserved_quantity         | bigint                   |
| inventory_status       | sell_price                | numeric                  |
| inventory_status       | total_stock               | integer                  |
| inventory_status       | available_stock           | bigint                   |
| inventory_status       | variant_name              | text                     |
| invoice_coupons        | coupon_id                 | integer                  |
| invoice_coupons        | created_at                | timestamp with time zone |
| invoice_coupons        | discount_type             | text                     |
| invoice_coupons        | coupon_code               | text                     |
| invoice_coupons        | title                     | text                     |
| invoice_coupons        | amount                    | numeric                  |
| invoice_coupons        | usage_limit               | integer                  |
| invoice_coupons        | used_count                | integer                  |
| invoice_coupons        | start_date                | timestamp with time zone |
| invoice_coupons        | end_date                  | timestamp with time zone |
| invoice_coupons        | is_active                 | boolean                  |
| notifications          | notification_id           | integer                  |
| notifications          | product_id                | integer                  |
| notifications          | created_at                | timestamp with time zone |
| notifications          | isread                    | boolean                  |
| notifications          | expires_at                | timestamp with time zone |
| notifications          | order_id                  | integer                  |
| notifications          | installment_plan_id       | integer                  |
| notifications          | description               | text                     |
| notifications          | sub_description           | text                     |
| notifications          | notificationtype          | text                     |
| oauth_users            | id                        | uuid                     |
| oauth_users            | google_id                 | character varying        |
| oauth_users            | email                     | character varying        |
| oauth_users            | name                      | character varying        |
| oauth_users            | picture                   | character varying        |
| oauth_users            | created_at                | timestamp with time zone |
| oauth_users            | updated_at                | timestamp with time zone |
| order_items            | order_id                  | integer                  |
| order_items            | product_id                | integer                  |
| order_items            | variant_id                | integer                  |
| order_items            | created_at                | timestamp with time zone |
| order_items            | unit                      | character varying        |
| order_items            | total_buy_price           | numeric                  |
| order_items            | quantity                  | integer                  |
| order_items            | price                     | numeric                  |
| orders                 | order_id                  | integer                  |
| orders                 | user_id                   | integer                  |
| orders                 | shipping_method           | text                     |
| orders                 | idempotency_key           | character varying        |
| orders                 | buying_price              | numeric                  |
| orders                 | discount                  | numeric                  |
| orders                 | tax                       | numeric                  |
| orders                 | shipping_fee              | numeric                  |
| orders                 | customer_id               | integer                  |
| orders                 | payment_method            | text                     |
| orders                 | salesman_id               | integer                  |
| orders                 | salesman_comission        | integer                  |
| orders                 | sub_total                 | numeric                  |
| orders                 | status                    | text                     |
| orders                 | address_id                | integer                  |
| orders                 | order_date                | date                     |
| orders                 | paid_amount               | numeric                  |
| orders                 | saletype                  | text                     |
| product_discounts      | discount_id               | integer                  |
| product_discounts      | product_id                | integer                  |
| product_discounts      | end_date                  | timestamp with time zone |
| product_discounts      | start_date                | timestamp with time zone |
| product_discounts      | discount_type             | text                     |
| product_discounts      | amount                    | numeric                  |
| product_discounts      | created_at                | timestamp with time zone |
| product_discounts      | is_active                 | boolean                  |
| product_variants       | variant_id                | integer                  |
| product_variants       | sku                       | character varying        |
| product_variants       | alert_stock               | bigint                   |
| product_variants       | stock                     | integer                  |
| product_variants       | is_visible                | boolean                  |
| product_variants       | updated_at                | timestamp with time zone |
| product_variants       | created_at                | timestamp with time zone |
| product_variants       | sell_price                | numeric                  |
| product_variants       | buy_price                 | numeric                  |
| product_variants       | product_id                | integer                  |
| product_variants       | variant_name              | text                     |
| products               | product_id                | integer                  |
| products               | tag                       | text                     |
| products               | description               | text                     |
| products               | name                      | text                     |
| products               | base_price                | text                     |
| products               | sale_price                | text                     |
| products               | price_range               | text                     |
| products               | isVisible                 | boolean                  |
| products               | alert_stock               | integer                  |
| products               | brandID                   | integer                  |
| products               | created_at                | timestamp with time zone |
| products               | stock_quantity            | integer                  |
| products               | ispopular                 | boolean                  |
| products               | category_id               | integer                  |
| reviews                | review_id                 | bigint                   |
| reviews                | product_id                | integer                  |
| reviews                | customer_id               | integer                  |
| reviews                | rating                    | numeric                  |
| reviews                | review                    | text                     |
| reviews                | sent_at                   | timestamp with time zone |
| security_audit_log     | log_id                    | integer                  |
| security_audit_log     | timestamp                 | timestamp with time zone |
| security_audit_log     | user_agent                | text                     |
| security_audit_log     | event_type                | character varying        |
| security_audit_log     | severity                  | character varying        |
| security_audit_log     | event_data                | jsonb                    |
| security_audit_log     | customer_id               | integer                  |
| security_audit_log     | ip_address                | inet                     |
| security_dashboard     | event_type                | character varying        |
| security_dashboard     | severity                  | character varying        |
| security_dashboard     | unique_customers          | bigint                   |
| security_dashboard     | event_count               | bigint                   |
| security_dashboard     | date                      | date                     |
| shop                   | shop_id                   | integer                  |
| shop                   | max_allowed_item_quantity | bigint                   |
| shop                   | software_website_link     | text                     |
| shop                   | software_contact_no       | text                     |
| shop                   | software_company_name     | text                     |
| shop                   | shopname                  | text                     |
| shop                   | taxrate                   | numeric                  |
| shop                   | shipping_price            | numeric                  |
| shop                   | threshold_free_shipping   | numeric                  |
| shop                   | is_shipping_enable        | boolean                  |
| users                  | user_id                   | integer                  |
| users                  | first_name                | text                     |
| users                  | gender                    | text                     |
| users                  | created_at                | timestamp with time zone |
| users                  | dob                       | timestamp with time zone |
| users                  | auth_uid                  | character varying        |
| users                  | email                     | text                     |
| users                  | phone_number              | text                     |
| users                  | last_name                 | text                     |
| wishlist               | wishlist_id               | bigint                   |
| wishlist               | created_at                | timestamp with time zone |
| wishlist               | product_id                | integer                  |
| wishlist               | customer_id               | integer                  |