import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class MediaUploader {
  final String filePath;

  MediaUploader({required this.filePath});

  Future<Map<String, dynamic>> upload() async {
    File file = File(filePath);
    List<int> bytes = await file.readAsBytes();

    final mimeTypeData = lookupMimeType(filePath, headerBytes: bytes);

    FormData formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filePath.split('/').last,
        contentType: MediaType.parse(mimeTypeData!),
      ),
    });

    final response = await Dio().post(
      'https://unityhub.fr/upload',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${await const FlutterSecureStorage().read(key: 'token')}',
        },
      ),
    );

    return response.data;
  }
}