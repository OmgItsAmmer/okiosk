import 'kiosk_cart_model.dart';

/// Cart Model - Represents a single cart entry in the database
///
/// This model follows the Single Responsibility Principle by only handling
/// cart data representation and transformation. It's immutable and provides
/// clear contract for cart operations.
///
/// Database Schema Mapping:
/// - cart_id: Primary key (auto-generated)
/// - variant_id: Foreign key to product_variants table
/// - quantity: String representation of item quantity
/// - customer_id: Foreign key to customers table (nullable for kiosk carts)
/// - kiosk_session_id: UUID for kiosk session identification (optional)
class CartModel {
  final int cartId;
  final int? variantId;
  final String quantity;
  final int? customerId;
  final String? kioskSessionId;

  /// Creates a new CartModel instance
  ///
  /// All fields are final to ensure immutability and prevent accidental modifications
  const CartModel({
    required this.cartId,
    this.variantId,
    required this.quantity,
    this.customerId,
    this.kioskSessionId,
  });

  /// Creates an empty cart model for initialization purposes
  ///
  /// Uses factory pattern to provide a standard way of creating empty instances
  static CartModel empty() => const CartModel(
        cartId: -1,
        variantId: null,
        quantity: "0",
        customerId: null,
        kioskSessionId: null,
      );

  /// Converts model to JSON for database operations
  ///
  /// Excludes cart_id for insert operations, includes it for updates
  /// This follows the Interface Segregation Principle by providing different
  /// interfaces for different operations
  Map<String, dynamic> toJson({bool isUpdate = false}) {
    final Map<String, dynamic> data = {
      'variant_id': variantId,
      'quantity': quantity,
      'customer_id': customerId,
    };

    // Add kiosk_session_id if present
    if (kioskSessionId != null && kioskSessionId!.isNotEmpty) {
      data['kiosk_session_id'] = kioskSessionId;
    }

    if (isUpdate && cartId > 0) {
      data['cart_id'] = cartId;
    }

    return data;
  }

  /// Factory constructor to create CartModel from database response
  ///
  /// Handles null safety and provides default values for missing fields
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      cartId: json['cart_id'] as int? ?? -1,
      variantId: json['variant_id'] as int?,
      quantity: json['quantity'] as String? ?? "0",
      customerId: json['customer_id'] as int?,
      kioskSessionId: json['kiosk_session_id'] as String?,
    );
  }

  /// Creates a copy of this model with updated fields
  ///
  /// Enables immutable updates following functional programming principles
  CartModel copyWith({
    int? cartId,
    int? variantId,
    String? quantity,
    int? customerId,
    String? kioskSessionId,
  }) {
    return CartModel(
      cartId: cartId ?? this.cartId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      customerId: customerId ?? this.customerId,
      kioskSessionId: kioskSessionId ?? this.kioskSessionId,
    );
  }

  /// Converts quantity string to integer with null safety
  int get quantityAsInt => int.tryParse(quantity) ?? 0;

  /// Validates if the cart item is valid
  bool get isValid =>
      variantId != null &&
      quantityAsInt > 0 &&
      (customerId != null || kioskSessionId != null);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartModel &&
          runtimeType == other.runtimeType &&
          cartId == other.cartId &&
          variantId == other.variantId;

  @override
  int get hashCode => cartId.hashCode ^ variantId.hashCode;

  @override
  String toString() {
    return 'CartModel{cartId: $cartId, variantId: $variantId, quantity: $quantity, customer_id: $customerId, kiosk_session_id: $kioskSessionId}';
  }

  /// Converts a KioskCartModel to CartModel
  ///
  /// This method creates a CartModel from a KioskCartModel with customerId set to null
  /// and kioskSessionId populated from the kiosk cart data.
  ///
  /// @param kioskCart The KioskCartModel to convert
  /// @return CartModel The converted cart model
  static CartModel fromKioskCart(KioskCartModel kioskCart) {
    return CartModel(
      cartId: kioskCart.kioskId,
      variantId: kioskCart.variantId,
      quantity: kioskCart.quantity.toString(),
      customerId: null, // Kiosk carts don't have customer IDs
      kioskSessionId: kioskCart.kioskSessionId,
    );
  }

  /// Converts a list of KioskCartModel to list of CartModel
  ///
  /// This method converts multiple KioskCartModel instances to CartModel instances
  /// for batch processing.
  ///
  /// @param kioskCarts The list of KioskCartModel to convert
  /// @return List<CartModel> The converted list of cart models
  static List<CartModel> fromKioskCartList(List<KioskCartModel> kioskCarts) {
    return kioskCarts.map((kioskCart) => fromKioskCart(kioskCart)).toList();
  }
}

/// Enhanced Cart Item Model - Represents a complete cart item with product and variant details
///
/// This model aggregates data from multiple tables to provide a complete view
/// of a cart item. It follows the Aggregate pattern from DDD.
/// Updated to match new database schema: products and product_variants tables
class CartItemModel {
  final CartModel cart;

  // Product fields (from products table)
  final String productName;
  final String productDescription;
  final String basePrice;
  final String salePrice;
  final int? brandId;

  // Variant fields (from product_variants table)
  final String variantName;
  final double sellPrice;
  final double? buyPrice;
  final int stock;
  final bool isVisible;

  const CartItemModel({
    required this.cart,
    required this.productName,
    required this.productDescription,
    required this.basePrice,
    required this.salePrice,
    this.brandId,
    required this.variantName,
    required this.sellPrice,
    this.buyPrice,
    required this.stock,
    required this.isVisible,
  });

  /// Factory constructor to create from merged data
  factory CartItemModel.fromMergedData(Map<String, dynamic> data) {
    return CartItemModel(
      cart: CartModel(
        cartId: data['cart_id'] as int? ?? -1,
        variantId: data['variant_id'] as int?,
        quantity: data['quantity']?.toString() ?? "0",
        customerId: data['customer_id'] as int?,
      ),
      // Product data
      productName: data['name'] as String? ?? '',
      productDescription: data['description'] as String? ?? '',
      basePrice: data['base_price'] as String? ?? '0',
      salePrice: data['sale_price'] as String? ?? '0',
      brandId: data['brandID'] as int?,
      // Variant data
      variantName: data['variant_name'] as String? ?? '',
      sellPrice: data['sell_price'] as double? ?? 0.0,
      buyPrice: data['buy_price'] as double?,
      stock: data['stock'] as int? ?? 0,
      isVisible: data['isVisible'] as bool? ?? false,
    );
  }

  /// Calculates total price for this cart item (reactive-ready)
  double get totalPrice => (sellPrice) * cart.quantityAsInt;

  /// Checks if item is in stock
  bool get isInStock => (stock) > 0;

  /// Gets effective price (variant sell price or product sale price)
  double get effectivePrice => sellPrice;

  /// Creates updated cart item with new quantity
  CartItemModel updateQuantity(int newQuantity) {
    return CartItemModel(
      cart: cart.copyWith(quantity: newQuantity.toString()),
      productName: productName,
      productDescription: productDescription,
      basePrice: basePrice,
      salePrice: salePrice,
      brandId: brandId,
      variantName: variantName,
      sellPrice: sellPrice,
      buyPrice: buyPrice,
      stock: stock,
      isVisible: isVisible,
    );
  }

  /// Legacy getters for backward compatibility
  /// These map the new schema fields to old field names used in UI

  double get variantPrice => sellPrice;
  int get variantStock => stock;
  int? get brandName => brandId; // Convert to string if needed
  String? get variantImage =>
      null; // No image in current schema, can be added later

  @override
  String toString() {
    return 'CartItemModel{cart: $cart, productName: $productName, totalPrice: $totalPrice}';
  }
}

/// Cart Summary Model - Represents aggregated cart information
///
/// Follows the Value Object pattern to encapsulate cart calculations
class CartSummary {
  final List<CartItemModel> items;
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double total;
  final int totalItems;

  const CartSummary({
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.taxAmount,
    required this.total,
    required this.totalItems,
  });

  /// Factory constructor to calculate summary from cart items
  factory CartSummary.fromItems(
    List<CartItemModel> items, {
    double shippingCost = 0.0,
    double taxRate = 0.0,
  }) {
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    //final taxAmount = subtotal * taxRate;
    final total = subtotal + shippingCost + taxRate;
    final totalItems = items.fold<int>(
      0,
      (sum, item) => sum + item.cart.quantityAsInt,
    );

    return CartSummary(
      items: items,
      subtotal: subtotal,
      shippingCost: shippingCost,
      taxAmount: taxRate,
      total: total,
      totalItems: totalItems,
    );
  }

  /// Creates empty cart summary
  static CartSummary empty() => const CartSummary(
        items: [],
        subtotal: 0.0,
        shippingCost: 0.0,
        taxAmount: 0.0,
        total: 0.0,
        totalItems: 0,
      );

  /// Checks if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Checks if cart has items
  bool get isNotEmpty => items.isNotEmpty;
}

/// Cart Stock Validation Model - Represents stock validation result for a cart item
///
/// This model contains information about stock availability and suggested adjustments
/// for individual cart items. Used by the stock validation system.
class CartStockValidation {
  final int cartId;
  final int variantId;
  final String productName;
  final String variantName;
  final int currentQuantity;
  final int availableStock;
  final int suggestedQuantity;
  final bool needsAdjustment;
  final String adjustmentReason;
  final bool shouldRemove;

  const CartStockValidation({
    required this.cartId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.currentQuantity,
    required this.availableStock,
    required this.suggestedQuantity,
    required this.needsAdjustment,
    required this.adjustmentReason,
    required this.shouldRemove,
  });

  /// Factory constructor to create from database response
  factory CartStockValidation.fromJson(Map<String, dynamic> json) {
    return CartStockValidation(
      cartId: json['cart_id'] as int? ?? -1,
      variantId: json['variant_id'] as int? ?? -1,
      productName: json['product_name'] as String? ?? '',
      variantName: json['variant_name'] as String? ?? '',
      currentQuantity: json['current_quantity'] as int? ?? 0,
      availableStock: json['available_stock'] as int? ?? 0,
      suggestedQuantity: json['suggested_quantity'] as int? ?? 0,
      needsAdjustment: json['needs_adjustment'] as bool? ?? false,
      adjustmentReason: json['adjustment_reason'] as String? ?? '',
      shouldRemove: json['should_remove'] as bool? ?? false,
    );
  }

  /// Converts to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'current_quantity': currentQuantity,
      'available_stock': availableStock,
      'suggested_quantity': suggestedQuantity,
      'needs_adjustment': needsAdjustment,
      'adjustment_reason': adjustmentReason,
      'should_remove': shouldRemove,
    };
  }

  /// Gets user-friendly adjustment message
  String get adjustmentMessage {
    if (shouldRemove) {
      return adjustmentReason;
    } else if (needsAdjustment && suggestedQuantity < currentQuantity) {
      return 'Quantity reduced from $currentQuantity to $suggestedQuantity - $adjustmentReason';
    }
    return adjustmentReason;
  }

  /// Gets adjustment type for UI display
  CartAdjustmentType get adjustmentType {
    if (shouldRemove) {
      return CartAdjustmentType.remove;
    } else if (needsAdjustment) {
      return CartAdjustmentType.quantityReduced;
    }
    return CartAdjustmentType.none;
  }

  @override
  String toString() {
    return 'CartStockValidation{cartId: $cartId, productName: $productName, needsAdjustment: $needsAdjustment, adjustmentReason: $adjustmentReason}';
  }
}

/// Enum for cart adjustment types
enum CartAdjustmentType {
  none,
  quantityReduced,
  remove,
}

/// Extension for CartAdjustmentType to get user-friendly labels
extension CartAdjustmentTypeExtension on CartAdjustmentType {
  String get label {
    switch (this) {
      case CartAdjustmentType.none:
        return '';
      case CartAdjustmentType.quantityReduced:
        return 'Quantity Updated';
      case CartAdjustmentType.remove:
        return 'Item Removed';
    }
  }

  bool get isAdjustment => this != CartAdjustmentType.none;
}
