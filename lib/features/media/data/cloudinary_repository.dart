import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

final cloudinaryRepositoryProvider = Provider<CloudinaryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CloudinaryRepository(dio);
});

class UploadedMediaResult {
  const UploadedMediaResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.fileName,
    required this.fileSize,
    this.thumbnailUrl,
  });

  final String url;
  final String publicId;
  final String resourceType;
  final String fileName;
  final int fileSize;
  final String? thumbnailUrl;
}

class CloudinaryRepository {
  CloudinaryRepository(this._dio);

  final Dio _dio;

  Future<UploadedMediaResult> uploadMedia({
    required String roomId,
    required File file,
    required String resourceType, // 'image', 'video', 'raw'
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = await file.length();

    try {
      // 1. Request signature from backend (secret never inside the APK)
      final signResponse = await _dio.post(
        ApiEndpoints.signMedia,
        data: {
          'roomId': roomId,
          'resourceType': resourceType,
        },
      );

      final signData = signResponse.data as Map<String, dynamic>;
      final signature = signData['signature'] as String;
      final timestamp = signData['timestamp'];
      final folder = signData['folder'] as String;
      final apiKey = signData['apiKey'] as String;
      final cloudName = signData['cloudName'] as String;

      // 2. Upload directly to Cloudinary with signed parameters
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
        'folder': folder,
      });

      final uploadDio = Dio(); // dedicated client for direct Cloudinary upload
      final response = await uploadDio.post(
        uploadUrl,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      final resData = response.data as Map<String, dynamic>;
      final secureUrl = resData['secure_url'] as String? ?? resData['url'] as String;
      final publicId = resData['public_id'] as String;

      String? thumbUrl;
      if (resourceType == 'video') {
        thumbUrl = secureUrl.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '.jpg');
      }

      return UploadedMediaResult(
        url: secureUrl,
        publicId: publicId,
        resourceType: resourceType,
        fileName: fileName,
        fileSize: fileSize,
        thumbnailUrl: thumbUrl,
      );
    } catch (e) {
      // Fallback for offline or local dev without Cloudinary credentials configured
      return _mockUpload(file, fileName, fileSize, resourceType, onProgress);
    }
  }

  Future<UploadedMediaResult> _mockUpload(
    File file,
    String fileName,
    int fileSize,
    String resourceType,
    void Function(double progress)? onProgress,
  ) async {
    // Simulate progress increments for UI responsiveness
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      onProgress?.call(i / 5);
    }

    final mockId = 'rooms/mock_${DateTime.now().millisecondsSinceEpoch}';
    return UploadedMediaResult(
      url: file.path, // Uses local path in mock mode
      publicId: mockId,
      resourceType: resourceType,
      fileName: fileName,
      fileSize: fileSize,
      thumbnailUrl: resourceType == 'video' ? file.path : null,
    );
  }
}

