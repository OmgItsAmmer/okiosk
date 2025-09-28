import 'dart:io';
import 'package:okiosk/features/media/controllers/image_cache_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final int entityId;
  final String entityCategory;
  final int? imageId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingProgress;
  final BorderRadius? borderRadius;

  const CachedNetworkImageWidget({
    super.key,
    required this.entityId,
    required this.entityCategory,
    this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.showLoadingProgress = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final ImageCacheController cacheController =
        Get.find<ImageCacheController>();

    return FutureBuilder<ImageCacheResult>(
      future: imageId != null
          ? cacheController.getCachedImageOrFetch(
              entityId: entityId,
              entityCategory: entityCategory,
              imageId: imageId!,
            )
          : cacheController.getMainImageWithCache(entityId, entityCategory),
      builder: (context, snapshot) {
        // Show loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(cacheController);
        }

        // Handle error state
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
          return _buildErrorWidget();
        }

        final ImageCacheResult result = snapshot.data!;

        // Build the image widget
        Widget imageWidget;

        if (result.imageBytes != null) {
          // Display from bytes (freshly downloaded)
          imageWidget = Image.memory(
            result.imageBytes!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        } else if (result.localFilePath != null) {
          // Display from local file (cached)
          imageWidget = Image.file(
            File(result.localFilePath!),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        } else {
          // Fallback to network image
          imageWidget = result.imageUrl != null
              ? Image.network(
                  result.imageUrl!,
                  width: width,
                  height: height,
                  fit: fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingWidget(cacheController);
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorWidget(),
                )
              : _buildErrorWidget();
        }

        // Apply border radius if specified
        if (borderRadius != null) {
          imageWidget = ClipRRect(
            borderRadius: borderRadius!,
            child: imageWidget,
          );
        }

        return imageWidget;
      },
    );
  }

  Widget _buildLoadingWidget(ImageCacheController cacheController) {
    if (!showLoadingProgress) {
      return placeholder ?? _buildDefaultPlaceholder();
    }

    final String cacheKey = imageId != null
        ? '${entityCategory}_${entityId}_$imageId'
        : '${entityCategory}_${entityId}_main';

    return Obx(() {
      final bool isLoading = cacheController.isImageLoading(cacheKey);
      final double progress = cacheController.getDownloadProgress(cacheKey);

      if (!isLoading && progress == 0.0) {
        return placeholder ?? _buildDefaultPlaceholder();
      }

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (placeholder != null) placeholder!,
            if (isLoading && progress > 0.0)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(Get.context!).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image,
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.broken_image,
            size: (width != null && height != null)
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 48,
            color: Colors.grey[400],
          ),
        );
  }
}

/// Simplified widget for product cards
class CachedProductImage extends StatelessWidget {
  final int productId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedProductImage({
    super.key,
    required this.productId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImageWidget(
      entityId: productId,
      entityCategory: 'products',
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Cached brand image widget
class CachedBrandImage extends StatelessWidget {
  final int brandId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedBrandImage({
    super.key,
    required this.brandId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImageWidget(
      entityId: brandId,
      entityCategory: 'brands',
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}

/// Cached category image widget
class CachedCategoryImage extends StatelessWidget {
  final int categoryId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedCategoryImage({
    super.key,
    required this.categoryId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImageWidget(
      entityId: categoryId,
      entityCategory: 'categories',
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
