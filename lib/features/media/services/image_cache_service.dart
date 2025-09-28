import 'dart:io';
import 'package:okiosk/features/media/models/cached_image_model.dart';
import 'package:okiosk/utils/local_storage/sqlite_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._();

  ImageCacheService._();

  /// Get cached image for specific entity and image ID
  Future<CachedImageModel?> getCachedImage(
      int entityId, String entityCategory, int imageId) async {
    try {
      final db = await SQLiteHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        SQLiteHelper.cachedImagesTable,
        where: '${SQLiteHelper.columnEntityId} = ? AND '
            '${SQLiteHelper.columnEntityCategory} = ? AND '
            '${SQLiteHelper.columnImageId} = ?',
        whereArgs: [entityId, entityCategory, imageId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final cachedImage = CachedImageModel.fromMap(maps.first);

        // Verify that the file still exists on disk
        if (await cachedImage.fileExists()) {
          return cachedImage;
        } else {
          // File doesn't exist, remove from cache
          await deleteCachedImage(entityId, entityCategory, imageId);
          return null;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error getting cached image: $e');
      }
      return null;
    }
  }

  /// Get all cached images for an entity
  Future<List<CachedImageModel>> getCachedImagesForEntity(
      int entityId, String entityCategory) async {
    try {
      final db = await SQLiteHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        SQLiteHelper.cachedImagesTable,
        where: '${SQLiteHelper.columnEntityId} = ? AND '
            '${SQLiteHelper.columnEntityCategory} = ?',
        whereArgs: [entityId, entityCategory],
        orderBy: '${SQLiteHelper.columnCreatedAt} ASC',
      );

      final List<CachedImageModel> cachedImages = [];

      for (final map in maps) {
        final cachedImage = CachedImageModel.fromMap(map);

        // Verify that the file still exists on disk
        if (await cachedImage.fileExists()) {
          cachedImages.add(cachedImage);
        } else {
          // File doesn't exist, remove from cache
          await deleteCachedImage(
              entityId, entityCategory, cachedImage.imageId);
        }
      }

      return cachedImages;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ ImageCacheService: Error getting cached images for entity: $e');
      }
      return [];
    }
  }

  /// Save or update cached image
  Future<bool> saveCachedImage(CachedImageModel cachedImage) async {
    try {
      if (!cachedImage.isValid()) {
        if (kDebugMode) {
          print('❌ ImageCacheService: Invalid cached image model');
        }
        return false;
      }

      final db = await SQLiteHelper.database;

      await db.insert(
        SQLiteHelper.cachedImagesTable,
        cachedImage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        print(
            '✅ ImageCacheService: Cached image saved: ${cachedImage.cacheKey}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error saving cached image: $e');
      }
      return false;
    }
  }

  /// Update cached image metadata
  Future<bool> updateCachedImage(
    int entityId,
    String entityCategory,
    int imageId, {
    String? imageUrl,
    String? filePath,
    DateTime? updatedAt,
    int? fileSize,
  }) async {
    try {
      final db = await SQLiteHelper.database;

      final Map<String, dynamic> updateData = {};
      if (imageUrl != null) updateData[SQLiteHelper.columnImageUrl] = imageUrl;
      if (filePath != null) updateData[SQLiteHelper.columnFilePath] = filePath;
      if (updatedAt != null) {
        updateData[SQLiteHelper.columnUpdatedAt] = updatedAt.toIso8601String();
      }
      if (fileSize != null) updateData[SQLiteHelper.columnFileSize] = fileSize;

      if (updateData.isEmpty) return true;

      final int rowsAffected = await db.update(
        SQLiteHelper.cachedImagesTable,
        updateData,
        where: '${SQLiteHelper.columnEntityId} = ? AND '
            '${SQLiteHelper.columnEntityCategory} = ? AND '
            '${SQLiteHelper.columnImageId} = ?',
        whereArgs: [entityId, entityCategory, imageId],
      );

      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error updating cached image: $e');
      }
      return false;
    }
  }

  /// Delete cached image
  Future<bool> deleteCachedImage(
      int entityId, String entityCategory, int imageId) async {
    try {
      // First get the cached image to delete the file
      final cachedImage =
          await getCachedImage(entityId, entityCategory, imageId);

      final db = await SQLiteHelper.database;

      final int rowsAffected = await db.delete(
        SQLiteHelper.cachedImagesTable,
        where: '${SQLiteHelper.columnEntityId} = ? AND '
            '${SQLiteHelper.columnEntityCategory} = ? AND '
            '${SQLiteHelper.columnImageId} = ?',
        whereArgs: [entityId, entityCategory, imageId],
      );

      // Delete the actual file if it exists
      if (cachedImage != null) {
        await cachedImage.deleteFile();
      }

      if (kDebugMode && rowsAffected > 0) {
        print(
            '✅ ImageCacheService: Cached image deleted: ${entityCategory}_${entityId}_$imageId');
      }

      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error deleting cached image: $e');
      }
      return false;
    }
  }

  /// Delete all cached images for an entity
  Future<bool> deleteCachedImagesForEntity(
      int entityId, String entityCategory) async {
    try {
      // First get all cached images to delete the files
      final cachedImages =
          await getCachedImagesForEntity(entityId, entityCategory);

      final db = await SQLiteHelper.database;

      final int rowsAffected = await db.delete(
        SQLiteHelper.cachedImagesTable,
        where: '${SQLiteHelper.columnEntityId} = ? AND '
            '${SQLiteHelper.columnEntityCategory} = ?',
        whereArgs: [entityId, entityCategory],
      );

      // Delete the actual files
      for (final cachedImage in cachedImages) {
        await cachedImage.deleteFile();
      }

      if (kDebugMode && rowsAffected > 0) {
        print(
            '✅ ImageCacheService: All cached images deleted for entity: ${entityCategory}_$entityId');
      }

      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ ImageCacheService: Error deleting cached images for entity: $e');
      }
      return false;
    }
  }

  /// Check if image is cached and valid
  Future<bool> isCacheValid(int entityId, String entityCategory, int imageId,
      DateTime serverUpdatedAt) async {
    try {
      final cachedImage =
          await getCachedImage(entityId, entityCategory, imageId);

      if (cachedImage == null) return false;

      return cachedImage.isValidCache(serverUpdatedAt);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error checking cache validity: $e');
      }
      return false;
    }
  }

  /// Get Windows cache directory path
  String getCacheDirectoryPath() {
    return SQLiteHelper.windowsCachePath;
  }

  /// Generate file path for cached image
  String generateCacheFilePath(
      int entityId, String entityCategory, int imageId, String originalUrl) {
    try {
      final String cacheDir = getCacheDirectoryPath();

      // Extract extension from original URL or default to .jpg
      String extension = path.extension(originalUrl).isNotEmpty
          ? path.extension(originalUrl)
          : '.jpg';

      // Remove query parameters from extension if present
      if (extension.contains('?')) {
        extension = extension.split('?').first;
      }

      final String fileName =
          '${entityCategory}_${entityId}_${imageId}_${DateTime.now().millisecondsSinceEpoch}$extension';

      return path.join(cacheDir, fileName);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error generating cache file path: $e');
      }
      rethrow;
    }
  }

  /// Ensure cache directory exists
  Future<void> ensureCacheDirectoryExists() async {
    try {
      final String cacheDir = getCacheDirectoryPath();
      final Directory cacheDirObj = Directory(cacheDir);

      if (!await cacheDirObj.exists()) {
        await cacheDirObj.create(recursive: true);
        if (kDebugMode) {
          print('📁 ImageCacheService: Created cache directory: $cacheDir');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error ensuring cache directory exists: $e');
      }
      rethrow;
    }
  }

  /// Clear all cache (for "Clear Cache" functionality)
  Future<bool> clearAllCache() async {
    try {
      // Get cache directory
      final String cacheDir = getCacheDirectoryPath();
      final Directory cacheDirObj = Directory(cacheDir);

      // Delete all image files in cache directory
      if (await cacheDirObj.exists()) {
        await for (final FileSystemEntity entity in cacheDirObj.list()) {
          if (entity is File &&
              entity.path
                  .toLowerCase()
                  .contains(RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp)$'))) {
            try {
              await entity.delete();
            } catch (e) {
              if (kDebugMode) {
                print(
                    '❌ ImageCacheService: Error deleting file ${entity.path}: $e');
              }
            }
          }
        }
      }

      // Clear SQLite cache
      await SQLiteHelper.clearAllCache();

      if (kDebugMode) {
        print('✅ ImageCacheService: All cache cleared successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error clearing all cache: $e');
      }
      return false;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await SQLiteHelper.database;

      // Count total cached images
      final countResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM ${SQLiteHelper.cachedImagesTable}');
      final int totalImages = countResult.first['count'] as int? ?? 0;

      // Calculate total file size from database
      final sizeResult = await db.rawQuery(
          'SELECT SUM(${SQLiteHelper.columnFileSize}) as total_size FROM ${SQLiteHelper.cachedImagesTable}');
      final int totalSize = sizeResult.first['total_size'] as int? ?? 0;

      // Get actual cache directory size
      final String cacheDir = getCacheDirectoryPath();
      final Directory cacheDirObj = Directory(cacheDir);
      int actualDirSize = 0;

      if (await cacheDirObj.exists()) {
        await for (final FileSystemEntity entity
            in cacheDirObj.list(recursive: false)) {
          if (entity is File) {
            try {
              final FileStat stat = await entity.stat();
              actualDirSize += stat.size;
            } catch (e) {
              // Ignore errors reading individual files
            }
          }
        }
      }

      return {
        'totalImages': totalImages,
        'totalSizeBytes': totalSize,
        'actualDirectorySizeBytes': actualDirSize,
        'cacheDirectory': cacheDir,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error getting cache stats: $e');
      }
      return {
        'totalImages': 0,
        'totalSizeBytes': 0,
        'actualDirectorySizeBytes': 0,
        'cacheDirectory': getCacheDirectoryPath(),
      };
    }
  }

  /// Clean up orphaned cache entries (files that don't exist but are in database)
  Future<int> cleanupOrphanedEntries() async {
    try {
      final db = await SQLiteHelper.database;

      final List<Map<String, dynamic>> allCachedImages = await db.query(
        SQLiteHelper.cachedImagesTable,
      );

      int cleanedCount = 0;

      for (final map in allCachedImages) {
        final cachedImage = CachedImageModel.fromMap(map);

        if (!await cachedImage.fileExists()) {
          await deleteCachedImage(
            cachedImage.entityId,
            cachedImage.entityCategory,
            cachedImage.imageId,
          );
          cleanedCount++;
        }
      }

      if (kDebugMode && cleanedCount > 0) {
        print(
            '🧹 ImageCacheService: Cleaned up $cleanedCount orphaned cache entries');
      }

      return cleanedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error cleaning up orphaned entries: $e');
      }
      return 0;
    }
  }

  /// Get cached images older than specified duration
  Future<List<CachedImageModel>> getOldCachedImages(Duration age) async {
    try {
      final db = await SQLiteHelper.database;
      final cutoffDate = DateTime.now().subtract(age);

      final List<Map<String, dynamic>> maps = await db.query(
        SQLiteHelper.cachedImagesTable,
        where: '${SQLiteHelper.columnCreatedAt} < ?',
        whereArgs: [cutoffDate.toIso8601String()],
        orderBy: '${SQLiteHelper.columnCreatedAt} ASC',
      );

      return maps.map((map) => CachedImageModel.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error getting old cached images: $e');
      }
      return [];
    }
  }

  /// Clean up old cached images
  Future<int> cleanupOldImages(Duration maxAge) async {
    try {
      final oldImages = await getOldCachedImages(maxAge);
      int deletedCount = 0;

      for (final cachedImage in oldImages) {
        final success = await deleteCachedImage(
          cachedImage.entityId,
          cachedImage.entityCategory,
          cachedImage.imageId,
        );
        if (success) deletedCount++;
      }

      if (kDebugMode && deletedCount > 0) {
        print(
            '🧹 ImageCacheService: Cleaned up $deletedCount old cached images');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageCacheService: Error cleaning up old images: $e');
      }
      return 0;
    }
  }
}
