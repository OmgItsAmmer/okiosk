import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../features/categories/models/category_model.dart';
import '../../../utils/exceptions/TFormatException.dart';
import '../../backend/services/category_api_service.dart';

/// Backend Category Repository - Handles all category-related API operations
///
/// This repository uses the backend API instead of direct Supabase calls.
/// It follows the Repository Pattern and provides a clean interface for category operations.
class BackendCategoryRepository {
  final CategoryApiService _categoryApiService = Get.find<CategoryApiService>();

  /// Get all categories from backend
  ///
  /// Calls: GET /api/categories/all
  /// Returns list of categories sorted alphabetically with "More" category at the end
  Future<List<CategoryModel>> getAllCategories(
      {bool featuredOnly = false}) async {
    try {
      if (kDebugMode) {
        print(
            'BackendCategoryRepository: Fetching categories (featured_only: $featuredOnly)');
      }

      final response = await _categoryApiService.getAllCategories(
        featuredOnly: featuredOnly,
      );

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final categoriesData = response.data!['categories'] as List<dynamic>;

      if (kDebugMode) {
        print(
            'BackendCategoryRepository: Received ${categoriesData.length} categories');
      }

      // Convert each JSON object to CategoryModel
      final List<CategoryModel> categories =
          categoriesData.map((json) => CategoryModel.fromJson(json)).toList();

      // Sort categories to ensure "More" category always comes at the end
      categories.sort((a, b) {
        // If category name is "More", it should come last
        if (a.categoryName.toLowerCase() == 'more') return 1;
        if (b.categoryName.toLowerCase() == 'more') return -1;

        // For other categories, maintain alphabetical order
        return a.categoryName.compareTo(b.categoryName);
      });

      if (kDebugMode) {
        print(
            'BackendCategoryRepository: Returning ${categories.length} sorted categories');
      }

      return categories;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      if (kDebugMode) {
        print('BackendCategoryRepository Error: $e');
      }
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get category by ID
  ///
  /// Calls: GET /api/categories/:category_id
  Future<CategoryModel?> getCategoryById(int categoryId) async {
    try {
      if (kDebugMode) {
        print('BackendCategoryRepository: Fetching category $categoryId');
      }

      final response = await _categoryApiService.getCategoryById(categoryId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final categoryData = response.data!['category'];

      return CategoryModel.fromJson(categoryData);
    } catch (e) {
      if (kDebugMode) {
        print('BackendCategoryRepository Error: $e');
      }
      return null;
    }
  }

  /// Get category statistics
  ///
  /// Calls: GET /api/categories/stats
  Future<Map<String, int>> getCategoryStats() async {
    try {
      if (kDebugMode) {
        print('BackendCategoryRepository: Fetching category stats');
      }

      final response = await _categoryApiService.getCategoryStats();

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return {
        'total_categories': response.data!['total_categories'] ?? 0,
        'featured_categories': response.data!['featured_categories'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('BackendCategoryRepository Error: $e');
      }
      return {
        'total_categories': 0,
        'featured_categories': 0,
      };
    }
  }
}
