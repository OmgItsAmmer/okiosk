# Database Column Name Reference

This document lists the exact column names as they appear in the Supabase database schema.
**IMPORTANT**: PostgreSQL is case-sensitive when column names contain uppercase letters!

## Key Tables and Their Column Casing

### products table
- `product_id` - lowercase
- `name` - lowercase
- `description` - lowercase
- `price_range` - lowercase
- `base_price` - lowercase
- `sale_price` - lowercase
- `category_id` - lowercase
- **`ispopular`** - **ALL LOWERCASE** (not isPopular!)
- `stock_quantity` - lowercase
- `created_at` - lowercase
- **`brandID`** - **camelCase** (must be quoted as "brandID")
- `alert_stock` - lowercase
- **`isVisible`** - **camelCase** (must be quoted as "isVisible")
- `tag` - lowercase

### images table
- `image_id` - lowercase
- **`foldertype`** - **ALL LOWERCASE** (not folderType!)
- `filename` - lowercase
- `created_at` - lowercase

### image_entity table
- `image_entity_id` - lowercase
- `updated_at` - lowercase
- `entity_category` - lowercase
- `image_id` - lowercase
- `entity_id` - lowercase
- **`isfeatured`** - **ALL LOWERCASE** (not isFeatured!)
- `created_at` - lowercase

### categories table
- `category_id` - lowercase
- `category_name` - lowercase
- **`isFeatured`** - **camelCase** (must be quoted as "isFeatured")
- `created_at` - lowercase
- `product_count` - lowercase

## SQL Query Rules

1. **Lowercase columns**: Use without quotes
   ```sql
   SELECT ispopular, foldertype, isfeatured FROM ...
   ```

2. **camelCase columns**: MUST be quoted with double quotes
   ```sql
   SELECT "isVisible", "brandID", "isFeatured" FROM ...
   ```

3. **Common mistakes to avoid**:
   - ❌ `isPopular` → ✅ `ispopular`
   - ❌ `folderType` → ✅ `foldertype`
   - ❌ `isFeatured` (in image_entity) → ✅ `isfeatured`
   - ❌ `brandId` → ✅ `"brandID"`
   - ❌ `isvisible` → ✅ `"isVisible"`

## Reference
See `schema.md` for the complete database schema.
