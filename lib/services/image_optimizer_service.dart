import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageOptimizer {
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int thumbnailSize = 200;
  static const int jpegQuality = 85;

  static Future<File> optimizeImage(File imageFile, {int? maxWidth, int? maxHeight}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final targetWidth = maxWidth ?? maxImageWidth;
      final targetHeight = maxHeight ?? maxImageHeight;

      // Calculate new dimensions maintaining aspect ratio
      final originalWidth = originalImage.width.toDouble();
      final originalHeight = originalImage.height.toDouble();
      final aspectRatio = originalWidth / originalHeight;

      int newWidth, newHeight;
      if (originalWidth > targetWidth || originalHeight > targetHeight) {
        if (aspectRatio > 1) {
          newWidth = targetWidth;
          newHeight = (targetWidth / aspectRatio).round();
        } else {
          newHeight = targetHeight;
          newWidth = (targetHeight * aspectRatio).round();
        }
      } else {
        newWidth = originalWidth.toInt();
        newHeight = originalHeight.toInt();
      }

      // Resize image
      final resizedImage = await _resizeImage(originalImage, newWidth, newHeight);

      // Convert to JPEG with compression
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to convert image to bytes');

      // Save optimized image
      final optimizedPath = _getOptimizedImagePath(imageFile.path);
      final optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(byteData.buffer.asUint8List());

      return optimizedFile;
    } catch (e) {
      throw Exception('Failed to optimize image: $e');
    }
  }

  static Future<File> createThumbnail(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final originalImage = frame.image;

      final resizedImage = await _resizeImage(originalImage, thumbnailSize, thumbnailSize);
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to create thumbnail');

      final thumbnailPath = _getThumbnailPath(imageFile.path);
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(byteData.buffer.asUint8List());

      return thumbnailFile;
    } catch (e) {
      throw Exception('Failed to create thumbnail: $e');
    }
  }

  static Future<ui.Image> _resizeImage(
    ui.Image originalImage,
    int targetWidth,
    int targetHeight,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
      Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      Paint(),
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(targetWidth, targetHeight);
    picture.dispose();

    return resizedImage;
  }

  static String _getOptimizedImagePath(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    final ext = path.extension(originalPath);
    return path.join(dir, '${name}_optimized$ext');
  }

  static String _getThumbnailPath(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    return path.join(dir, '${name}_thumb.jpg');
  }

  static Future<bool> isImageOptimized(File imageFile) async {
    try {
      final optimizedPath = _getOptimizedImagePath(imageFile.path);
      final optimizedFile = File(optimizedPath);
      return await optimizedFile.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<File?> getOptimizedImage(File originalImage) async {
    if (await isImageOptimized(originalImage)) {
      return File(_getOptimizedImagePath(originalImage.path));
    }
    return null;
  }

  static Future<void> clearOptimizedImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;
      final dir = Directory(tempPath);

      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file is File && file.path.contains('_optimized') || file.path.contains('_thumb')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

class CachedNetworkImageOptimized extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useThumbnail;

  const CachedNetworkImageOptimized({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      useThumbnail ? _getThumbnailUrl(imageUrl) : imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildDefaultError();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: wasSynchronouslyLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      cacheWidth: useThumbnail ? ImageOptimizer.thumbnailSize : ImageOptimizer.maxImageWidth,
      cacheHeight: useThumbnail ? ImageOptimizer.thumbnailSize : ImageOptimizer.maxImageHeight,
    );
  }

  String _getThumbnailUrl(String url) {
    // Add thumbnail parameter if supported by your image service
    if (url.contains('?')) {
      return '$url&thumbnail=true';
    } else {
      return '$url?thumbnail=true';
    }
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: (width ?? height ?? 100) * 0.3, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: (width ?? height ?? 100) * 0.3,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

class AssetImageOptimized extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const AssetImageOptimized({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        return AnimatedOpacity(
          opacity: wasSynchronouslyLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? _buildDefaultError();
      },
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: (width ?? height ?? 100) * 0.3,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

class ImageCacheManager {
  static final Map<String, ui.Image> _imageCache = {};
  static const int maxCacheSize = 100;

  static Future<ui.Image?> getCachedImage(String key) async {
    return _imageCache[key];
  }

  static Future<void> cacheImage(String key, ui.Image image) async {
    if (_imageCache.length >= maxCacheSize) {
      _imageCache.clear();
    }
    _imageCache[key] = image;
  }

  static void clearCache() {
    _imageCache.clear();
  }

  static int get cacheSize => _imageCache.length;
}
