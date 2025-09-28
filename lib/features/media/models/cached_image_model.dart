import 'dart:io';
import 'package:flutter/foundation.dart';

/// Model for cached image data stored in SQLite
class CachedImageModel {
  final int? id;
  final int entityId;
  final String entityCategory;
  final int imageId;
  final String imageUrl;
  final String filePath;
  final DateTime updatedAt;
  final DateTime createdAt;
  final int fileSize;

  const CachedImageModel({
    this.id,
    required this.entityId,
    required this.entityCategory,
    required this.imageId,
    required this.imageUrl,
    required this.filePath,
    required this.updatedAt,
    required this.createdAt,
    required this.fileSize,
  });

  /// Create from JSON/Map (from SQLite)
  factory CachedImageModel.fromMap(Map<String, dynamic> map) {
    return CachedImageModel(
      id: map['id'] as int?,
      entityId: map['entity_id'] as int,
      entityCategory: map['entity_category'] as String,
      imageId: map['image_id'] as int,
      imageUrl: map['image_url'] as String,
      filePath: map['file_path'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      fileSize: map['file_size'] as int,
    );
  }

  /// Convert to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'entity_id': entityId,
      'entity_category': entityCategory,
      'image_id': imageId,
      'image_url': imageUrl,
      'file_path': filePath,
      'updated_at': updatedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'file_size': fileSize,
    };
  }

  /// Generate cache key for this image
  String get cacheKey => '${entityCategory}_${entityId}_$imageId';

  /// Check if the cached file exists on disk
  Future<bool> fileExists() async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      if (kDebugMode) {
        print('❌ CachedImageModel: Error checking file existence: $e');
      }
      return false;
    }
  }

  /// Get file size from disk (to verify integrity)
  Future<int?> getActualFileSize() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ CachedImageModel: Error getting file size: $e');
      }
      return null;
    }
  }

  /// Check if cache is valid compared to server updated_at timestamp
  bool isValidCache(DateTime serverUpdatedAt) {
    // Cache is valid if our cached version is newer than or equal to server version
    return updatedAt.isAtSameMomentAs(serverUpdatedAt) ||
        updatedAt.isAfter(serverUpdatedAt);
  }

  /// Check if cache is older than specified duration
  bool isOlderThan(Duration duration) {
    final now = DateTime.now();
    return now.difference(createdAt) > duration;
  }

  /// Format file size for display
  String get formattedFileSize {
    if (fileSize == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = fileSize.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(size.truncateToDouble() == size ? 0 : 1)} ${suffixes[i]}';
  }

  /// Create a copy with updated values
  CachedImageModel copyWith({
    int? id,
    int? entityId,
    String? entityCategory,
    int? imageId,
    String? imageUrl,
    String? filePath,
    DateTime? updatedAt,
    DateTime? createdAt,
    int? fileSize,
  }) {
    return CachedImageModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityCategory: entityCategory ?? this.entityCategory,
      imageId: imageId ?? this.imageId,
      imageUrl: imageUrl ?? this.imageUrl,
      filePath: filePath ?? this.filePath,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  /// Validate the model data
  bool isValid() {
    return entityId > 0 &&
        entityCategory.isNotEmpty &&
        imageId > 0 &&
        imageUrl.isNotEmpty &&
        filePath.isNotEmpty &&
        fileSize >= 0;
  }

  /// Get the file extension from the file path
  String get fileExtension {
    return filePath.split('.').last.toLowerCase();
  }

  /// Check if the cached image is an image file based on extension
  bool get isImageFile {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    return imageExtensions.contains(fileExtension);
  }

  /// Delete the cached file from disk
  Future<bool> deleteFile() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return true; // File doesn't exist, consider it "deleted"
    } catch (e) {
      if (kDebugMode) {
        print('❌ CachedImageModel: Error deleting file: $e');
      }
      return false;
    }
  }

  @override
  String toString() {
    return 'CachedImageModel{id: $id, entityId: $entityId, entityCategory: $entityCategory, '
        'imageId: $imageId, imageUrl: $imageUrl, filePath: $filePath, '
        'updatedAt: $updatedAt, createdAt: $createdAt, fileSize: $fileSize}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CachedImageModel &&
        other.entityId == entityId &&
        other.entityCategory == entityCategory &&
        other.imageId == imageId &&
        other.imageUrl == imageUrl &&
        other.filePath == filePath;
  }

  @override
  int get hashCode {
    return entityId.hashCode ^
        entityCategory.hashCode ^
        imageId.hashCode ^
        imageUrl.hashCode ^
        filePath.hashCode;
  }

  /// Create an empty/invalid cached image model
  factory CachedImageModel.empty() {
    return CachedImageModel(
      entityId: -1,
      entityCategory: '',
      imageId: -1,
      imageUrl: '',
      filePath: '',
      updatedAt: DateTime.now(),
      createdAt: DateTime.now(),
      fileSize: 0,
    );
  }

  /// Check if this is an empty/invalid model
  bool get isEmpty => entityId == -1 || entityCategory.isEmpty || imageId == -1;
}
