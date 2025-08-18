
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:okiosk/features/products/controller/product_controller.dart';

import '../../../common/widgets/loaders/tloaders.dart';
import '../../../data/repositories/products/product_repository.dart';
import '../models/product_variation_model.dart';


/// A controller class for managing product variations, including variant availability,
/// selection, and stock checks.
///
/// This class provides methods to fetch product variations, check variant availability,
/// handle variant selection, and perform stock-related operations.
class ProductVariationController extends GetxController {
  /// Singleton instance of [ProductVariationController].
  static ProductVariationController get instance => Get.find();

  /// Repository for fetching product-related data.
  final productRepository = Get.find<ProductRepository>();

  /// Observable flag indicating whether the controller is loading data.
  final isLoading = false.obs;
  final isVariantLoading = false.obs;

  /// List of all product variations for the current product.
  RxList<ProductVariationModel> allProductVariations =
      <ProductVariationModel>[].obs;

  /// Reference to the [ProductController] for product-related operations.
  late final ProductController productController =
      Get.find<ProductController>();

  /// Observable model representing the currently selected product variation.
  Rx<ProductVariationModel> selectedVariationProduct =
      ProductVariationModel.empty().obs;

  /// Observable string representing the currently selected variant.
  Rx<String> selectedVariant = Rx<String>('');

  /// Observable integer representing the quantity of the selected product.
  Rx<int> itemQuantity = Rx<int>(1);

  /// Current product ID for validation
  int? _currentProductId;

  /// Resets the controller state when switching between products
  void resetController() {
    selectedVariationProduct.value = ProductVariationModel.empty();
    selectedVariant.value = '';
    itemQuantity.value = 1;
    allProductVariations.clear();
    allProductVariations.refresh();
    _currentProductId = null;
  }

  /// Fetches product variations for the given [productId].
  Future<void> fetchProductVariantByProductId(int productId) async {
    try {
      isLoading.value = true;

      // Reset controller state before fetching new variations
      resetController();

      // Set current product ID for validation
      _currentProductId = productId;

      final products =
          await productRepository.fetchProductVariationsWithID(productId);

      // Update the product variations list
      allProductVariations.assignAll(products);
      allProductVariations.refresh();

      // Automatically select the first available variant if any exist
      if (allProductVariations.isNotEmpty) {
        autoSelectVariant();
      }
    } catch (e) {
      TLoader.errorSnackBar(title: 'Oh Snap!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void autoSelectVariant() {
    if (allProductVariations.isNotEmpty) {
      // Find the first in-stock variant
      for (var variation in allProductVariations) {
        if (isVariationInStock(variation.variantName ?? '')) {
          selectVariant(variation.variantName ?? '');
          break;
        }
      }
    }
  }

  ///Fetch product variantios from the given [variantId]
  Future<ProductVariationModel?> fetchProductVariantByVariantId(
      int variantId) async {
    try {
      isLoading.value = true;

      // Reset controller state before fetching new variations
      resetController();

      final products =
          await productRepository.fetchProductVariationsByVariantId(variantId);
      allProductVariations.assignAll(products);
      allProductVariations.refresh();
      return products.first;
    } catch (e) {
      TLoader.errorSnackBar(title: 'Oh Snap!', message: e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles the selection of a product variant.
  ///
  /// [variantName]: The variant name to select.
  void selectVariant(String variantName) {
    selectedVariant.value = variantName;

    // Find the product variation for the selected variant
    final selectedProduct = allProductVariations.firstWhere(
      (product) => product.variantName == variantName,
      orElse: () => ProductVariationModel.empty(),
    );

    selectedVariationProduct.value = selectedProduct;
  }

  /// Retrieves a product variation by its variant name.
  ///
  /// [variantName]: The variant name to look up.
  /// Returns the matching [ProductVariationModel] or `null` if not found.
  ProductVariationModel? getVariationByName(String variantName) {
    try {
      return allProductVariations.firstWhere(
        (variation) => variation.variantName == variantName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Checks if a product variation is available and in stock.
  ///
  /// [variantName]: The variant name to check.
  /// Returns `true` if the variation is available and in stock, otherwise `false`.
  bool isVariationInStock(String variantName) {
    final variation = getVariationByName(variantName);
    if (variation?.stockQuantity == null || variation!.stockQuantity.isEmpty) {
      return false;
    }
    final stock = int.tryParse(variation.stockQuantity) ?? 0;
    return stock > 0;
  }

  /// Checks if a product variation is visible.
  ///
  /// [variantName]: The variant name to check.
  /// Returns `true` if the variation is visible, otherwise `false`.
  bool isVariationVisible(String variantName) {
    final variation = getVariationByName(variantName);
    return variation?.isVisible ?? false;
  }

  /// Retrieves a list of all visible variants for the current product.
  /// Since we now only fetch visible variants, this returns all fetched variants.
  ///
  /// Returns a list of visible variant names.
  List<String> getVisibleVariants() {
    isVariantLoading.value = true;

    try {
      return allProductVariations
          .map((variation) => variation.variantName ?? '')
          .where((variantName) => variantName.isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return [];
    } finally {
      isVariantLoading.value = false;
    }
  }

  /// Retrieves a list of available (visible and in stock) variants for the current product.
  ///
  /// Returns a list of available variant names.
  List<String> getAvailableVariants() {
    return allProductVariations
        .where((variation) {
          final stock = int.tryParse(variation.stockQuantity) ?? 0;
          return stock > 0;
        })
        .map((variation) => variation.variantName ?? '')
        .where((variantName) => variantName.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Retrieves a list of out of stock but visible variants for the current product.
  ///
  /// Returns a list of out of stock variant names.
  List<String> getOutOfStockVariants() {
    return allProductVariations
        .where((variation) {
          final stock = int.tryParse(variation.stockQuantity) ?? 0;
          return stock <= 0;
        })
        .map((variation) => variation.variantName ?? '')
        .where((variantName) => variantName.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Checks if the selected variant is the given variant name.
  ///
  /// [variantName]: The variant name to check.
  /// Returns `true` if the variant is selected, otherwise `false`.
  bool isVariantSelected(String variantName) {
    return selectedVariant.value == variantName;
  }

  /// Checks if the controller has a valid selected variant for the current product.
  ///
  /// Returns `true` if a valid variant is selected, otherwise `false`.
  bool hasValidSelectedVariant() {
    final variant = selectedVariationProduct.value;
    return variant.variantId > 0 &&
        variant.variantName != null &&
        variant.variantName!.isNotEmpty &&
        variant.productId == _currentProductId;
  }

  /// Gets the current product ID for validation purposes.
  ///
  /// Returns the current product ID or null if not set.
  int? getCurrentProductId() {
    return _currentProductId;
  }

  ///get the variant name from the variant id
  getVariantName(int? variantId) {
    try {
      if (variantId == null) return '';
      final variantName = allProductVariations
              .firstWhere((variation) => variation.variantId == variantId)
              .variantName ??
          '';

      return variantName;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return '';
    }
  }

  //get product id from the variant id
  getProductId(int? variantId) {
    try {
      if (variantId == null) return 0;
      return allProductVariations
          .firstWhere((variation) => variation.variantId == variantId)
          .productId;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return 0;
    }
  }
}
