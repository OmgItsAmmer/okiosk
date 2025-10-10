import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import '../models/api_response.dart';

/// Category API Service - Handles all category-related backend API calls
///
/// This service follows the API specification in CATEGORY_MODULE.md and provides
/// methods for fetching categories and statistics.
class CategoryApiService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Get all categories
  ///
  /// Endpoint: GET /api/categories/all
  /// Query params: featured_only (optional boolean)
  /// Returns list of categories with product counts
  Future<ApiResponse<Map<String, dynamic>>> getAllCategories({
    bool featuredOnly = false,
  }) async {
    try {
      if (kDebugMode) {
        print(
            'CategoryApiService: Fetching categories (featured_only: $featuredOnly)');
      }

      final queryParams = featuredOnly ? {'featured_only': 'true'} : null;

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/categories/all',
        queryParams: queryParams,
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CategoryApiService: Response - ${response.message}');
        if (response.data != null) {
          print(
              'CategoryApiService: Categories count - ${response.data!['total_count']}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CategoryApiService: Error fetching categories - $e');
      }
      rethrow;
    }
  }

  /// Get category by ID
  ///
  /// Endpoint: GET /api/categories/:category_id
  /// Returns single category with details
  Future<ApiResponse<Map<String, dynamic>>> getCategoryById(
      int categoryId) async {
    try {
      if (kDebugMode) {
        print('CategoryApiService: Fetching category $categoryId');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/categories/$categoryId',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CategoryApiService: Category response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CategoryApiService: Error fetching category - $e');
      }
      rethrow;
    }
  }

  /// Get category statistics
  ///
  /// Endpoint: GET /api/categories/stats
  /// Returns total categories count and featured categories count
  Future<ApiResponse<Map<String, dynamic>>> getCategoryStats() async {
    try {
      if (kDebugMode) {
        print('CategoryApiService: Fetching category statistics');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/categories/stats',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      if (kDebugMode) {
        print('CategoryApiService: Stats response - ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('CategoryApiService: Error fetching stats - $e');
      }
      rethrow;
    }
  }
}
