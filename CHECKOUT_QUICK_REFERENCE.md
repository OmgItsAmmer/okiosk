# Checkout Module - Quick Reference

## 🚀 Getting Started

### 1. Run Database Migrations

```sql
-- Connect to your Supabase database and run:
\i database_migrations_checkout.sql
```

### 2. Start the Server

```bash
cargo run --release
```

### 3. Test Checkout

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
        "quantity": 1,
        "sellPrice": "299.99",
        "buyPrice": "150.00"
      }
    ]
  }'
```

## 📋 Checkout Request Format

### Cart Checkout

```json
{
    "customerId": 123,
    "addressId": -1,
    "shippingMethod": "pickup",
    "paymentMethod": "cod",
    "cartItems": [
        {
            "variantId": 789,
            "quantity": 2,
            "sellPrice": "299.99",
            "buyPrice": "150.00"
        }
    ]
}
```

### Direct Checkout (Buy Now)

```json
{
    "customerId": 123,
    "addressId": 5,
    "shippingMethod": "shipping",
    "paymentMethod": "cod",
    "directCheckout": {
        "variantId": 789,
        "quantity": 1,
        "price": "299.99"
    }
}
```

## 🎯 Key Features

### Race Condition Prevention ✅

- Idempotency keys prevent duplicate orders
- Atomic database operations prevent overselling
- Row-level locking during inventory reservation
- Two-phase commit: Reserve → Confirm

### Security Features ✅

- Server-side price validation
- Stock availability checks
- Product visibility validation
- Security audit logging
- Business rule enforcement

### Payment Methods

- ✅ COD (Cash on Delivery)
- ✅ Pickup (Pay at pickup)
- 🔄 Credit Card (TODO)
- 🔄 Bank Transfer (TODO)
- 🔄 JazzCash (TODO)

### Shipping Methods

- ✅ Pickup (addressId = -1)
- ✅ Shipping (addressId > 0)

## 🔍 Response Codes

### Success (200)

```json
{
    "success": true,
    "message": "Order placed successfully!",
    "orderId": 1001,
    "total": "649.98"
}
```

### Error Codes

| Code                      | Description          | Fix                            |
| ------------------------- | -------------------- | ------------------------------ |
| `PHONE_NUMBER_REQUIRED`   | Customer needs phone | Add phone to customer profile  |
| `PRODUCT_NOT_FOUND`       | Invalid variant ID   | Check variant exists           |
| `EMPTY_CART`              | No items in request  | Add items to cart/request      |
| `SHIPPING_METHOD_INVALID` | Invalid shipping     | Use "pickup" or "shipping"     |
| `DUPLICATE_ORDER`         | Already processed    | Wait 1 minute or use new key   |
| `SECURITY_VIOLATION`      | Price mismatch       | Refresh prices from server     |
| `INVENTORY_UNAVAILABLE`   | Out of stock         | Reduce quantity or remove item |
| `PAYMENT_FAILED`          | Payment error        | Check payment method           |
| `ORDER_CREATION_FAILED`   | Database error       | Check logs                     |

## 🔧 Monitoring Queries

### Active Reservations

```sql
SELECT * FROM inventory_reservations 
WHERE expires_at > NOW()
ORDER BY created_at DESC;
```

### Security Events

```sql
SELECT * FROM security_audit_log 
WHERE severity = 'critical'
ORDER BY timestamp DESC 
LIMIT 20;
```

### Recent Orders

```sql
SELECT order_id, customer_id, paid_amount, payment_method, status
FROM orders 
WHERE idempotency_key IS NOT NULL
ORDER BY order_date DESC 
LIMIT 20;
```

### Cleanup Expired Reservations

```sql
SELECT cleanup_expired_reservations();
```

## 🐛 Troubleshooting

### Issue: Duplicate Order Error

**Cause**: Same request within 1-minute window\
**Fix**: Wait 1 minute or provide unique idempotencyKey

### Issue: Inventory Unavailable

**Cause**: Stock exhausted or reserved\
**Fix**: Clean expired reservations or wait for stock

### Issue: Price Mismatch

**Cause**: Client price differs from database\
**Fix**: Fetch latest prices from server before checkout

### Issue: Address Not Found

**Cause**: Invalid address_id\
**Fix**: Verify address exists for customer

## 📊 Performance Tips

1. **Connection Pooling**: Default 50 connections
2. **Indexes**: Ensure indexes on:
   - `orders.idempotency_key`
   - `product_variants.variant_id`
   - `inventory_reservations.variant_id`

3. **Cleanup**: Schedule periodic cleanup:
   ```sql
   -- Every 5 minutes
   SELECT cleanup_expired_reservations();
   ```

## 🔗 Documentation Links

- 📖 [Full Documentation](CHECKOUT_MODULE.md)
- ✅ [Implementation Summary](CHECKOUT_IMPLEMENTATION_SUMMARY.md)
- 🗄️ [Database Migrations](database_migrations_checkout.sql)
- 📝 [Main README](README.md)

## 🎉 Quick Wins

### Test Race Conditions

```bash
# Terminal 1-10: Try to buy same item
for i in {1..10}; do
  curl -X POST http://localhost:3000/api/checkout \
    -H "Content-Type: application/json" \
    -d '{"customerId":'$i',"addressId":-1,"shippingMethod":"pickup","paymentMethod":"cod","cartItems":[{"variantId":1,"quantity":1,"sellPrice":"99.99","buyPrice":"50.00"}]}' &
done
wait
```

### Test Idempotency

```bash
# Run same request twice
REQUEST='{"customerId":1,"addressId":-1,"shippingMethod":"pickup","paymentMethod":"cod","cartItems":[{"variantId":1,"quantity":1,"sellPrice":"99.99","buyPrice":"50.00"}]}'

curl -X POST http://localhost:3000/api/checkout -H "Content-Type: application/json" -d "$REQUEST"
sleep 1
curl -X POST http://localhost:3000/api/checkout -H "Content-Type: application/json" -d "$REQUEST"
```

### Test Security

```bash
# Try price manipulation (should fail)
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
        "quantity": 1,
        "sellPrice": "0.01",
        "buyPrice": "0.01"
      }
    ]
  }'
```

---

**Status**: ✅ Production Ready\
**Version**: 1.0.0\
**Date**: October 10, 2025
