import 'dart:convert';

import 'package:file_selector/file_selector.dart';

import 'package:http/http.dart' as http;

import '../models/ocr/excavator_maintenance_ocr_model.dart';
import '../models/ocr/excavator_service_ocr_model.dart';
import '../models/ocr/transport_maintenance_ocr_model.dart';
import '../models/ocr/transport_service_ocr_model.dart';

class OcrService {
  const OcrService();

  Future<ExcavatorMaintenanceOcrModel> extractExcavatorMaintenance(
    XFile imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();

    final imageBase64 = base64Encode(imageBytes);

    final mimeType = _getMimeType(imageFile.name);

    final response = await http.post(
      Uri.parse(
        'https://us-central1-stonefleeterp.cloudfunctions.net/'
        'extractExcavatorMaintenance',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': imageBase64, 'mimeType': mimeType}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OCR request failed: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    if (responseJson['success'] != true) {
      throw Exception(responseJson['message'] ?? 'OCR extraction failed.');
    }

    final data = responseJson['data'] as Map<String, dynamic>;

    return ExcavatorMaintenanceOcrModel.fromJson(data);
  }

  Future<ExcavatorServiceOcrModel> extractExcavatorService(
    XFile imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();

    final imageBase64 = base64Encode(imageBytes);

    final mimeType = _getMimeType(imageFile.name);

    final response = await http.post(
      Uri.parse(
        'https://us-central1-stonefleeterp.cloudfunctions.net/'
        'extractExcavatorService',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': imageBase64, 'mimeType': mimeType}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OCR request failed: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    if (responseJson['success'] != true) {
      throw Exception(responseJson['message'] ?? 'OCR extraction failed.');
    }

    final data = responseJson['data'] as Map<String, dynamic>;

    return ExcavatorServiceOcrModel.fromJson(data);
  }

  Future<TransportMaintenanceOcrModel> extractTransportMaintenance(
    XFile imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();

    final imageBase64 = base64Encode(imageBytes);

    final mimeType = _getMimeType(imageFile.name);

    final response = await http.post(
      Uri.parse(
        'https://us-central1-stonefleeterp.cloudfunctions.net/'
        'extractTransportMaintenance',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': imageBase64, 'mimeType': mimeType}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OCR request failed: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    if (responseJson['success'] != true) {
      throw Exception(responseJson['message'] ?? 'OCR extraction failed.');
    }

    final data = responseJson['data'] as Map<String, dynamic>;

    return TransportMaintenanceOcrModel.fromJson(data);
  }

  Future<TransportServiceOcrModel> extractTransportService(
    XFile imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final imageBase64 = base64Encode(imageBytes);
    final mimeType = _getMimeType(imageFile.name);

    final response = await http.post(
      Uri.parse(
        'https://us-central1-stonefleeterp.cloudfunctions.net/'
        'extractTransportService',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageBase64': imageBase64, 'mimeType': mimeType}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OCR request failed: ${response.statusCode}\n'
        '${response.body}',
      );
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    if (responseJson['success'] != true) {
      throw Exception(responseJson['message'] ?? 'OCR extraction failed.');
    }

    final data = responseJson['data'] as Map<String, dynamic>;

    return TransportServiceOcrModel.fromJson(data);
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
