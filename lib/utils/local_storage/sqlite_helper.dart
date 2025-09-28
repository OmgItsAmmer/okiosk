import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteHelper {
  static Database? _database;

  // Windows-specific cache directory path
  static const String _windowsCachePath =
      r'C:\Users\ammer\OneDrive\Desktop\Okisosk_images';

  // Database file path
  static String get _databasePath =>
      path.join(_windowsCachePath, 'okiosk_cache.db');

  // Table and column names for cached images
  static const String cachedImagesTable = 'cached_images';
  static const String columnId = 'id';
  static const String columnEntityId = 'entity_id';
  static const String columnEntityCategory = 'entity_category';
  static const String columnImageId = 'image_id';
  static const String columnImageUrl = 'image_url';
  static const String columnFilePath = 'file_path';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnCreatedAt = 'created_at';
  static const String columnFileSize = 'file_size';

  /// Get database instance (singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database for Windows
  static Future<Database> _initDatabase() async {
    try {
      // Initialize SQLite FFI for Windows
      sqfliteFfiInit();

      // Set database factory for Windows
      databaseFactory = databaseFactoryFfi;

      // Ensure cache directory exists
      await _ensureCacheDirectoryExists();

      if (kDebugMode) {
        print('🗄️ SQLiteHelper: Initializing database at: $_databasePath');
      }

      // Open/create database
      final database = await openDatabase(
        _databasePath,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      if (kDebugMode) {
        print('✅ SQLiteHelper: Database initialized successfully');
      }

      return database;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error initializing database: $e');
      }
      rethrow;
    }
  }

  /// Ensure cache directory exists
  static Future<void> _ensureCacheDirectoryExists() async {
    try {
      final Directory cacheDir = Directory(_windowsCachePath);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
        if (kDebugMode) {
          print('📁 SQLiteHelper: Created cache directory: $_windowsCachePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error creating cache directory: $e');
      }
      rethrow;
    }
  }

  /// Create tables when database is first created
  static Future<void> _onCreate(Database db, int version) async {
    try {
      if (kDebugMode) {
        print('🏗️ SQLiteHelper: Creating cached images table...');
      }

      await db.execute('''
        CREATE TABLE $cachedImagesTable (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnEntityId INTEGER NOT NULL,
          $columnEntityCategory TEXT NOT NULL,
          $columnImageId INTEGER NOT NULL,
          $columnImageUrl TEXT NOT NULL,
          $columnFilePath TEXT NOT NULL,
          $columnUpdatedAt TEXT NOT NULL,
          $columnCreatedAt TEXT NOT NULL,
          $columnFileSize INTEGER NOT NULL,
          UNIQUE($columnEntityId, $columnEntityCategory, $columnImageId)
        )
      ''');

      // Create index for better query performance
      await db.execute('''
        CREATE INDEX idx_entity_lookup 
        ON $cachedImagesTable($columnEntityId, $columnEntityCategory)
      ''');

      await db.execute('''
        CREATE INDEX idx_image_lookup 
        ON $cachedImagesTable($columnImageId)
      ''');

      if (kDebugMode) {
        print('✅ SQLiteHelper: Cached images table created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error creating tables: $e');
      }
      rethrow;
    }
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 SQLiteHelper: Upgrading database from $oldVersion to $newVersion');
      }

      // Handle future database migrations here
      // For now, we'll just recreate the table if needed
      if (oldVersion < newVersion) {
        await db.execute('DROP TABLE IF EXISTS $cachedImagesTable');
        await _onCreate(db, newVersion);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error upgrading database: $e');
      }
      rethrow;
    }
  }

  /// Clear all cached data
  static Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete(cachedImagesTable);

      if (kDebugMode) {
        print('🧹 SQLiteHelper: All cache data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error clearing cache: $e');
      }
      rethrow;
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await database;

      // Count total cached images
      final countResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM $cachedImagesTable');
      final int totalImages = countResult.first['count'] as int? ?? 0;

      // Calculate total file size
      final sizeResult = await db.rawQuery(
          'SELECT SUM($columnFileSize) as total_size FROM $cachedImagesTable');
      final int totalSize = sizeResult.first['total_size'] as int? ?? 0;

      return {
        'totalImages': totalImages,
        'totalSizeBytes': totalSize,
        'cacheDirectory': _windowsCachePath,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error getting cache stats: $e');
      }
      return {
        'totalImages': 0,
        'totalSizeBytes': 0,
        'cacheDirectory': _windowsCachePath,
      };
    }
  }

  /// Close database connection
  static Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;

        if (kDebugMode) {
          print('🔒 SQLiteHelper: Database connection closed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error closing database: $e');
      }
    }
  }

  /// Get Windows cache directory path
  static String get windowsCachePath => _windowsCachePath;

  /// Check if database is initialized
  static bool get isInitialized => _database != null;

  /// Force reinitialize database (useful for testing or after errors)
  static Future<void> reinitialize() async {
    try {
      await close();
      _database = await _initDatabase();
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error reinitializing database: $e');
      }
      rethrow;
    }
  }

  /// Delete cache database file (complete reset)
  static Future<void> deleteCacheDatabase() async {
    try {
      await close();

      final File dbFile = File(_databasePath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        if (kDebugMode) {
          print('🗑️ SQLiteHelper: Cache database file deleted');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SQLiteHelper: Error deleting cache database: $e');
      }
    }
  }
}
