import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

abstract final class MediaCompressor {
  /// Compresses an image file to reduce bandwidth and Cloudinary quota usage.
  /// Typically reduces a 4MB photo to ~250-400KB without visible quality loss.
  static Future<File> compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 78,
        minWidth: 1280,
        minHeight: 1280,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (_) {}

    return file; // fallback to original file if compression fails
  }
}

