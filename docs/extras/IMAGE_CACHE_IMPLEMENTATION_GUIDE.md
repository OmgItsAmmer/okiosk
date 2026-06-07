# Image Caching System Implementation Guide

## Overview

This implementation provides a robust image caching system for your Flutter
Windows application using SQLite for metadata storage and local file system for
image storage. The system automatically downloads images from Supabase, caches
them locally, and serves them from cache for subsequent requests.

## Features

- ✅ **SQLite-based metadata storage** for cache management
- ✅ **Windows file system caching** at
  `C:\Users\ammer\OneDrive\Desktop\Okisosk_images`
- ✅ **Automatic cache validation** based on server timestamps
- ✅ **Progress tracking** for image downloads
- ✅ **Background maintenance** for cleanup of old/orphaned files
- ✅ **Memory and disk optimization**
- ✅ **Error handling and fallback mechanisms**
- ✅ **Integration with existing MediaController**

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│  CachedNetworkImageWidget  │  MediaController (Updated)    │
├─────────────────────────────────────────────────────────────┤
│                ImageCacheController                         │
├─────────────────────────────────────────────────────────────┤
│  ImageCacheService  │  ImageDownloadService                │
├─────────────────────────────────────────────────────────────┤
│  SQLiteHelper       │  CachedImageModel                    │
├─────────────────────────────────────────────────────────────┤
│  SQLite Database    │  Windows File System                │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/
├── utils/local_storage/
│   └── sqlite_helper.dart                     # SQLite database management
├── features/media/
│   ├── models/
│   │   └── cached_image_model.dart           # Cache metadata model
│   ├── services/
│   │   ├── image_cache_service.dart          # Cache CRUD operations
│   │   ├── image_download_service.dart       # HTTP download service
│   │   └── cache_initialization_service.dart # System initialization
│   ├── controllers/
│   │   └── image_cache_controller.dart       # Main cache controller
│   └── examples/
│       └── cached_image_examples.dart        # Usage examples
├── common/widgets/images/
│   └── cached_network_image_widget.dart      # UI components
└── main.dart                                  # Cache initialization
```

## Installation & Setup

### 1. Dependencies Added

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
    sqflite_common_ffi: ^2.3.0 # SQLite for Windows
    path_provider: ^2.1.1 # File path management
    path: ^1.8.3 # Path utilities
```

### 2. Initialization

The cache system is automatically initialized in `main.dart`:

```dart
// Initialize image caching system
await CacheInitializationService.instance.initializeCache();
```

### 3. Cache Directory

Images are cached at: `C:\Users\ammer\OneDrive\Desktop\Okisosk_images`

## Usage

### Basic Widget Usage

```dart
// Product image with automatic caching
CachedProductImage(
  productId: 123,
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(8),
)

// Brand image
CachedBrandImage(
  brandId: 456,
  width: 150,
  height: 100,
)

// Category image
CachedCategoryImage(
  categoryId: 789,
  width: 150,
  height: 100,
)

// Generic cached image
CachedNetworkImageWidget(
  entityId: 123,
  entityCategory: 'products',
  imageId: 456, // Optional: specific image ID
  width: 200,
  height: 200,
  showLoadingProgress: true,
  placeholder: CustomPlaceholderWidget(),
  errorWidget: CustomErrorWidget(),
)
```

### Programmatic Usage

```dart
final ImageCacheController cacheController = Get.find<ImageCacheController>();

// Get cached image or fetch from server
final result = await cacheController.getMainImageWithCache(123, 'products');
if (result.success) {
  // Use result.localFilePath or result.imageUrl
}

// Preload images for better performance
await cacheController.preloadImages([1, 2, 3, 4, 5], 'products');

// Clear cache for specific entity
await cacheController.clearEntityCache(123, 'products');

// Get cache statistics
final stats = cacheController.getCacheStatistics();
print('Total images: ${stats['totalImages']}');
print('Cache size: ${stats['totalSizeBytes']} bytes');

// Cleanup old images (older than 30 days)
final cleanedCount = await cacheController.cleanupOldImages();

// Clear all cache
await cacheController.clearAllCache();
```

### Integration with Existing MediaController

The existing `MediaController` has been updated to use the cache system
automatically:

```dart
final MediaController mediaController = Get.find<MediaController>();

// This now uses persistent cache if available
final imageUrl = await mediaController.fetchMainImage(123, 'products');

// Check if persistent cache is available
if (mediaController.isPersistentCacheAvailable) {
  // Get cache statistics
  final stats = mediaController.getCacheStatistics();
  
  // Cleanup old images
  final cleanedCount = await mediaController.cleanupOldCachedImages();
}
```

## Cache Management

### Automatic Maintenance

The system performs automatic maintenance on startup:

- Removes orphaned database entries (files that no longer exist)
- Cleans up old images (older than 30 days)
- Updates cache statistics

### Manual Maintenance

```dart
final cacheService = CacheInitializationService.instance;

// Perform manual maintenance
final result = await cacheService.performMaintenance();
print('Orphaned entries cleaned: ${result['orphanedCleaned']}');
print('Old images cleaned: ${result['oldImagesCleaned']}');

// Get comprehensive cache information
final info = await cacheService.getCacheInfo();

// Test cache system functionality
final isWorking = await cacheService.testCacheSystem();

// Clear all cache
await cacheService.clearAllCache();
```

### Cache Statistics

```dart
final controller = Get.find<ImageCacheController>();
final stats = controller.getCacheStatistics();

// Available statistics:
// - totalImages: Number of cached images
// - totalSizeBytes: Total size of cached data
// - actualDirectorySizeBytes: Actual directory size on disk
// - cacheDirectory: Path to cache directory
```

## Database Schema

The SQLite database contains a `cached_images` table:

```sql
CREATE TABLE cached_images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_id INTEGER NOT NULL,
  entity_category TEXT NOT NULL,
  image_id INTEGER NOT NULL,
  image_url TEXT NOT NULL,
  file_path TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  UNIQUE(entity_id, entity_category, image_id)
);
```

## Error Handling

The system includes comprehensive error handling:

1. **Network Errors**: Falls back to cached images or shows error widget
2. **File System Errors**: Attempts cleanup and shows appropriate messages
3. **Database Errors**: Logs errors and continues with fallback mechanisms
4. **Supabase Errors**: Graceful degradation to direct image loading

## Performance Considerations

1. **Download Throttling**: Prevents overwhelming Supabase with concurrent
   requests
2. **Memory Management**: Uses file-based caching to minimize memory usage
3. **Background Processing**: Maintenance tasks run in background
4. **Progressive Loading**: Shows cached images immediately while validating
   freshness

## Troubleshooting

### Common Issues

1. **Cache Directory Not Created**
   - Ensure the Windows user has write permissions to
     `C:\Users\ammer\OneDrive\Desktop\`
   - Check if the directory path exists and is accessible

2. **SQLite Initialization Errors**
   - Verify `sqflite_common_ffi` dependency is properly installed
   - Check if FFI initialization is working on Windows

3. **Image Download Failures**
   - Verify network connectivity
   - Check Supabase URL generation and authentication
   - Ensure signed URLs are valid and not expired

### Debug Information

Enable debug mode to see detailed logging:

```dart
// In main.dart or anywhere in debug mode
if (kDebugMode) {
  // Cache system will automatically print debug information
}
```

### Testing Cache System

```dart
final service = CacheInitializationService.instance;
final isWorking = await service.testCacheSystem();

if (!isWorking) {
  print('Cache system test failed - check debug logs');
  
  // Get detailed status
  final status = service.getInitializationStatus();
  print('Initialization status: $status');
}
```

## Migration from Previous System

The new cache system is designed to work alongside the existing MediaController:

1. **Automatic Fallback**: If the cache system fails, it falls back to the
   original repository-based image loading
2. **Gradual Migration**: Existing code continues to work while new code can use
   the cached widgets
3. **Performance Improvement**: Existing `fetchMainImage()` calls now benefit
   from persistent caching

## Best Practices

1. **Use Cached Widgets**: Replace `Image.network()` with
   `CachedNetworkImageWidget` or specific widgets like `CachedProductImage`
2. **Preload Images**: Use `preloadImages()` for lists that will be scrolled
   frequently
3. **Regular Maintenance**: Set up periodic cache cleanup in your app
4. **Monitor Cache Size**: Keep an eye on cache statistics to prevent unlimited
   growth
5. **Error Handling**: Always provide fallback placeholders for failed image
   loads

## Future Enhancements

Potential improvements for the future:

1. **Cache Size Limits**: Implement maximum cache size with LRU eviction
2. **Network State Awareness**: Pause downloads on poor network conditions
3. **Image Optimization**: Resize/compress images before caching
4. **Background Sync**: Update cached images in background when app is idle
5. **Cloud Backup**: Sync cache across devices (if needed)

---

## Technical Notes

- **Windows Compatibility**: Uses `sqflite_common_ffi` for Windows SQLite
  support
- **File Naming**: Cache files use format:
  `{category}_{entityId}_{imageId}_{timestamp}.{ext}`
- **Cache Validation**: Compares server `updated_at` with cached `updated_at`
- **Concurrent Safety**: Prevents duplicate downloads for the same image
- **Resource Cleanup**: Automatically removes orphaned files and database
  entries
