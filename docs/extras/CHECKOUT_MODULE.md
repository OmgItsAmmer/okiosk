# Checkout Module Documentation

## Overview

The checkout module implements a robust, race-condition-safe checkout system for
the KKS Online Backend. It handles concurrent checkouts from multiple apps (one
using Supabase Edge Functions directly, another using this Rust backend) while
maintaining data integrity and preventing inventory overselling.

## Key Features

### 🔒 Race Condition Prevention

The checkout implementation uses several strategies to prevent race conditions:

1. **Idempotency Keys**: Every checkout request generates or accepts an
   idempotency key to prevent duplicate order processing
2. **Atomic Inventory Reservations**: Uses database-level atomic operations
   (`reserve_inventory_secure` function) to reserve inventory before order
   creation
3. **Optimistic Locking**: Inventory is reserved first, then confirmed only
   after successful order creation
4. **Database Transactions**: All critical operations use database functions to
   ensure atomicity

### 🛡️ Security Features

1. **Server-Side Price Validation**: Prevents price manipulation by validating
   against database prices
2. **Stock Availability Checks**: Ensures products are in stock before allowing
   checkout
3. **Business Rule Validation**: Enforces min/max order amounts (PKR 10 - PKR
   500,000)
4. **Security Audit Logging**: Logs all security events including price
   manipulation attempts
5. **Customer Verification**: Ensures customer exists and has required phone
   number

### 📦 Checkout Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CHECKOUT REQUEST                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Verify Customer (phone number required)            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 2: Prepare Cart Items (cart or direct checkout)       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Generate Idempotency Key (SHA-256 hash)            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 4: Validate Shipping Method                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 5: Check for Duplicate Orders (idempotency)           │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 6: Validate Cart Security                             │
│  • Price validation (prevent manipulation)                  │
│  • Stock availability                                        │
│  • Product visibility                                        │
│  • Quantity constraints                                      │
│  • Business rules (min/max amounts)                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 7: Reserve Inventory (ATOMIC)                         │
│  Uses database function: reserve_inventory_secure()          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 8: Process Payment                                    │
│  • COD (Cash on Delivery)                                   │
│  • Pickup (Pay at pickup)                                   │
│  • Credit Card (TODO: Stripe integration)                   │
│  • Bank Transfer (TODO)                                     │
│  • JazzCash (TODO: JazzCash API integration)                │
└─────────────────────────────────────────────────────────────┘
                            │
                   ┌────────┴────────┐
                   │   Payment OK?    │
                   └────────┬────────┘
                            │ NO
                            ▼
              ┌──────────────────────────┐
              │ Rollback Inventory       │
              │ Return Payment Failed    │
              └──────────────────────────┘
                            │ YES
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 9: Create Order                                       │
│  • Copy address (if applicable)                             │
│  • Create order record                                      │
│  • Create order items                                       │
└─────────────────────────────────────────────────────────────┘
                            │
                   ┌────────┴────────┐
                   │   Order Created? │
                   └────────┬────────┘
                            │ NO
                            ▼
              ┌──────────────────────────┐
              │ Rollback Inventory       │
              │ TODO: Refund Payment     │
              └──────────────────────────┘
                            │ YES
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 10: Confirm Inventory Reservation                     │
│  Reduces actual stock, removes reservation records          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 11: Clear Cart (if not direct checkout)               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Step 12: Log Security Event (checkout_success)             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │  SUCCESS RESPONSE   │
                 │  Order ID + Total   │
                 └─────────────────────┘
```

## API Endpoint

### POST `/api/checkout`

Process a checkout request with full validation and race condition handling.

#### Request Body

```json
{
    "customerId": 123,
    "addressId": 456, // -1 for pickup, >0 for valid address
    "shippingMethod": "shipping", // "pickup" or "shipping"
    "paymentMethod": "cod", // "cod", "pickup", "credit_card", "bank_transfer", "jazzcash"

    // Option 1: Cart checkout (regular)
    "cartItems": [
        {
            "variantId": 789,
            "quantity": 2,
            "sellPrice": "299.99",
            "buyPrice": "150.00"
        }
    ],

    // Option 2: Direct checkout (buy now)
    "directCheckout": {
        "variantId": 789,
        "quantity": 1,
        "price": "299.99"
    },

    // Optional: Provide your own idempotency key
    "idempotencyKey": "checkout_abc123..."
}
```

#### Success Response (200 OK)

```json
{
    "success": true,
    "message": "Order placed successfully!",
    "orderId": 1001,
    "total": "649.98"
}
```

#### Error Response (400/401/409/500)

```json
{
    "success": false,
    "message": "Descriptive error message",
    "errorCode": "ERROR_CODE"
}
```

#### Error Codes

| Error Code                | Description                           | HTTP Status |
| ------------------------- | ------------------------------------- | ----------- |
| `PHONE_NUMBER_REQUIRED`   | Customer needs to add phone number    | 400         |
| `PRODUCT_NOT_FOUND`       | Product variant not found             | 400         |
| `EMPTY_CART`              | No items in cart                      | 400         |
| `SHIPPING_METHOD_INVALID` | Invalid shipping method or address    | 400         |
| `DUPLICATE_ORDER`         | Order already processed (idempotency) | 409         |
| `SECURITY_VIOLATION`      | Price manipulation or invalid data    | 400         |
| `INVENTORY_UNAVAILABLE`   | Insufficient stock                    | 400         |
| `PAYMENT_FAILED`          | Payment processing failed             | 400         |
| `ORDER_CREATION_FAILED`   | Order creation failed                 | 500         |
| `SYSTEM_ERROR`            | Internal server error                 | 500         |

## Race Condition Handling

### Problem Statement

Two apps use the same database:

1. **App A**: Uses Supabase Edge Function for checkout
2. **App B**: Uses this Rust backend for checkout

When multiple users checkout simultaneously, potential race conditions include:

- **Double booking**: Two customers buying the last item
- **Inventory overselling**: Stock goes negative
- **Duplicate orders**: Same customer submits order twice

### Solutions Implemented

#### 1. Idempotency Keys

Every checkout generates a unique key based on:

- Customer ID
- Cart items (variant IDs, quantities, prices)
- Timestamp (1-minute window)
- SHA-256 hashing

```rust
// Example: checkout_a1b2c3d4e5f6g7h8
```

If the same request is made twice within a minute, the second attempt is
rejected with `DUPLICATE_ORDER`.

#### 2. Atomic Inventory Reservation

The system uses a database function `reserve_inventory_secure()` that:

```sql
-- Pseudo-code representation
CREATE OR REPLACE FUNCTION reserve_inventory_secure(
    p_reservation_id TEXT,
    p_cart_items JSONB
) RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    error_details JSONB
) AS $$
BEGIN
    -- Lock rows for update (prevents concurrent modification)
    -- Check stock availability atomically
    -- Create reservation records
    -- Return success or detailed errors
END;
$$ LANGUAGE plpgsql;
```

This function:

- Locks the variant rows during the transaction
- Checks if sufficient stock is available
- Creates reservation records if available
- Returns detailed error messages if stock is insufficient

#### 3. Two-Phase Inventory Update

1. **Phase 1 - Reserve**: Create reservation records without reducing stock
2. **Phase 2 - Confirm**: After successful order creation, reduce actual stock

If anything fails between phases, reservations are rolled back.

```rust
// Reserve inventory
db.orders().reserve_inventory(&idempotency_key, &cart_items).await?;

// ... payment processing ...
// ... order creation ...

// Confirm and reduce actual stock
db.orders().confirm_inventory_reservation(&idempotency_key).await?;
```

#### 4. Database-Level Locking

The PostgreSQL database uses:

- `SELECT ... FOR UPDATE` to lock rows during reservation
- Serializable transaction isolation where needed
- Unique constraints on idempotency keys

## Database Schema Requirements

The checkout system requires the following database tables and functions:

### Tables

```sql
-- Inventory reservations table
CREATE TABLE inventory_reservations (
    reservation_id TEXT NOT NULL,
    variant_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '10 minutes'
);

-- Security audit log table
CREATE TABLE security_audit_log (
    id SERIAL PRIMARY KEY,
    event_type TEXT NOT NULL,
    event_data JSONB,
    timestamp TIMESTAMP DEFAULT NOW(),
    ip_address TEXT,
    user_agent TEXT,
    customer_id INTEGER,
    severity TEXT DEFAULT 'info'
);

-- Orders table (should already exist)
ALTER TABLE orders ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_method TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS payment_method TEXT;
```

### Required Database Functions

1. **reserve_inventory_secure(p_reservation_id, p_cart_items)**: Atomically
   reserve inventory
2. **confirm_inventory_reservation(p_reservation_id)**: Reduce stock and clear
   reservations
3. **copy_address_to_order_address(p_address_id)**: Copy customer address for
   order history

These functions must be created in your Supabase database to match the Edge
Function implementation.

## Concurrent Checkout Scenario

### Example: Two Users, One Product

**Initial State:**

- Product A: 1 item in stock
- User 1 (Edge Function): Checks out Product A
- User 2 (Rust Backend): Checks out Product A at the same time

**Timeline:**

| Time | User 1 (Edge Function)        | User 2 (Rust Backend)        | Stock |
| ---- | ----------------------------- | ---------------------------- | ----- |
| T0   | Start checkout                | -                            | 1     |
| T1   | Reserve inventory (locks row) | Start checkout               | 1     |
| T2   | Reservation successful        | Attempts to reserve          | 1     |
| T3   | Create order                  | **Blocked waiting for lock** | 1     |
| T4   | Confirm inventory (stock = 0) | Still waiting                | 0     |
| T5   | Release lock                  | Gets lock, checks stock      | 0     |
| T6   | ✅ Order complete             | ❌ Insufficient stock error  | 0     |

**Result**: User 1 gets the item, User 2 receives "INVENTORY_UNAVAILABLE" error.

## Payment Methods

### Currently Supported

1. **COD (Cash on Delivery)**: No payment processing, confirmed on delivery
2. **Pickup**: Payment at pickup location

### TODO: Integration Required

3. **Credit Card**: Integrate with Stripe/Square
4. **Bank Transfer**: Integrate with bank API
5. **JazzCash**: Integrate with JazzCash payment gateway

### Adding New Payment Methods

To add a new payment method, update the `process_payment` function in
`src/handlers/checkout_handlers.rs`:

```rust
async fn process_payment(
    payment_method: &str,
    amount: &Decimal,
    _customer_id: i32,
    idempotency_key: &str,
) -> (bool, String, String) {
    match payment_method {
        "your_payment_method" => {
            // Your integration here
            // Return (success: bool, message: String, transaction_id: String)
        }
        // ... existing methods
    }
}
```

## Security Features

### Price Manipulation Prevention

The system validates prices server-side:

```rust
// Client sends price
let cart_price = item.sell_price; // e.g., $10.00 (manipulated)

// Server fetches actual price from database
let db_price = fetch_from_database(); // e.g., $99.99

// Compare with tolerance
if (db_price - cart_price).abs() > 0.01 {
    // Log security event
    log_security_event("price_manipulation_detected", ...);
    // Reject checkout
    return error("Price mismatch");
}
```

### Audit Logging

All security events are logged:

- Price manipulation attempts
- Cart validation failures
- Inventory unavailability
- Checkout errors
- Successful checkouts

Severity levels:

- **Critical**: Price manipulation, checkout errors
- **Warning**: Validation failures, inventory issues
- **Info**: Successful checkouts

## Testing the Checkout

### Example Request (cURL)

```bash
curl -X POST http://localhost:3000/api/checkout \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "addressId": -1,
    "shippingMethod": "pickup",
    "paymentMethod": "cod",
    "cartItems": [
      {
        "variantId": 1,
        "quantity": 2,
        "sellPrice": "299.99",
        "buyPrice": "150.00"
      }
    ]
  }'
```

### Example Request (JavaScript/Flutter)

```javascript
const response = await fetch("http://localhost:3000/api/checkout", {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
    },
    body: JSON.stringify({
        customerId: 1,
        addressId: 5,
        shippingMethod: "shipping",
        paymentMethod: "cod",
        cartItems: [
            {
                variantId: 1,
                quantity: 1,
                sellPrice: "299.99",
                buyPrice: "150.00",
            },
        ],
    }),
});

const data = await response.json();
if (data.success) {
    console.log("Order placed!", data.orderId);
} else {
    console.error("Checkout failed:", data.message, data.errorCode);
}
```

## Migration from Edge Function

If you're migrating from the Edge Function to this Rust backend:

1. **Database compatibility**: Both use the same database functions, so they can
   coexist
2. **Same API contract**: Request/response formats are identical
3. **Gradual migration**: You can migrate users gradually
4. **No downtime**: Both systems can run simultaneously

### Differences

| Feature        | Edge Function     | Rust Backend           |
| -------------- | ----------------- | ---------------------- |
| Language       | TypeScript (Deno) | Rust                   |
| Performance    | Good              | Excellent              |
| Type Safety    | Good              | Excellent              |
| Concurrency    | Single-threaded   | Multi-threaded (Tokio) |
| Error Handling | Try-catch         | Result types           |
| Compilation    | Runtime           | Compile-time checks    |

## Performance Considerations

### Optimization Tips

1. **Connection Pooling**: sqlx uses connection pooling by default
2. **Async Operations**: All database operations are async (non-blocking)
3. **Minimal Allocations**: Uses references where possible
4. **Database Indexes**: Ensure proper indexes on:
   - `orders.idempotency_key`
   - `product_variants.variant_id`
   - `inventory_reservations.reservation_id`
   - `inventory_reservations.expires_at`

### Cleanup Tasks

Periodically clean expired inventory reservations:

```sql
DELETE FROM inventory_reservations 
WHERE expires_at < NOW();
```

Consider setting up a cron job or database trigger for this.

## Troubleshooting

### Common Issues

**Issue**: "DUPLICATE_ORDER" error when it shouldn't be a duplicate

**Solution**: The idempotency key uses a 1-minute window. If you're testing
rapidly, wait 1 minute or provide your own unique key.

---

**Issue**: "INVENTORY_UNAVAILABLE" but stock shows available

**Solution**: Check for orphaned reservations in `inventory_reservations` table.
Clean up expired reservations.

---

**Issue**: Compilation errors about `sqlx::Type` for `InventoryReservationItem`

**Solution**: Ensure the database type `cart_item_type` exists and matches the
struct fields.

---

**Issue**: Database function not found errors

**Solution**: Ensure all required database functions exist in your Supabase
database.

## Future Enhancements

- [ ] Add payment refund logic for failed orders
- [ ] Integrate Stripe for credit card payments
- [ ] Integrate JazzCash payment gateway
- [ ] Add webhook support for async payment confirmations
- [ ] Implement partial refunds
- [ ] Add order status tracking webhooks
- [ ] Implement inventory reservation expiration cleanup
- [ ] Add rate limiting for checkout requests
- [ ] Add customer-level concurrency limits
- [ ] Implement order retry queue for failed payments

## Related Documentation

- [Cart Module](CART_MODULE.md)
- [Product Module](PRODUCT_MODULE.md)
- [Category Module](CATEGORY_MODULE.md)
- [API Migration Guide](API_MIGRATION_GUIDE.md)
- [Quick Start](QUICK_START.md)

## Support

For issues or questions about the checkout implementation, please check the
existing documentation or create an issue in the project repository.
