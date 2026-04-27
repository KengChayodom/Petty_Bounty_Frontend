import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_config.dart';

import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class SightingRepository {

  final String baseUrl = AppConfig.apiBaseUrl;

  Future<String> uploadImage(String filePath) async {
  final request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/upload/pet-image'),
  );

  final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
  final mimeTypeSplit = mimeType.split('/');

  request.files.add(
    await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
    ),
  );

  final response = await request.send();
  if (response.statusCode == 200) {
    final responseData = await response.stream.bytesToString();
    final json = jsonDecode(responseData);
    return json['image_url'];
  } else {
    throw Exception('Failed to upload image.');
  }
}

  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sightings/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_url': imageUrl}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze image with AI.');
    }
  }
}

// Provider for injecting the repository easily
final sightingRepositoryProvider = Provider<SightingRepository>((ref) {
  return SightingRepository();
});