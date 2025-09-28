import 'dart:io';
import 'dart:typed_data';
import 'package:okiosk/features/media/models/cached_image_model.dart';
import 'package:okiosk/features/media/services/image_cache_service.dart';
import 'package:okiosk/features/media/services/image_download_service.dart';
import 'package:okiosk/main.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class ImageCacheController extends GetxController {
  static ImageCacheController get instance => Get.find();

  final ImageCacheService _cacheService = ImageCacheService.instance;
  final ImageDownloadService _downloadService = ImageDownloadService.instance;

  // Loading states
  final RxMap<String, bool> _loadingStates = <String, bool>{}.obs;
  final RxMap<String, double> _downloadProgress = <String, double>{}.obs;

  // Cache statistics
  final RxMap<String, dynamic> cacheStats = <String, dynamic>{}.obs;

  // Request throttling to prevent overwhelming Supabase connections
  final Map<String, Future<ImageCacheResult>> _pendingRequests = {};
  final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _requestThrottle = Duration(milliseconds: 100);

  @override
  void onInit() {
    super.onInit();
    updateCacheStats();
  }

  /// Get cached image or fetch from server if outdated/missing
  Future<ImageCacheResult> getCachedImageOrFetch({
    required int entityId,
    required String entityCategory,
    required int imageId,
  }) async {
    final String cacheKey = '${entityCategory}_${entityId}_$imageId';

    // Check if there's already a pending request for this image
    if (_pendingRequests.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('⏳ ImageCacheController: Reusing pending request for $cacheKey');
      }
      return await _pendingRequests[cacheKey]!;
    }

    // Throttle requests to prevent overwhelming Supabase
    final lastRequest = _lastRequestTime[cacheKey];
    if (lastRequest != null) {
      final timeSinceLastRequest = DateTime.now().difference(lastRequest);
      if (timeSinceLastRequest < _requestThrottle) {
        await Future.delayed(_requestThrottle - timeSinceLastRequest);
      }
    }
    _lastRequestTime[cacheKey] = DateTime.now();

    // Create and store the request future
    final requestFuture =
        _performCacheRequest(entityId, entityCategory, imageId, cacheKey);
    _pendingRequests[cacheKey] = requestFuture;

    try {
      final result = await requestFuture;
      return result;
    } finally {
      // Clean up the pending request
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Perform the actual cache request (separated for better error handling)
  Future<ImageCacheResult> _performCacheRequest(
    int entityId,
    String entityCategory,
    int imageId,
    String cacheKey,
  ) async {
    try {
      _loadingStates[cacheKey] = true;

      if (kDebugMode) {
        print(
            '🔄 ImageCacheController: Processing image request for $cacheKey');
      }

      // Step 1: Check local cache first
      if (kDebugMode) {
        print('📁 ImageCacheController: Checking cache for $cacheKey');
      }

      final CachedImageModel? cachedImage =
          await _cacheService.getCachedImage(entityId, entityCategory, imageId);

      // If we have a cached image, use it immediately
      if (cachedImage != null) {
        if (kDebugMode) {
          print(
              '✅ ImageCacheController: Cache HIT for $cacheKey - loading from: ${cachedImage.filePath}');
        }

        // Return cached image immediately for better UX
        return ImageCacheResult(
          success: true,
          localFilePath: cachedImage.filePath,
          imageUrl: cachedImage.imageUrl,
          isFromCache: true,
          cacheKey: cacheKey,
          message: 'Image loaded from cache',
        );
      }

      // Step 2: No cache found, need to fetch from server
      if (kDebugMode) {
        print('❌ ImageCacheController: Cache MISS for $cacheKey');
        print('🌐 ImageCacheController: Fetching from server...');
      }

      // Get server metadata
      final ServerImageMetadata? serverMetadata =
          await _getServerImageMetadata(entityId, entityCategory, imageId);

      if (serverMetadata == null) {
        if (kDebugMode) {
          print(
              '❌ ImageCacheController: No server metadata found for $cacheKey');
        }
        return ImageCacheResult(
          success: false,
          message: 'Image not found on server',
          cacheKey: cacheKey,
        );
      }

      if (kDebugMode) {
        print('📊 ImageCacheController: Server metadata found for $cacheKey');
        print('   URL: ${serverMetadata.imageUrl}');
      }

      // Step 3: Fetch and cache the image
      return await _fetchAndCacheImage(
        entityId: entityId,
        entityCategory: entityCategory,
        imageId: imageId,
        serverMetadata: serverMetadata,
        cacheKey: cacheKey,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error processing image request: $e');
      }
      return ImageCacheResult(
        success: false,
        message: 'Error processing image: ${e.toString()}',
        cacheKey: cacheKey,
      );
    } finally {
      _loadingStates[cacheKey] = false;
      _downloadProgress.remove(cacheKey);
    }
  }

  /// Fetch image from server and cache it locally
  Future<ImageCacheResult> _fetchAndCacheImage({
    required int entityId,
    required String entityCategory,
    required int imageId,
    required ServerImageMetadata serverMetadata,
    required String cacheKey,
  }) async {
    try {
      _downloadProgress[cacheKey] = 0.0;

      // Check if the image URL is a local file path
      if (_isLocalFilePath(serverMetadata.imageUrl)) {
        if (kDebugMode) {
          print(
              '⚠️ ImageCacheController: Local file path detected: ${serverMetadata.imageUrl}');
        }

        // For local file paths, we cannot cache them as they're not accessible via HTTP
        // Return a result indicating this is a local file that should be handled differently
        return ImageCacheResult(
          success: false,
          message: 'Local file path detected - cannot cache',
          cacheKey: cacheKey,
        );
      }

      // Download image as bytes for immediate display
      if (kDebugMode) {
        print('⬇️ ImageCacheController: Downloading image for $cacheKey');
        print('   From URL: ${serverMetadata.imageUrl}');
      }

      final downloadResult =
          await _downloadService.downloadImageAsBytes(serverMetadata.imageUrl);

      if (!downloadResult.success || downloadResult.imageBytes == null) {
        if (kDebugMode) {
          print('❌ ImageCacheController: Download failed for $cacheKey');
          print('   Error: ${downloadResult.message}');
        }
        return ImageCacheResult(
          success: false,
          message: downloadResult.message ?? 'Failed to download image',
          cacheKey: cacheKey,
        );
      }

      if (kDebugMode) {
        print('✅ ImageCacheController: Download successful for $cacheKey');
        print('   Size: ${downloadResult.fileSize} bytes');
      }

      _downloadProgress[cacheKey] = 0.5;

      // Generate cache file path
      final String cacheFilePath = _cacheService.generateCacheFilePath(
          entityId, entityCategory, imageId, serverMetadata.imageUrl);

      // Save image to local storage
      final File cacheFile = File(cacheFilePath);
      await cacheFile.writeAsBytes(downloadResult.imageBytes!);

      _downloadProgress[cacheKey] = 0.8;

      // Save metadata to SQLite
      final CachedImageModel newCachedImage = CachedImageModel(
        entityId: entityId,
        entityCategory: entityCategory,
        imageId: imageId,
        imageUrl: serverMetadata.imageUrl,
        filePath: cacheFilePath,
        updatedAt: serverMetadata.updatedAt,
        createdAt: DateTime.now(),
        fileSize: downloadResult.fileSize ?? 0,
      );

      if (kDebugMode) {
        print('💾 ImageCacheController: Saving to cache: $cacheFilePath');
      }

      final bool saved = await _cacheService.saveCachedImage(newCachedImage);

      if (!saved) {
        if (kDebugMode) {
          print(
              '⚠️ ImageCacheController: Failed to save cache metadata for $cacheKey');
        }
      } else {
        if (kDebugMode) {
          print('✅ ImageCacheController: Cache metadata saved for $cacheKey');
        }
      }

      _downloadProgress[cacheKey] = 1.0;
      updateCacheStats();

      if (kDebugMode) {
        print(
            '🎉 ImageCacheController: Image fetched and cached successfully for $cacheKey');
        print('   Local path: $cacheFilePath');
      }

      return ImageCacheResult(
        success: true,
        localFilePath: cacheFilePath,
        imageUrl: serverMetadata.imageUrl,
        imageBytes: downloadResult.imageBytes,
        isFromCache: false,
        cacheKey: cacheKey,
        message: 'Image fetched and cached successfully',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error fetching and caching image: $e');
      }
      return ImageCacheResult(
        success: false,
        message: 'Error fetching image: ${e.toString()}',
        cacheKey: cacheKey,
      );
    }
  }

  /// Get server image metadata (filename, folderType, and updated_at)
  Future<ServerImageMetadata?> _getServerImageMetadata(
      int entityId, String entityCategory, int imageId) async {
    try {
      // Query image_entity table for the relationship and updated_at
      final response = await supabase
          .from('image_entity')
          .select('image_id, updated_at')
          .eq('entity_id', entityId)
          .eq('entity_category', entityCategory)
          .eq('image_id', imageId)
          .maybeSingle();

      if (response == null) return null;

      // Query images table for filename and folderType
      final imageResponse = await supabase
          .from('images')
          .select('filename, folderType')
          .eq('image_id', imageId)
          .maybeSingle();

      if (imageResponse == null) return null;

      final String? filename = imageResponse['filename'] as String?;
      final String? folderType = imageResponse['folderType'] as String?;

      if (kDebugMode) {
        print('📋 ImageCacheController: Image metadata retrieved:');
        print('   Filename: $filename');
        print('   FolderType: $folderType');
      }

      if (filename == null || filename.isEmpty) {
        if (kDebugMode) {
          print('❌ ImageCacheController: No filename found in database');
        }
        return null;
      }

      // Check if filename is actually a local file path (data issue)
      if (_isLocalFilePath(filename)) {
        if (kDebugMode) {
          print(
              '⚠️ ImageCacheController: Local file path detected in filename: $filename');
          print(
              '   This should be a storage filename. Skipping cache for this image.');
        }
        return null; // Skip caching for local paths
      }

      // Use folderType as bucket name, or fallback to entityCategory
      final String bucketName = folderType ?? entityCategory;

      if (kDebugMode) {
        print('🪣 ImageCacheController: Using bucket: $bucketName');
      }

      // Generate signed URL from your private bucket
      String imageUrl;
      try {
        imageUrl = await supabase.storage
            .from(bucketName)
            .createSignedUrl(filename, 86400); // 24 hours
      } catch (e) {
        if (kDebugMode) {
          print('❌ ImageCacheController: Error generating signed URL: $e');
          print('   Bucket: $bucketName, Filename: $filename');
        }
        return null;
      }

      return ServerImageMetadata(
        imageUrl: imageUrl,
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ ImageCacheController: Error getting server image metadata: $e');
      }
      return null;
    }
  }

  /// Get main image for entity (similar to existing MediaController method but with caching)
  Future<ImageCacheResult> getMainImageWithCache(
      int entityId, String entityCategory) async {
    try {
      // First get the main image ID from server
      final response = await supabase
          .from('image_entity')
          .select('image_id')
          .eq('entity_id', entityId)
          .eq('entity_category', entityCategory)
          .eq('isFeatured', true)
          .maybeSingle();

      if (response == null) {
        return ImageCacheResult(
          success: false,
          message: 'No main image found for entity',
          cacheKey: '${entityCategory}_${entityId}_main',
        );
      }

      final int imageId = response['image_id'] as int;

      return await getCachedImageOrFetch(
        entityId: entityId,
        entityCategory: entityCategory,
        imageId: imageId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error getting main image: $e');
      }
      return ImageCacheResult(
        success: false,
        message: 'Error getting main image: ${e.toString()}',
        cacheKey: '${entityCategory}_${entityId}_main',
      );
    }
  }

  /// Check if image is currently loading
  bool isImageLoading(String cacheKey) {
    return _loadingStates[cacheKey] ?? false;
  }

  /// Get download progress for image
  double getDownloadProgress(String cacheKey) {
    return _downloadProgress[cacheKey] ?? 0.0;
  }

  /// Clear cache for specific entity
  Future<bool> clearEntityCache(int entityId, String entityCategory) async {
    try {
      final bool success = await _cacheService.deleteCachedImagesForEntity(
          entityId, entityCategory);

      if (success) {
        updateCacheStats();
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error clearing entity cache: $e');
      }
      return false;
    }
  }

  /// Clear all cache
  Future<bool> clearAllCache() async {
    try {
      final bool success = await _cacheService.clearAllCache();

      if (success) {
        _loadingStates.clear();
        _downloadProgress.clear();
        updateCacheStats();
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error clearing all cache: $e');
      }
      return false;
    }
  }

  /// Update cache statistics
  Future<void> updateCacheStats() async {
    try {
      final stats = await _cacheService.getCacheStats();
      cacheStats.value = stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error updating cache stats: $e');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return Map<String, dynamic>.from(cacheStats);
  }

  /// Check if a URL/filename is actually a local file path
  bool _isLocalFilePath(String url) {
    // Check for Windows-style paths (C:\ or c:/)
    if (RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(url)) {
      return true;
    }

    // Check for Unix-style absolute paths
    if (url.startsWith('/')) {
      return true;
    }

    // Check for relative paths (./path or ../path)
    if (url.startsWith('./') || url.startsWith('../')) {
      return true;
    }

    // Check for Windows-style UNC paths (\\server\share)
    if (url.startsWith('\\\\')) {
      return true;
    }

    // If it's a full URL (http/https), it's not a local path
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return false;
    }

    // Check if it looks like a Windows path with backslashes
    if (url.contains('\\') && !url.startsWith('http')) {
      return true;
    }

    // For other cases (like UUIDs), assume it's a valid filename/URL
    return false;
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<int> entityIds, String entityCategory) async {
    try {
      if (entityIds.isEmpty) return;

      for (final entityId in entityIds) {
        // Don't await - let them load in parallel
        getMainImageWithCache(entityId, entityCategory).then((result) {
          if (kDebugMode && result.success) {
            print(
                '🚀 ImageCacheController: Preloaded image for ${entityCategory}_$entityId');
          }
        }).catchError((e) {
          if (kDebugMode) {
            print(
                '❌ ImageCacheController: Error preloading image for ${entityCategory}_$entityId: $e');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error in preload images: $e');
      }
    }
  }

  /// Get all cached images for an entity
  Future<List<ImageCacheResult>> getAllCachedImagesForEntity(
      int entityId, String entityCategory) async {
    try {
      final cachedImages = await _cacheService.getCachedImagesForEntity(
          entityId, entityCategory);

      return cachedImages
          .map((cachedImage) => ImageCacheResult(
                success: true,
                localFilePath: cachedImage.filePath,
                imageUrl: cachedImage.imageUrl,
                isFromCache: true,
                cacheKey: cachedImage.cacheKey,
                message: 'Image loaded from cache',
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ ImageCacheController: Error getting all cached images for entity: $e');
      }
      return [];
    }
  }

  /// Cleanup old cached images
  Future<int> cleanupOldImages(
      {Duration maxAge = const Duration(days: 30)}) async {
    try {
      final deletedCount = await _cacheService.cleanupOldImages(maxAge);
      if (deletedCount > 0) {
        updateCacheStats();
      }
      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error cleaning up old images: $e');
      }
      return 0;
    }
  }

  /// Cleanup orphaned cache entries
  Future<int> cleanupOrphanedEntries() async {
    try {
      final cleanedCount = await _cacheService.cleanupOrphanedEntries();
      if (cleanedCount > 0) {
        updateCacheStats();
      }
      return cleanedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheController: Error cleaning up orphaned entries: $e');
      }
      return 0;
    }
  }
}

/// Result class for image cache operations
class ImageCacheResult {
  final bool success;
  final String? localFilePath;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final bool isFromCache;
  final String cacheKey;
  final String? message;

  const ImageCacheResult({
    required this.success,
    this.localFilePath,
    this.imageUrl,
    this.imageBytes,
    this.isFromCache = false,
    required this.cacheKey,
    this.message,
  });

  @override
  String toString() {
    return 'ImageCacheResult(success: $success, localFilePath: $localFilePath, '
        'imageUrl: $imageUrl, isFromCache: $isFromCache, cacheKey: $cacheKey, '
        'message: $message)';
  }
}

/// Server image metadata class
class ServerImageMetadata {
  final String imageUrl;
  final DateTime updatedAt;

  const ServerImageMetadata({
    required this.imageUrl,
    required this.updatedAt,
  });

  @override
  String toString() {
    return 'ServerImageMetadata(imageUrl: $imageUrl, updatedAt: $updatedAt)';
  }
}
