import 'package:flutter/foundation.dart';

import 'package:get/get.dart';
import 'dart:io';

import '../../../data/repositories/media/media_repository.dart';
import '../controllers/image_cache_controller.dart';
import '../models/image_model.dart';

class MediaOwnerImage {
  int ownerId;
  String ownerType;
  ImageModel image;

  MediaOwnerImage({
    required this.ownerId,
    required this.ownerType,
    required this.image,
  });
}

class MediaController extends GetxController {
  static MediaController get instance => Get.find();
  final MediaRepository _mediaRepository = Get.put(MediaRepository());

  // New cache controller for persistent caching
  ImageCacheController? _cacheController;

  // Legacy cache for storing fetched images to avoid repeated API calls (kept for compatibility)
  final RxMap<String, String> _imageCache = <String, String>{}.obs;
  final RxMap<String, List<String>> _multipleImagesCache =
      <String, List<String>>{}.obs;

  // Loading states
  final RxBool isLoading = false.obs;
  final RxMap<String, bool> _entityLoadingStates = <String, bool>{}.obs;

  // Upload states
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize cache controller if available
    if (Get.isRegistered<ImageCacheController>()) {
      _cacheController = Get.find<ImageCacheController>();
    }
  }

  /// Fetch main image URL for a single entity with caching
  Future<String?> fetchMainImage(int entityId, String entityType) async {
    final cacheKey = '${entityType}_${entityId}_main';

    // Try persistent cache first if available
    if (_cacheController != null) {
      try {
        final cacheResult =
            await _cacheController!.getMainImageWithCache(entityId, entityType);
        if (cacheResult.success) {
          // Update legacy cache for compatibility
          if (cacheResult.imageUrl != null) {
            _imageCache[cacheKey] = cacheResult.imageUrl!;
            return cacheResult.imageUrl;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              '⚠️ MediaController: Cache controller error, falling back to repository: $e');
        }
      }
    }

    // Return legacy cached image if available
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      // Set loading state for this specific entity
      _entityLoadingStates[cacheKey] = true;

      final imageUrl =
          await _mediaRepository.fetchMainImageUrl(entityId, entityType);

      if (imageUrl != null) {
        _imageCache[cacheKey] = imageUrl;
        return imageUrl;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ MediaController: Error fetching main image for $entityType $entityId: $e');
      }
      return null;
    } finally {
      _entityLoadingStates[cacheKey] = false;
    }
  }

  /// Fetch all images for a single entity with caching
  Future<List<String>> fetchAllImagesForEntity(
      int entityId, String entityType) async {
    final cacheKey = '${entityType}_${entityId}_all';

    // Return cached images if available
    if (_multipleImagesCache.containsKey(cacheKey)) {
      return _multipleImagesCache[cacheKey]!;
    }

    try {
      _entityLoadingStates[cacheKey] = true;

      final imageUrls =
          await _mediaRepository.fetchAllImagesForEntity(entityId, entityType);

      _multipleImagesCache[cacheKey] = imageUrls;
      return imageUrls;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ MediaController: Error fetching all images for $entityType $entityId: $e');
      }
      return [];
    } finally {
      _entityLoadingStates[cacheKey] = false;
    }
  }

  /// Fetch main images for multiple entities (optimized for lists like product grids)
  Future<Map<int, String>> fetchMultipleMainImages(
      List<int> entityIds, String entityType) async {
    if (entityIds.isEmpty) return {};

    try {
      isLoading.value = true;

      // Check cache for existing images
      Map<int, String> cachedImages = {};
      List<int> uncachedIds = [];

      for (int entityId in entityIds) {
        final cacheKey = '${entityType}_${entityId}_main';
        if (_imageCache.containsKey(cacheKey)) {
          cachedImages[entityId] = _imageCache[cacheKey]!;
        } else {
          uncachedIds.add(entityId);
        }
      }

      // Fetch uncached images
      if (uncachedIds.isNotEmpty) {
        final fetchedImages = await _mediaRepository.fetchMultipleMainImages(
            uncachedIds, entityType);

        // Cache the fetched images
        fetchedImages.forEach((entityId, imageUrl) {
          final cacheKey = '${entityType}_${entityId}_main';
          _imageCache[cacheKey] = imageUrl;
          cachedImages[entityId] = imageUrl;
        });
      }

      return cachedImages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MediaController: Error fetching multiple main images: $e');
      }
      return {};
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if an entity has images
  Future<bool> hasImages(int entityId, String entityType) async {
    try {
      return await _mediaRepository.hasImages(entityId, entityType);
    } catch (e) {
      if (kDebugMode) {
        print('❌ MediaController: Error checking if entity has images: $e');
      }
      return false;
    }
  }

  /// Get cached image URL (useful for immediate UI updates)
  String? getCachedMainImage(int entityId, String entityType) {
    final cacheKey = '${entityType}_${entityId}_main';
    return _imageCache[cacheKey];
  }

  /// Get cached all images for entity
  List<String>? getCachedAllImages(int entityId, String entityType) {
    final cacheKey = '${entityType}_${entityId}_all';
    return _multipleImagesCache[cacheKey];
  }

  /// Check if entity is currently being loaded
  bool isEntityLoading(int entityId, String entityType,
      {bool isMultiple = false}) {
    final suffix = isMultiple ? '_all' : '_main';
    final cacheKey = '${entityType}_$entityId$suffix';
    return _entityLoadingStates[cacheKey] ?? false;
  }

  /// Clear cache for specific entity type (e.g., 'product', 'brand', 'category')
  void clearCacheForEntityType(String entityType) {
    _imageCache.removeWhere((key, value) => key.startsWith(entityType));
    _multipleImagesCache
        .removeWhere((key, value) => key.startsWith(entityType));
    _entityLoadingStates
        .removeWhere((key, value) => key.startsWith(entityType));
  }

  /// Clear cache for specific entity
  void clearCacheForEntity(int entityId, String entityType) {
    final mainKey = '${entityType}_${entityId}_main';
    final allKey = '${entityType}_${entityId}_all';

    _imageCache.remove(mainKey);
    _multipleImagesCache.remove(allKey);
    _entityLoadingStates.remove(mainKey);
    _entityLoadingStates.remove(allKey);
  }

  /// Clear all cache
  void clearAllCache() {
    _imageCache.clear();
    _multipleImagesCache.clear();
    _entityLoadingStates.clear();

    // Also clear persistent cache if available
    if (_cacheController != null) {
      _cacheController!.clearAllCache().then((success) {
        if (kDebugMode) {
          print(success
              ? '✅ MediaController: Persistent cache cleared successfully'
              : '❌ MediaController: Failed to clear persistent cache');
        }
      });
    }
  }

  /// Preload images for better performance (useful for product lists)
  Future<void> preloadImages(List<int> entityIds, String entityType) async {
    if (entityIds.isEmpty) return;

    // Use persistent cache preloading if available
    if (_cacheController != null) {
      try {
        await _cacheController!.preloadImages(entityIds, entityType);
        return;
      } catch (e) {
        if (kDebugMode) {
          print(
              '⚠️ MediaController: Cache preload error, falling back to legacy: $e');
        }
      }
    }

    // Legacy preload logic
    final uncachedIds = entityIds.where((id) {
      final cacheKey = '${entityType}_${id}_main';
      return !_imageCache.containsKey(cacheKey);
    }).toList();

    if (uncachedIds.isNotEmpty) {
      await fetchMultipleMainImages(uncachedIds, entityType);
    }
  }

  /// Fetch main image and all images for product details page
  Future<Map<String, List<String>>> fetchProductDetailsImages(
      int entityId, String entityType) async {
    final mainImageKey = '${entityType}_${entityId}_main';
    final allImagesKey = '${entityType}_${entityId}_all';

    final cachedMainImage = _imageCache[mainImageKey];
    final cachedAllImages = _multipleImagesCache[allImagesKey];

    // If both are cached, return immediately
    if (cachedMainImage != null && cachedAllImages != null) {
      return {
        'mainImageUrl': [cachedMainImage],
        'allImageUrls': cachedAllImages
      };
    }

    // Otherwise, fetch them
    try {
      _entityLoadingStates[mainImageKey] = true;
      _entityLoadingStates[allImagesKey] = true;

      final mainImageUrlFuture = fetchMainImage(entityId, entityType);
      final allImageUrlsFuture = fetchAllImagesForEntity(entityId, entityType);

      final results = await Future.wait(
          [mainImageUrlFuture, allImageUrlsFuture.then((list) => list)]);

      final String? mainImageUrl = results[0] as String?;
      final List<String> allImageUrls = results[1] as List<String>;

      if (mainImageUrl != null) {
        _imageCache[mainImageKey] = mainImageUrl;
      }
      _multipleImagesCache[allImagesKey] = allImageUrls;

      return {
        'mainImageUrl': mainImageUrl != null ? [mainImageUrl] : [],
        'allImageUrls': allImageUrls
      };
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ MediaController: Error fetching product details images for $entityType $entityId: $e');
      }
      return {'mainImageUrl': [], 'allImageUrls': []};
    } finally {
      _entityLoadingStates[mainImageKey] = false;
      _entityLoadingStates[allImagesKey] = false;
    }
  }

  /// Upload image for an entity
  Future<String?> uploadImage(
    File imageFile,
    int entityId,
    String entityType, {
    bool isFeatured = true,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final String? uploadedUrl = await _mediaRepository.uploadImage(
        imageFile,
        entityType,
        entityId,
        isFeatured: isFeatured,
      );

      if (uploadedUrl != null) {
        // Clear cache for this entity to force refresh
        clearCacheForEntity(entityId, entityType);

        // Update cache with new image
        final cacheKey = '${entityType}_${entityId}_main';
        _imageCache[cacheKey] = uploadedUrl;
      }

      uploadProgress.value = 1.0;
      return uploadedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MediaController: Error uploading image: $e');
      }
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Update existing image for an entity
  Future<String?> updateImage(
    File imageFile,
    int entityId,
    String entityType, {
    bool isFeatured = true,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      final String? uploadedUrl = await _mediaRepository.updateImage(
        imageFile,
        entityType,
        entityId,
        isFeatured: isFeatured,
      );

      if (uploadedUrl != null) {
        // Clear cache for this entity to force refresh
        clearCacheForEntity(entityId, entityType);

        // Update cache with new image
        final cacheKey = '${entityType}_${entityId}_main';
        _imageCache[cacheKey] = uploadedUrl;
      }

      uploadProgress.value = 1.0;
      return uploadedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MediaController: Error updating image: $e');
      }
      return null;
    } finally {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Delete all images for an entity
  Future<bool> deleteEntityImages(int entityId, String entityType) async {
    try {
      final bool deleted =
          await _mediaRepository.deleteEntityImages(entityId, entityType);

      if (deleted) {
        // Clear cache for this entity
        clearCacheForEntity(entityId, entityType);
      }

      return deleted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MediaController: Error deleting entity images: $e');
      }
      return false;
    }
  }

  void clearImageCache(int entityId, String entityType) {
    final cacheKey = '${entityType}_${entityId}_main';
    _imageCache.remove(cacheKey);
  }

  /// Force refresh image for an entity (clears cache and fetches new)
  Future<String?> forceRefreshImage(int entityId, String entityType) async {
    // Clear cache first
    clearCacheForEntity(entityId, entityType);

    // Fetch fresh image
    return await fetchMainImage(entityId, entityType);
  }

  /// Check if upload is in progress
  bool get isUploadingImage => isUploading.value;

  /// Get current upload progress (0.0 to 1.0)
  double get uploadProgressValue => uploadProgress.value;

  /// Get cache statistics (if persistent cache is available)
  Map<String, dynamic>? getCacheStatistics() {
    return _cacheController?.getCacheStatistics();
  }

  /// Check if persistent cache is available and initialized
  bool get isPersistentCacheAvailable => _cacheController != null;

  /// Force refresh image for an entity (clears both caches and fetches new)
  Future<String?> forceRefreshImageWithPersistentCache(
      int entityId, String entityType) async {
    // Clear from persistent cache if available
    if (_cacheController != null) {
      try {
        await _cacheController!.clearEntityCache(entityId, entityType);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ MediaController: Error clearing persistent cache: $e');
        }
      }
    }

    // Clear from legacy cache
    clearCacheForEntity(entityId, entityType);

    // Fetch fresh image
    return await fetchMainImage(entityId, entityType);
  }

  /// Cleanup old cached images (persistent cache only)
  Future<int> cleanupOldCachedImages(
      {Duration maxAge = const Duration(days: 30)}) async {
    if (_cacheController != null) {
      try {
        return await _cacheController!.cleanupOldImages(maxAge: maxAge);
      } catch (e) {
        if (kDebugMode) {
          print('❌ MediaController: Error cleaning up old images: $e');
        }
      }
    }
    return 0;
  }

  /// Get cache directory path (Windows specific)
  String? getCacheDirectoryPath() {
    return _cacheController != null
        ? _cacheController!.getCacheStatistics()['cacheDirectory'] as String?
        : null;
  }

  @override
  void onClose() {
    clearAllCache();
    super.onClose();
  }
}
