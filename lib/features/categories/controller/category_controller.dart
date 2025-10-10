import 'package:okiosk/common/widgets/loaders/tloaders.dart';
import 'package:get/get.dart';

import '../../../data/repositories/categories/backend_category_repository.dart';
import '../models/category_model.dart';
import '../../products/models/product_model.dart';

class CategoryController extends GetxController {
  static CategoryController get instance => Get.find();

  final isLoading = false.obs;
  final _categoryRepository = Get.find<BackendCategoryRepository>();
  final RxList<CategoryModel> allCategories = <CategoryModel>[].obs;

  // Category selection state
  final _selectedCategoryId = Rx<int?>(null);

  // Product filtering state
  final RxList<ProductModel> _allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> _filteredProducts = <ProductModel>[].obs;

  // Getters
  int? get selectedCategoryId => _selectedCategoryId.value;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<ProductModel> get allProducts => _allProducts;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  // Load category data
  Future<void> fetchCategories() async {
    try {
      // Show loader while loading categories
      isLoading.value = true;

      // Fetch categories from the repository
      final categories = await _categoryRepository.getAllCategories();

      // Update the categories list
      allCategories.assignAll(categories);
    } catch (e) {
      TLoader.errorSnackBar(title: 'Oh Snap', message: e.toString());
    } finally {
      // Remove loader
      isLoading.value = false;
    }
  }

  /// Set all products for filtering
  void setProducts(List<ProductModel> products) {
    _allProducts.assignAll(products);
    _filteredProducts.assignAll(products);
  }

  /// Select a category and filter products
  void selectCategory(int? categoryId) {
    _selectedCategoryId.value = categoryId;

    if (categoryId == null) {
      // Show all products
      _filteredProducts.assignAll(_allProducts);
    } else {
      // Filter products by category
      _filteredProducts.assignAll(
        _allProducts
            .where((product) => product.categoryId == categoryId)
            .toList(),
      );
    }
  }

  /// Clear category selection
  void clearCategorySelection() {
    selectCategory(null);
  }

  /// Get selected category
  CategoryModel? get selectedCategory {
    if (_selectedCategoryId.value == null) return null;
    return allCategories.firstWhereOrNull(
      (cat) => cat.categoryId == _selectedCategoryId.value,
    );
  }
}
