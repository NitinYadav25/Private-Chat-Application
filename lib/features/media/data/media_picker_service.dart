import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import 'media_compressor.dart';

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService();
});

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return MediaCompressor.compressImage(File(picked.path));
  }

  Future<File?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return MediaCompressor.compressImage(File(picked.path));
  }

  Future<File?> pickVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<File?> pickDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );

    if (files.isEmpty) return null;
    final path = files.first.path;
    if (path == null) return null;

    final file = File(path);
    final size = await file.length();

    // Enforce 10 MB file size limit
    if (size > AppConstants.maxFileSizeBytes) {
      throw Exception(
        'File size exceeds the 10 MB limit (${(size / (1024 * 1024)).toStringAsFixed(1)} MB).',
      );
    }

    return file;
  }
}
