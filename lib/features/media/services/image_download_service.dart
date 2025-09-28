import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageDownloadService {
  static ImageDownloadService? _instance;
  static ImageDownloadService get instance =>
      _instance ??= ImageDownloadService._();

  ImageDownloadService._();

  /// Download image from URL and save to local file
  Future<ImageDownloadResult> downloadAndSaveImage(
      String imageUrl, String filePath) async {
    try {
      if (kDebugMode) {
        print('🔄 ImageDownloadService: Starting download from: $imageUrl');
      }

      // Make HTTP request to download image
      final http.Response response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Download timeout', const Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        // Ensure directory exists
        final File file = File(filePath);
        final Directory directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Save image data to file
        await file.writeAsBytes(response.bodyBytes);

        // Verify file was created and get size
        if (await file.exists()) {
          final FileStat fileStat = await file.stat();

          if (kDebugMode) {
            print('✅ ImageDownloadService: Image downloaded successfully');
            print('   Size: ${_formatFileSize(fileStat.size)}');
            print('   Path: $filePath');
          }

          return ImageDownloadResult(
            success: true,
            filePath: filePath,
            fileSize: fileStat.size,
            message: 'Image downloaded successfully',
          );
        } else {
          throw Exception('File was not created after download');
        }
      } else {
        throw HttpException(
          'Failed to download image: HTTP ${response.statusCode}',
          uri: Uri.parse(imageUrl),
        );
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Download timeout: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download timeout: ${e.message}',
      );
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: HTTP error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'HTTP error: ${e.message}',
      );
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Network error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Unexpected error downloading image: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  /// Download image and return as bytes (for immediate display)
  Future<ImageDownloadResult> downloadImageAsBytes(String imageUrl) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 ImageDownloadService: Downloading image as bytes from: $imageUrl');
      }

      final http.Response response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
          'Cache-Control': 'no-cache',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Download timeout', const Duration(seconds: 30));
        },
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print(
              '✅ ImageDownloadService: Image downloaded as bytes successfully');
          print('   Size: ${_formatFileSize(response.bodyBytes.length)}');
        }

        return ImageDownloadResult(
          success: true,
          imageBytes: response.bodyBytes,
          fileSize: response.bodyBytes.length,
          message: 'Image downloaded successfully',
        );
      } else {
        throw HttpException(
          'Failed to download image: HTTP ${response.statusCode}',
          uri: Uri.parse(imageUrl),
        );
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Download timeout: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download timeout: ${e.message}',
      );
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: HTTP error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'HTTP error: ${e.message}',
      );
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Network error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Unexpected error downloading image: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  /// Download image with progress tracking
  Future<ImageDownloadResult> downloadImageWithProgress(
    String imageUrl,
    String filePath,
    Function(double progress)? onProgress,
  ) async {
    try {
      if (kDebugMode) {
        print(
            '🔄 ImageDownloadService: Starting download with progress from: $imageUrl');
      }

      final http.Client client = http.Client();
      final http.Request request = http.Request('GET', Uri.parse(imageUrl));

      request.headers.addAll({
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
      });

      final http.StreamedResponse response = await client.send(request);

      if (response.statusCode == 200) {
        // Ensure directory exists
        final File file = File(filePath);
        final Directory directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final List<int> bytes = [];
        int downloadedBytes = 0;
        final int? totalBytes = response.contentLength;

        await for (final List<int> chunk in response.stream) {
          bytes.addAll(chunk);
          downloadedBytes += chunk.length;

          if (totalBytes != null && onProgress != null) {
            final double progress = downloadedBytes / totalBytes;
            onProgress(progress);
          }
        }

        // Save to file
        await file.writeAsBytes(bytes);

        // Verify file was created and get size
        if (await file.exists()) {
          final FileStat fileStat = await file.stat();

          if (kDebugMode) {
            print(
                '✅ ImageDownloadService: Image downloaded with progress successfully');
            print('   Size: ${_formatFileSize(fileStat.size)}');
            print('   Path: $filePath');
          }

          return ImageDownloadResult(
            success: true,
            filePath: filePath,
            imageBytes: Uint8List.fromList(bytes),
            fileSize: fileStat.size,
            message: 'Image downloaded successfully',
          );
        } else {
          throw Exception('File was not created after download');
        }
      } else {
        throw HttpException(
          'Failed to download image: HTTP ${response.statusCode}',
          uri: Uri.parse(imageUrl),
        );
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Download timeout: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download timeout: ${e.message}',
      );
    } on HttpException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: HTTP error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'HTTP error: ${e.message}',
      );
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Network error: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Unexpected error downloading image: $e');
      }
      return ImageDownloadResult(
        success: false,
        message: 'Download failed: ${e.toString()}',
      );
    }
  }

  /// Check if URL is valid and accessible
  Future<bool> isImageUrlValid(String imageUrl) async {
    try {
      final http.Response response = await http.head(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: URL validation failed: $e');
      }
      return false;
    }
  }

  /// Get image content type from URL
  Future<String?> getImageContentType(String imageUrl) async {
    try {
      final http.Response response = await http.head(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.headers['content-type'];
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Error getting content type: $e');
      }
    }
    return null;
  }

  /// Get image size from URL without downloading the full image
  Future<int?> getImageSize(String imageUrl) async {
    try {
      final http.Response response = await http.head(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final String? contentLength = response.headers['content-length'];
        return contentLength != null ? int.tryParse(contentLength) : null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ImageDownloadService: Error getting image size: $e');
      }
    }
    return null;
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

  /// Batch download multiple images
  Future<List<ImageDownloadResult>> downloadMultipleImages(
    List<String> imageUrls,
    List<String> filePaths, {
    int maxConcurrent = 3,
  }) async {
    if (imageUrls.length != filePaths.length) {
      throw ArgumentError('imageUrls and filePaths must have the same length');
    }

    final List<ImageDownloadResult> results = [];
    final List<Future<ImageDownloadResult>> futures = [];

    for (int i = 0; i < imageUrls.length; i++) {
      futures.add(downloadAndSaveImage(imageUrls[i], filePaths[i]));

      // Limit concurrent downloads
      if (futures.length >= maxConcurrent || i == imageUrls.length - 1) {
        final batchResults = await Future.wait(futures);
        results.addAll(batchResults);
        futures.clear();
      }
    }

    return results;
  }
}

/// Result class for image download operations
class ImageDownloadResult {
  final bool success;
  final String? filePath;
  final Uint8List? imageBytes;
  final int? fileSize;
  final String? message;

  const ImageDownloadResult({
    required this.success,
    this.filePath,
    this.imageBytes,
    this.fileSize,
    this.message,
  });

  @override
  String toString() {
    return 'ImageDownloadResult(success: $success, filePath: $filePath, '
        'fileSize: $fileSize, message: $message)';
  }
}

/// Custom exceptions for image downloading
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}
