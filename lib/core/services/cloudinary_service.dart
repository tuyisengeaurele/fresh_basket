import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Uploads images to Cloudinary using an **unsigned** upload preset.
/// No API secret is required or stored in the app.
class CloudinaryService {
  static final _dio = Dio();

  static String get _cloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload a local [File] to Cloudinary.
  /// Returns the secure HTTPS URL of the uploaded image.
  /// Throws an [Exception] on failure.
  static Future<String> uploadImage(
    File file, {
    String? folder,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
      'upload_preset': _uploadPreset,
      if (folder != null) 'folder': folder,
    });

    final response = await _dio.post(
      _uploadUrl,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final url = response.data['secure_url'] as String?;
      if (url != null && url.isNotEmpty) return url;
    }
    throw Exception('Cloudinary upload failed (status ${response.statusCode})');
  }
}
