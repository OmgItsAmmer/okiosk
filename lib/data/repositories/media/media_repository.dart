

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../../features/media/models/image_entity_model.dart';
import '../../../features/media/models/image_model.dart';
import '../../../main.dart';

class MediaRepository extends GetxController {
  static MediaRepository get instance => Get.find();

  /// Fetch the main/featured image for an entity (product, brand, category, etc.)
  Future<String?> fetchMainImageUrl(int entityId, String entityType) async {
    try {
      // Step 1: Get the featured image ID from image_entity table
      final imageId = await _fetchMainImageId(entityId, entityType);
      if (imageId == -1) return null;

      // Step 2: Get image details from images table
      final imageModel = await _fetchImageDetails(imageId);
      if (imageModel.filename == null || imageModel.filename!.isEmpty) {
        return null;
      }

      // Step 3: Get public URL from storage
      return _getPublicImageUrl(imageModel.filename!, entityType);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching main image: $e");
      }
      return null;
    }
  }

  /// Fetch all images for an entity
  Future<List<String>> fetchAllImagesForEntity(
      int entityId, String entityType) async {
    try {
      // Get all image IDs for this entity
      final response = await supabase
          .from('image_entity')
          .select('image_id')
          .eq('entity_id', entityId)
          .eq('entity_category', entityType);

      if (response.isEmpty) return [];

      List<String> imageUrls = [];

      for (var item in response) {
        final imageId = item['image_id'] as int?;
        if (imageId != null) {
          final imageModel = await _fetchImageDetails(imageId);
          if (imageModel.filename != null && imageModel.filename!.isNotEmpty) {
            final url = await _getPublicImageUrl(imageModel.filename!, entityType);
            if (url != null) imageUrls.add(url);
          }
        }
      }

      return imageUrls;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching all images for entity: $e");
      }
      return [];
    }
  }

  /// Fetch multiple main images for a list of entities (optimized for product lists)
  Future<Map<int, String>> fetchMultipleMainImages(
      List<int> entityIds, String entityType) async {
    try {
      Map<int, String> imageMap = {};

      if (entityIds.isEmpty) return imageMap;

      // Get all featured images for these entities in one query
      final entityResponse = await supabase
          .from('image_entity')
          .select('entity_id, image_id')
          .eq('entity_category', entityType)
          .eq('isFeatured', true)
          .contains('entity_id', entityIds);

      if (entityResponse.isEmpty) return imageMap;

      // Extract image IDs
      final imageIds = entityResponse
          .map((item) => item['image_id'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toList();

      if (imageIds.isEmpty) return imageMap;

      // Get all image details in one query
      final imagesResponse = await supabase
          .from('images')
          .select('image_id, filename')
          .contains('image_id', imageIds);

      // Create a map of image_id to filename
      Map<int, String> imageIdToFilename = {};
      for (var image in imagesResponse) {
        final imageId = image['image_id'] as int?;
        final filename = image['filename'] as String?;
        if (imageId != null && filename != null && filename.isNotEmpty) {
          imageIdToFilename[imageId] = filename;
        }
      }

      // Map entity IDs to image URLs
      for (var entity in entityResponse) {
        final entityId = entity['entity_id'] as int?;
        final imageId = entity['image_id'] as int?;

        if (entityId != null && imageId != null) {
          final filename = imageIdToFilename[imageId];
          if (filename != null) {
            final url = await _getPublicImageUrl(filename, entityType);
            if (url != null) {
              imageMap[entityId] = url;
            }
          }
        }
      }

      return imageMap;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching multiple main images: $e");
      }
      return {};
    }
  }

  /// Private helper: Get the featured image ID for an entity
  Future<int> _fetchMainImageId(int entityId, String entityType) async {
    try {
      final response = await supabase
          .from('image_entity')
          .select('image_id')
          .eq('entity_id', entityId)
          .eq('entity_category', entityType)
          .eq('isFeatured', true)
          .maybeSingle();

      if (response == null) return -1;

      final imageEntityModel = ImageEntityModel.fromJson(response);
      return imageEntityModel.imageId ?? -1;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching main image ID: $e");
      }
      return -1;
    }
  }

  /// Private helper: Get image details from images table
  Future<ImageModel> _fetchImageDetails(int imageId) async {
    try {
      final response = await supabase
          .from('images')
          .select('*')
          .eq('image_id', imageId)
          .single();

      return ImageModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error fetching image details: $e");
      }
      return ImageModel.empty();
    }
  }

  /// Private helper: Get public URL from storage
  Future<String?> _getPublicImageUrl(String filename, String bucketName) async {
    try {
      return await supabase.storage
          .from(bucketName)
          .createSignedUrl(filename, 60);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error getting public URL: $e");
      }
      return null;
    }
  }

  /// Check if an entity has any images
  Future<bool> hasImages(int entityId, String entityType) async {
    try {
      final response = await supabase
          .from('image_entity')
          .select('image_entity_id')
          .eq('entity_id', entityId)
          .eq('entity_category', entityType)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error checking if entity has images: $e");
      }
      return false;
    }
  }

  /// Upload image to Supabase storage and save metadata to database
  Future<String?> uploadImage(
    File imageFile,
    String entityType,
    int entityId, {
    bool isFeatured = true,
  }) async {
    try {
      // Generate unique filename
      final String filename = _generateUniqueFilename(imageFile.path);

      // Upload to Supabase storage
      final String? uploadedUrl =
          await _uploadToStorage(imageFile, filename, entityType);
      if (uploadedUrl == null) {
        throw Exception('Failed to upload image to storage');
      }

      // Save image metadata to database
      final int imageId = await _saveImageMetadata(filename, entityType);
      if (imageId == -1) {
        throw Exception('Failed to save image metadata');
      }

      // Create image-entity relationship
      final bool relationshipCreated = await _createImageEntityRelationship(
        imageId,
        entityId,
        entityType,
        isFeatured,
      );
      if (!relationshipCreated) {
        throw Exception('Failed to create image-entity relationship');
      }

      return uploadedUrl;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error uploading image: $e");
      }
      return null;
    }
  }

  /// Update existing image (replace old image with new one)
  Future<String?> updateImage(
    File imageFile,
    String entityType,
    int entityId, {
    bool isFeatured = true,
  }) async {
    try {
      // Delete existing image first
      await deleteEntityImages(entityId, entityType);

      // Upload new image
      return await uploadImage(imageFile, entityType, entityId,
          isFeatured: isFeatured);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating image: $e");
      }
      return null;
    }
  }

  /// Delete all images for an entity
  Future<bool> deleteEntityImages(int entityId, String entityType) async {
    try {
      // Get all image IDs for this entity
      final response = await supabase
          .from('image_entity')
          .select('image_id')
          .eq('entity_id', entityId)
          .eq('entity_category', entityType);

      if (response.isEmpty) return true;

      // Delete from storage and database for each image
      for (var item in response) {
        final imageId = item['image_id'] as int?;
        if (imageId != null) {
          await _deleteImage(imageId, entityType);
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error deleting entity images: $e");
      }
      return false;
    }
  }

  /// Private helper: Generate unique filename
  String _generateUniqueFilename(String originalPath) {
    final String extension = originalPath.split('.').last;
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String randomString =
        (1000 + (DateTime.now().microsecond % 9000)).toString();
    return 'img_${timestamp}_$randomString.$extension';
  }

  /// Private helper: Upload file to Supabase storage
  Future<String?> _uploadToStorage(
      File file, String filename, String bucketName) async {
    try {
      await supabase.storage.from(bucketName).upload(filename, file);
      return supabase.storage.from(bucketName).getPublicUrl(filename);
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error uploading to storage: $e");
      }
      return null;
    }
  }

  /// Private helper: Save image metadata to database
  Future<int> _saveImageMetadata(String filename, String folderType) async {
    try {
      final response = await supabase
          .from('images')
          .insert({
            'filename': filename,
            'folderType': folderType,
          })
          .select('image_id')
          .single();

      return response['image_id'] as int;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error saving image metadata: $e");
      }
      return -1;
    }
  }

  /// Private helper: Create image-entity relationship
  Future<bool> _createImageEntityRelationship(
    int imageId,
    int entityId,
    String entityCategory,
    bool isFeatured,
  ) async {
    try {
      await supabase.from('image_entity').insert({
        'image_id': imageId,
        'entity_id': entityId,
        'entity_category': entityCategory,
        'isFeatured': isFeatured,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error creating image-entity relationship: $e");
      }
      return false;
    }
  }

  /// Private helper: Delete image from storage and database
  Future<bool> _deleteImage(int imageId, String bucketName) async {
    try {
      // Get image details first
      final imageDetails = await _fetchImageDetails(imageId);
      if (imageDetails.filename != null && imageDetails.filename!.isNotEmpty) {
        // Delete from storage
        await supabase.storage
            .from(bucketName)
            .remove([imageDetails.filename!]);
      }

      // Delete from image_entity table
      await supabase.from('image_entity').delete().eq('image_id', imageId);

      // Delete from images table
      await supabase.from('images').delete().eq('image_id', imageId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error deleting image: $e");
      }
      return false;
    }
  }
}
