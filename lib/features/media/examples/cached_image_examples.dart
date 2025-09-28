import 'package:flutter/material.dart';
import 'package:okiosk/common/widgets/images/cached_network_image_widget.dart';
import 'package:okiosk/features/media/controllers/image_cache_controller.dart';
import 'package:get/get.dart';

/// Example usage of the new image caching system
class CachedImageExamples extends StatelessWidget {
  const CachedImageExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Image Examples'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _showCacheManagementDialog,
            tooltip: 'Cache Management',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCacheStats(),
            const SizedBox(height: 20),
            _buildImageExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStats() {
    return GetBuilder<ImageCacheController>(
      builder: (controller) {
        final stats = controller.getCacheStatistics();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Total Images: ${stats['totalImages'] ?? 0}'),
                Text(
                    'Total Size: ${_formatFileSize(stats['totalSizeBytes'] ?? 0)}'),
                Text(
                    'Cache Directory: ${stats['cacheDirectory'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.updateCacheStats(),
                      child: const Text('Refresh Stats'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.clearAllCache(),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Clear All Cache'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image Examples',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Product Image Example
        _buildExample(
          'Product Image (ID: 1)',
          const CachedProductImage(
            productId: 1,
            width: 200,
            height: 200,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // Brand Image Example
        _buildExample(
          'Brand Image (ID: 1)',
          const CachedBrandImage(
            brandId: 1,
            width: 150,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // Category Image Example
        _buildExample(
          'Category Image (ID: 1)',
          const CachedCategoryImage(
            categoryId: 1,
            width: 150,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // Custom Cached Image Example
        _buildExample(
          'Custom Entity Image',
          const CachedNetworkImageWidget(
            entityId: 1,
            entityCategory: 'custom',
            width: 180,
            height: 180,
            showLoadingProgress: true,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildExample(String title, Widget imageWidget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageWidget,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showCacheManagementDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cache Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Cleanup Old Images'),
              subtitle: const Text('Remove images older than 30 days'),
              onTap: () async {
                Get.back();
                final controller = Get.find<ImageCacheController>();
                final count = await controller.cleanupOldImages();
                Get.snackbar(
                  'Cache Cleanup',
                  'Cleaned up $count old images',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Cleanup Orphaned Entries'),
              subtitle: const Text('Remove database entries without files'),
              onTap: () async {
                Get.back();
                final controller = Get.find<ImageCacheController>();
                final count = await controller.cleanupOrphanedEntries();
                Get.snackbar(
                  'Cache Cleanup',
                  'Cleaned up $count orphaned entries',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Cache'),
              subtitle: const Text('Remove all cached images'),
              onTap: () async {
                Get.back();
                final controller = Get.find<ImageCacheController>();
                final success = await controller.clearAllCache();
                Get.snackbar(
                  'Cache Management',
                  success
                      ? 'All cache cleared successfully'
                      : 'Failed to clear cache',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: success ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
}

/// Example of programmatic cache usage
class CacheUsageExample {
  static final ImageCacheController _cacheController =
      Get.find<ImageCacheController>();

  /// Example: Preload product images for a product list
  static Future<void> preloadProductImages(List<int> productIds) async {
    await _cacheController.preloadImages(productIds, 'products');
  }

  /// Example: Get cached image or fetch from server
  static Future<String?> getCachedProductImage(int productId) async {
    final result =
        await _cacheController.getMainImageWithCache(productId, 'products');

    if (result.success) {
      // If we have a cached file, return the local path for better performance
      if (result.localFilePath != null) {
        return result.localFilePath;
      }
      // Otherwise return the URL
      return result.imageUrl;
    }

    return null;
  }

  /// Example: Clear cache for specific product
  static Future<bool> clearProductCache(int productId) async {
    return await _cacheController.clearEntityCache(productId, 'products');
  }

  /// Example: Get cache statistics
  static Map<String, dynamic> getCacheInfo() {
    return _cacheController.getCacheStatistics();
  }

  /// Example: Cleanup old cached images
  static Future<int> performCacheMaintenance() async {
    final oldImagesCount = await _cacheController.cleanupOldImages();
    final orphanedCount = await _cacheController.cleanupOrphanedEntries();

    return oldImagesCount + orphanedCount;
  }
}
