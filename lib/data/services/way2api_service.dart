import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/vehicle_rc_response.dart';

class Way2ApiService {
  Future<VehicleRcModel> getVehicleDetails(String registrationNumber) async {
    final registration = registrationNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim()
        .toUpperCase();

    if (registration.isEmpty) {
      throw Exception('Registration number is required.');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.way2ApiBaseUrl}/rc/text-pdf'),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.way2ApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rc_number': registration}),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from Way2API.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ?? 'Vehicle lookup failed.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Vehicle verification failed.',
      );
    }

    final data = decoded['data'] as Map<String, dynamic>?;

    final result = data?['result'] as Map<String, dynamic>?;

    if (result == null) {
      throw Exception('Vehicle details were not returned.');
    }

    return VehicleRcModel.fromJson(result);
  }
}
