import 'package:get/get.dart';
import 'package:okiosk/features/categories/controller/category_controller.dart';
import 'package:okiosk/features/products/controller/product_controller.dart';
import 'package:okiosk/features/products/models/product_model.dart';
import 'package:okiosk/features/cart/model/cart_model.dart';
import 'package:okiosk/features/cart/controller/cart_controller.dart';
import 'package:okiosk/utils/constants/enums.dart';
import 'package:flutter/foundation.dart';

/// POS Controller managing the state of the Point of Sale kiosk interface
///
/// This controller handles:
/// - Category selection and filtering
/// - Product display and selection
/// - Cart management (add, remove, update quantities)
/// - Payment method selection
/// - Checkout process
class PosController extends GetxController {
  static PosController get instance => Get.find();

  // Observable state variables
  final _products = <ProductModel>[].obs;
  final _cartItems = <CartItemModel>[].obs;
  final _selectedPaymentMethod = PaymentMethods.cash.obs;
  final _selectedShippingMethod = ShippingMethods.pickup.obs;
  final _isLoading = false.obs;
  final _cartTotal = 0.0.obs;
  final _taxAmount = 0.0.obs;
  final _subTotal = 0.0.obs;

  // Get CategoryController instance
  CategoryController get categoryController => Get.find<CategoryController>();
  // Get ProductController instance
  final ProductController productController = Get.find<ProductController>();
  // Get CartController instance (single source of truth for cart)
  final CartController cartController = Get.find<CartController>();

  // Getters for reactive state
  List<ProductModel> get products => _products;
  List<ProductModel> get filteredProducts =>
      productController.filteredProductsForPOS;
  List<CartItemModel> get cartItems => _cartItems;
  PaymentMethods get selectedPaymentMethod => _selectedPaymentMethod.value;
  ShippingMethods get selectedShippingMethod => _selectedShippingMethod.value;
  bool get isLoading => _isLoading.value;
  double get cartTotal => _cartTotal.value;
  double get taxAmount => _taxAmount.value;
  double get subTotal => _subTotal.value;
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.cart.quantityAsInt);

  @override
  void onInit() {
    super.onInit();
    _initializeData();

    // Mirror cart items from CartController so sidebar stays in sync
    ever<List<CartItemModel>>(cartController.cartItems, (items) {
      if (kDebugMode) {
        print(
            'PosController: CartController items changed - ${items.length} items');
        for (int i = 0; i < items.length; i++) {
          print('PosController: Syncing item $i - ${items[i].productName}');
        }
      }
      _cartItems.assignAll(items);
      _updateCartTotals();
      if (kDebugMode) {
        print(
            'PosController: Cart items synchronized - ${_cartItems.length} items in POS controller');
      }
    });
  }

  /// Initialize data for the POS system
  Future<void> _initializeData() async {
    _isLoading.value = true;

    try {
      // Check if products are already loaded (from login)
      if (productController.allProductsForPOS.isEmpty) {
        // Load ALL products if not already loaded
        await productController.loadAllProductsForPOS();
      }

      // Set products in category controller for filtering
      categoryController.setProducts(productController.allProductsForPOS);

      if (kDebugMode) {
        print('POS Controller initialized');
        print('Total products: ${productController.allProductsForPOS.length}');
        print('Categories: ${categoryController.allCategories.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing POS data: $e');
      }
      // Fallback to dummy data if real data fails
    //  categoryController.initializeWithDummyCategories();
      _products.assignAll(_generateDummyProducts());
      categoryController.setProducts(_products);
    } finally {
      _isLoading.value = false;
    }
  }

  /// Add product to cart
  void addToCart(ProductModel product) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.productName == product.name,
    );

    if (existingItemIndex != -1) {
      // Update existing item quantity
      final existingItem = _cartItems[existingItemIndex];
      final newQuantity = existingItem.cart.quantityAsInt + 1;
      updateCartItemQuantity(existingItem, newQuantity);
    } else {
      // Create a basic cart item locally when needed (fallback)
      final sell = double.tryParse(product.salePrice.isNotEmpty
              ? product.salePrice
              : product.basePrice) ??
          0.0;
      final buy = double.tryParse(product.basePrice);
      final cartItem = CartItemModel(
        cart: CartModel(
          cartId: DateTime.now().millisecondsSinceEpoch,
          variantId: 1,
          quantity: "1",
          customerId: 0,
        ),
        productName: product.name,
        productDescription: product.description ?? '',
        basePrice: product.basePrice,
        salePrice: (product.salePrice.isNotEmpty
            ? product.salePrice
            : product.basePrice),
        brandId: product.brandID,
        variantName: 'Default',
        sellPrice: sell,
        buyPrice: buy,
        stock: product.stockQuantity,
        isVisible: product.isVisible,
      );
      _cartItems.add(cartItem);
      _updateCartTotals();
    }
  }

  /// Remove product from cart
  void removeFromCart(CartItemModel cartItem) {
    // Delegate to CartController so single source of truth updates
    cartController.removeCartItem(cartItem);
  }

  /// Update cart item quantity
  void updateCartItemQuantity(CartItemModel cartItem, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartItem);
      return;
    }
    cartController.updateCartItemQuantity(cartItem, quantity);
  }

  /// Clear entire cart
  void clearCart() {
    cartController.clearCart();
  }

  /// Update cart totals
  void _updateCartTotals() {
    _subTotal.value =
        _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    _taxAmount.value = _subTotal.value * 0.1; // 10% tax
    _cartTotal.value = _subTotal.value + _taxAmount.value;
  }

  /// Select payment method
  void selectPaymentMethod(PaymentMethods method) {
    _selectedPaymentMethod.value = method;
  }

  /// Select shipping method
  void selectShippingMethod(ShippingMethods method) {
    _selectedShippingMethod.value = method;
  }

  /// Process checkout
  Future<void> processCheckout() async {
    if (_cartItems.isEmpty) {
      Get.snackbar(
        'Cart Empty',
        'Please add items to cart before checkout',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    _isLoading.value = true;

    try {
      // Simulate checkout process
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart after successful checkout
      clearCart();

      Get.snackbar(
        'Checkout Successful',
        'Payment processed successfully!',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Checkout Failed',
        'An error occurred during checkout. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Generate dummy products
  List<ProductModel> _generateDummyProducts() {
    return [
      // Electronics
      ProductModel(
        priceRange: '599.99 - 549.99',
        productId: 1,
        name: 'Smartphone',
        description: 'Latest Android smartphone with premium features',
        basePrice: '599.99',
        salePrice: '549.99',
        categoryId: 1,
        stockQuantity: 15,
        createdAt: DateTime.now(),
        brandID: 1,
        alertStock: 5,
        tag: ProductTag.sale.name,
        isPopular: true,
        isVisible: true,
      ),
      //     ProductModel(
      //       productId: 2,
      //       name: 'Laptop',
      //       description: 'High-performance laptop for work and gaming',
      //       basePrice: '1299.99',
      //       salePrice: '1199.99',
      //       categoryId: 1,
      //       stockQuantity: 8,
      //       createdAt: DateTime.now(),
      //       brandID: 1,
      //       alertStock: 3,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 3,
      //       name: 'Wireless Headphones',
      //       description: 'Premium noise-cancelling wireless headphones',
      //       basePrice: '299.99',
      //       salePrice: '249.99',
      //       categoryId: 1,
      //       stockQuantity: 20,
      //       createdAt: DateTime.now(),
      //       brandID: 1,
      //       alertStock: 5,
      //       tag: ProductTag.sale.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 4,
      //       name: 'Tablet',
      //       description:
      //           '10-inch tablet perfect for entertainment and productivity',
      //       basePrice: '449.99',
      //       salePrice: '399.99',
      //       categoryId: 1,
      //       stockQuantity: 12,
      //       createdAt: DateTime.now(),
      //       brandID: 1,
      //       alertStock: 4,
      //       tag: ProductTag.new_product.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 5,
      //       name: 'Smart Watch',
      //       description: 'Advanced smartwatch with health monitoring',
      //       basePrice: '199.99',
      //       salePrice: '179.99',
      //       categoryId: 1,
      //       stockQuantity: 25,
      //       createdAt: DateTime.now(),
      //       brandID: 1,
      //       alertStock: 8,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),

      //     // Clothing
      //     ProductModel(
      //       productId: 6,
      //       name: 'Cotton T-Shirt',
      //       description: 'Premium cotton t-shirt available in multiple colors',
      //       basePrice: '29.99',
      //       salePrice: '24.99',
      //       categoryId: 2,
      //       stockQuantity: 50,
      //       createdAt: DateTime.now(),
      //       brandID: 2,
      //       alertStock: 10,
      //       tag: ProductTag.sale.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 7,
      //       name: 'Jeans',
      //       description: 'Classic denim jeans with modern fit',
      //       basePrice: '79.99',
      //       salePrice: '69.99',
      //       categoryId: 2,
      //       stockQuantity: 30,
      //       createdAt: DateTime.now(),
      //       brandID: 2,
      //       alertStock: 8,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 8,
      //       name: 'Winter Jacket',
      //       description: 'Warm and stylish winter jacket',
      //       basePrice: '149.99',
      //       salePrice: '129.99',
      //       categoryId: 2,
      //       stockQuantity: 18,
      //       createdAt: DateTime.now(),
      //       brandID: 2,
      //       alertStock: 5,
      //       tag: ProductTag.featured.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 9,
      //       name: 'Running Shoes',
      //       description: 'Comfortable running shoes for all terrains',
      //       basePrice: '89.99',
      //       salePrice: '79.99',
      //       categoryId: 2,
      //       stockQuantity: 22,
      //       createdAt: DateTime.now(),
      //       brandID: 2,
      //       alertStock: 6,
      //       tag: ProductTag.new_product.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),

      //     // Books
      //     ProductModel(
      //       productId: 10,
      //       name: 'Programming Guide',
      //       description: 'Complete guide to modern programming practices',
      //       basePrice: '49.99',
      //       salePrice: '39.99',
      //       categoryId: 3,
      //       stockQuantity: 15,
      //       createdAt: DateTime.now(),
      //       brandID: 3,
      //       alertStock: 3,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 11,
      //       name: 'Science Fiction Novel',
      //       description: 'Bestselling science fiction adventure',
      //       basePrice: '19.99',
      //       salePrice: '16.99',
      //       categoryId: 3,
      //       stockQuantity: 25,
      //       createdAt: DateTime.now(),
      //       brandID: 3,
      //       alertStock: 5,
      //       tag: ProductTag.sale.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 12,
      //       name: 'Cookbook',
      //       description: 'Collection of healthy and delicious recipes',
      //       basePrice: '34.99',
      //       salePrice: '29.99',
      //       categoryId: 3,
      //       stockQuantity: 20,
      //       createdAt: DateTime.now(),
      //       brandID: 3,
      //       alertStock: 4,
      //       tag: ProductTag.new_product.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),

      //     // Home & Garden
      //     ProductModel(
      //       productId: 13,
      //       name: 'Plant Pot Set',
      //       description: 'Beautiful ceramic plant pots for indoor gardening',
      //       basePrice: '39.99',
      //       salePrice: '34.99',
      //       categoryId: 4,
      //       stockQuantity: 35,
      //       createdAt: DateTime.now(),
      //       brandID: 4,
      //       alertStock: 8,
      //           tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 14,
      //       name: 'LED Lamp',
      //       description: 'Modern LED desk lamp with adjustable brightness',
      //       basePrice: '59.99',
      //       salePrice: '49.99',
      //       categoryId: 4,
      //       stockQuantity: 18,
      //       createdAt: DateTime.now(),
      //       brandID: 4,
      //       alertStock: 5,
      //       tag: ProductTag.sale.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 15,
      //       name: 'Garden Tools Set',
      //       description: 'Complete set of essential garden tools',
      //       basePrice: '89.99',
      //       salePrice: '79.99',
      //       categoryId: 4,
      //       stockQuantity: 12,
      //       createdAt: DateTime.now(),
      //       brandID: 4,
      //       alertStock: 3,
      //       tag: ProductTag.new_product.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 16,
      //       name: 'Wall Clock',
      //       description: 'Elegant wall clock with silent movement',
      //       basePrice: '45.99',
      //       salePrice: '39.99',
      //       categoryId: 4,
      //       stockQuantity: 22,
      //       createdAt: DateTime.now(),
      //       brandID: 4,
      //       alertStock: 6,
      //       tag: ProductTag.featured.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),

      //     // Sports
      //     ProductModel(
      //       productId: 17,
      //       name: 'Basketball',
      //       description: 'Official size basketball for indoor and outdoor play',
      //       basePrice: '24.99',
      //       salePrice: '21.99',
      //       categoryId: 5,
      //       stockQuantity: 40,
      //       createdAt: DateTime.now(),
      //       brandID: 5,
      //       alertStock: 10,
      //       tag: ProductTag.sale.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 18,
      //       name: 'Yoga Mat',
      //       description: 'Non-slip yoga mat for comfortable workouts',
      //       basePrice: '34.99',
      //       salePrice: '29.99',
      //       categoryId: 5,
      //       stockQuantity: 28,
      //       createdAt: DateTime.now(),
      //       brandID: 5,
      //       alertStock: 8,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 19,
      //       name: 'Dumbbells Set',
      //       description: 'Adjustable dumbbells for strength training',
      //       basePrice: '149.99',
      //       salePrice: '129.99',
      //       categoryId: 5,
      //       stockQuantity: 15,
      //       createdAt: DateTime.now(),
      //       brandID: 5,
      //       alertStock: 4,
      //       tag: ProductTag.new_product.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),

      //     // Food & Beverage
      //     ProductModel(
      //       productId: 20,
      //       name: 'Organic Coffee',
      //       description: 'Premium organic coffee beans from single origin',
      //       basePrice: '18.99',
      //       salePrice: '15.99',
      //       categoryId: 6,
      //       stockQuantity: 60,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 15,
      //       tag: ProductTag.sale.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 21,
      //       name: 'Green Tea',
      //       description: 'High-quality green tea with antioxidants',
      //       basePrice: '12.99',
      //       salePrice: '10.99',
      //       categoryId: 6,
      //       stockQuantity: 45,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 12,
      //       tag: ProductTag.featured.name,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 22,
      //       name: 'Protein Bar',
      //       description: 'High-protein energy bar for active lifestyle',
      //       basePrice: '3.99',
      //       salePrice: '3.49',
      //       categoryId: 6,
      //       stockQuantity: 100,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 25,
      //       tag: ProductTag.new_product.name,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 23,
      //       name: 'Honey',
      //       description: 'Pure natural honey from local beekeepers',
      //       basePrice: '14.99',
      //       salePrice: '12.99',
      //       categoryId: 6,
      //       stockQuantity: 35,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 8,
      //       productTag: ProductTag.featured,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 24,
      //       name: 'Olive Oil',
      //       description: 'Extra virgin olive oil for cooking and salads',
      //       basePrice: '22.99',
      //       salePrice: '19.99',
      //       categoryId: 6,
      //       stockQuantity: 28,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 7,
      //       productTag: ProductTag.sale,
      //       isPopular: false,
      //       isVisible: true,
      //     ),
      //     ProductModel(
      //       productId: 25,
      //       name: 'Sparkling Water',
      //       description: 'Refreshing sparkling water with natural flavors',
      //       basePrice: '2.99',
      //       salePrice: '2.49',
      //       categoryId: 6,
      //       stockQuantity: 80,
      //       createdAt: DateTime.now(),
      //       brandID: 6,
      //       alertStock: 20,
      //       productTag: ProductTag.new_product,
      //       isPopular: true,
      //       isVisible: true,
      //     ),
      //   ];
      // }
    ];
  }
}
