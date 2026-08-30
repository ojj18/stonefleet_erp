import 'dart:convert';

import 'package:http/http.dart' as http;

class VehicleApiService {
  VehicleApiService({required this.apiKey});

  final String apiKey;

  static const String _baseUrl = 'https://api.parzival.info/v1/vehicle-info';

  Future<Map<String, dynamic>> getVehicleDetails(
    String registrationNumber,
  ) async {
    final registration = registrationNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .toUpperCase()
        .trim();

    if (registration.isEmpty) {
      throw Exception('Registration number is required.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'regNumber': registration}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Vehicle API failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid vehicle API response.');
    }

    if (decoded['valid'] == false) {
      throw Exception('Vehicle registration was not found.');
    }

    return decoded;
  }
}
