import 'package:okiosk/features/media/controllers/image_cache_controller.dart';
import 'package:okiosk/utils/local_storage/sqlite_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class CacheInitializationService {
  static CacheInitializationService? _instance;
  static CacheInitializationService get instance =>
      _instance ??= CacheInitializationService._();

  CacheInitializationService._();

  bool _isInitialized = false;

  /// Initialize cache system on app startup
  Future<void> initializeCache() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🚀 CacheInitializationService: Initializing cache system...');
      }

      // Initialize SQLite database
      await SQLiteHelper.database;

      // Initialize and register the ImageCacheController
      if (!Get.isRegistered<ImageCacheController>()) {
        Get.put(ImageCacheController(), permanent: true);
      }

      _isInitialized = true;

      if (kDebugMode) {
        print(
            '✅ CacheInitializationService: Cache system initialized successfully');

        // Print cache statistics
        final controller = Get.find<ImageCacheController>();
        final stats = controller.getCacheStatistics();
        print(
            '📊 Cache Stats: ${stats['totalImages']} images, ${_formatFileSize(stats['totalSizeBytes'] ?? 0)}');
      }

      // Perform background cleanup
      _performBackgroundMaintenance();
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error initializing cache: $e');
      }
      rethrow;
    }
  }

  /// Clean up cache system (called on app termination)
  Future<void> cleanupCache() async {
    try {
      if (kDebugMode) {
        print('🧹 CacheInitializationService: Cleaning up cache system...');
      }

      // Close SQLite connection
      await SQLiteHelper.close();

      _isInitialized = false;

      if (kDebugMode) {
        print('✅ CacheInitializationService: Cache cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error cleaning up cache: $e');
      }
    }
  }

  /// Check if cache system is initialized
  bool get isInitialized => _isInitialized;

  /// Perform background maintenance tasks
  Future<void> _performBackgroundMaintenance() async {
    try {
      if (!Get.isRegistered<ImageCacheController>()) return;

      final controller = Get.find<ImageCacheController>();

      // Run maintenance in background to not block app startup
      Future(() async {
        if (kDebugMode) {
          print(
              '🔧 CacheInitializationService: Starting background maintenance...');
        }

        // Clean up orphaned cache entries
        final orphanedCount = await controller.cleanupOrphanedEntries();
        if (kDebugMode && orphanedCount > 0) {
          print(
              '🧹 CacheInitializationService: Cleaned up $orphanedCount orphaned entries');
        }

        // Clean up old images (older than 30 days)
        final oldImagesCount = await controller.cleanupOldImages();
        if (kDebugMode && oldImagesCount > 0) {
          print(
              '🧹 CacheInitializationService: Cleaned up $oldImagesCount old images');
        }

        // Update stats after cleanup
        await controller.updateCacheStats();

        if (kDebugMode) {
          print(
              '✅ CacheInitializationService: Background maintenance completed');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ CacheInitializationService: Error in background maintenance: $e');
      }
    }
  }

  /// Reinitialize cache system (useful for recovery scenarios)
  Future<void> reinitializeCache() async {
    try {
      if (kDebugMode) {
        print('🔄 CacheInitializationService: Reinitializing cache system...');
      }

      await cleanupCache();
      _isInitialized = false;
      await initializeCache();

      if (kDebugMode) {
        print(
            '✅ CacheInitializationService: Cache system reinitialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error reinitializing cache: $e');
      }
      rethrow;
    }
  }

  /// Get comprehensive cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      if (!_isInitialized || !Get.isRegistered<ImageCacheController>()) {
        return {
          'initialized': false,
          'error': 'Cache system not initialized',
        };
      }

      final controller = Get.find<ImageCacheController>();
      final stats = controller.getCacheStatistics();

      return {
        'initialized': true,
        'totalImages': stats['totalImages'] ?? 0,
        'totalSizeBytes': stats['totalSizeBytes'] ?? 0,
        'totalSizeFormatted': _formatFileSize(stats['totalSizeBytes'] ?? 0),
        'actualDirectorySizeBytes': stats['actualDirectorySizeBytes'] ?? 0,
        'actualDirectorySizeFormatted':
            _formatFileSize(stats['actualDirectorySizeBytes'] ?? 0),
        'cacheDirectory': stats['cacheDirectory'] ?? '',
        'databaseInitialized': SQLiteHelper.isInitialized,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error getting cache info: $e');
      }
      return {
        'initialized': false,
        'error': e.toString(),
      };
    }
  }

  /// Test cache system functionality
  Future<bool> testCacheSystem() async {
    try {
      if (kDebugMode) {
        print('🧪 CacheInitializationService: Testing cache system...');
      }

      // Check if cache system is initialized
      if (!_isInitialized) {
        if (kDebugMode) {
          print('❌ CacheInitializationService: Cache system not initialized');
        }
        return false;
      }

      // Check if SQLite database is accessible
      final db = await SQLiteHelper.database;
      if (db.isOpen) {
        if (kDebugMode) {
          print('✅ CacheInitializationService: SQLite database is accessible');
        }
      } else {
        if (kDebugMode) {
          print('❌ CacheInitializationService: SQLite database is not open');
        }
        return false;
      }

      // Check if ImageCacheController is registered
      if (Get.isRegistered<ImageCacheController>()) {
        final controller = Get.find<ImageCacheController>();
        final stats = controller.getCacheStatistics();
        if (kDebugMode) {
          print(
              '✅ CacheInitializationService: ImageCacheController is working');
          print('   Cache contains ${stats['totalImages']} images');
        }
      } else {
        if (kDebugMode) {
          print(
              '❌ CacheInitializationService: ImageCacheController not registered');
        }
        return false;
      }

      // Check cache directory accessibility
      final stats = await getCacheInfo();
      final String cacheDir = stats['cacheDirectory'] ?? '';
      if (cacheDir.isNotEmpty) {
        if (kDebugMode) {
          print(
              '✅ CacheInitializationService: Cache directory accessible: $cacheDir');
        }
      } else {
        if (kDebugMode) {
          print('❌ CacheInitializationService: Cache directory not accessible');
        }
        return false;
      }

      if (kDebugMode) {
        print('✅ CacheInitializationService: All cache system tests passed');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Cache system test failed: $e');
      }
      return false;
    }
  }

  /// Perform cache maintenance manually
  Future<Map<String, int>> performMaintenance() async {
    try {
      if (!_isInitialized || !Get.isRegistered<ImageCacheController>()) {
        return {
          'orphanedCleaned': 0,
          'oldImagesCleaned': 0,
        };
      }

      final controller = Get.find<ImageCacheController>();

      if (kDebugMode) {
        print(
            '🔧 CacheInitializationService: Performing manual maintenance...');
      }

      // Clean up orphaned entries
      final orphanedCount = await controller.cleanupOrphanedEntries();

      // Clean up old images
      final oldImagesCount = await controller.cleanupOldImages();

      // Update stats
      await controller.updateCacheStats();

      if (kDebugMode) {
        print('✅ CacheInitializationService: Manual maintenance completed');
        print('   Orphaned entries cleaned: $orphanedCount');
        print('   Old images cleaned: $oldImagesCount');
      }

      return {
        'orphanedCleaned': orphanedCount,
        'oldImagesCleaned': oldImagesCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error in manual maintenance: $e');
      }
      return {
        'orphanedCleaned': 0,
        'oldImagesCleaned': 0,
      };
    }
  }

  /// Clear all cache data
  Future<bool> clearAllCache() async {
    try {
      if (!_isInitialized || !Get.isRegistered<ImageCacheController>()) {
        return false;
      }

      final controller = Get.find<ImageCacheController>();

      if (kDebugMode) {
        print('🗑️ CacheInitializationService: Clearing all cache data...');
      }

      final success = await controller.clearAllCache();

      if (kDebugMode) {
        if (success) {
          print(
              '✅ CacheInitializationService: All cache data cleared successfully');
        } else {
          print('❌ CacheInitializationService: Failed to clear all cache data');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CacheInitializationService: Error clearing all cache: $e');
      }
      return false;
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size.truncateToDouble() == size ? 0 : 1)} ${suffixes[i]}';
  }

  /// Get cache initialization status for debugging
  Map<String, dynamic> getInitializationStatus() {
    return {
      'isInitialized': _isInitialized,
      'sqLiteInitialized': SQLiteHelper.isInitialized,
      'imageCacheControllerRegistered':
          Get.isRegistered<ImageCacheController>(),
      'cacheDirectory': SQLiteHelper.windowsCachePath,
    };
  }
}
