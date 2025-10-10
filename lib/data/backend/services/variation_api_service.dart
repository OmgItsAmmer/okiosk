import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/product_api_models.dart';
import 'api_client.dart';

/// Service class for Product Variation API operations
class VariationApiService extends GetxService {
  static VariationApiService get instance => Get.find();

  final ApiClient _apiClient = ApiClient();

  /// Get variation by ID
  Future<ApiResponse<ProductVariationApiModel>> getVariationById(
      int variationId) async {
    try {
      final response = await _apiClient.get<ProductVariationApiModel>(
        '/api/variations/$variationId',
        fromJson: (data) => ProductVariationApiModel.fromJson(data),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get variation by ID error: $e');
      }
      return ApiResponse<ProductVariationApiModel>(
        success: false,
        message: 'Failed to get variation by ID',
      );
    }
  }

  /// Get related variations
  Future<ApiResponse<List<RelatedVariationApiModel>>> getRelatedVariations(
      int variationId) async {
    try {
      final response = await _apiClient.get<List<RelatedVariationApiModel>>(
        '/api/variations/$variationId/related',
        fromJson: (data) => (data as List)
            .map((item) => RelatedVariationApiModel.fromJson(item))
            .toList(),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get related variations error: $e');
      }
      return ApiResponse<List<RelatedVariationApiModel>>(
        success: false,
        message: 'Failed to get related variations',
      );
    }
  }

  /// Get variation stock
  Future<ApiResponse<Map<String, dynamic>>> getVariationStock(
      int variationId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/variations/$variationId/stock',
        fromJson: (data) => Map<String, dynamic>.from(data),
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get variation stock error: $e');
      }
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Failed to get variation stock',
      );
    }
  }

  @override
  void onClose() {
    _apiClient.dispose();
    super.onClose();
  }
}
