import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../models/vehicle_rc_response.dart';

class Way2ApiService {
  Future<VehicleRcModel> getVehicleDetails(String registrationNumber) async {
    // ------------------------------------------------------------
    // NORMALIZE REGISTRATION NUMBER
    // ------------------------------------------------------------

    final registration = registrationNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim()
        .toUpperCase();

    if (registration.isEmpty) {
      throw Exception('Registration number is required.');
    }

    // ------------------------------------------------------------
    // API REQUEST
    // ------------------------------------------------------------

    final response = await http.post(
      Uri.parse('${ApiConstants.way2ApiBaseUrl}/rc/verify'),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.way2ApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'rc_number': registration}),
    );

    // ------------------------------------------------------------
    // DECODE RESPONSE
    // ------------------------------------------------------------

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response received from Way2API.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response received from Way2API.');
    }

    // ------------------------------------------------------------
    // WAY2API MESSAGE CODE
    // ------------------------------------------------------------

    final messageCode = decoded['message_code']?.toString();

    final message = decoded['message']?.toString();

    final orderId = decoded['order_id']?.toString();

    // ------------------------------------------------------------
    // HTTP / API ERROR HANDLING
    // ------------------------------------------------------------

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (messageCode) {
        case 'INSUFFICIENT_BALANCE':
          throw Exception('Way2API wallet balance is insufficient.');

        case 'NO_API_ACCESS':
          throw Exception(
            'Vehicle RC Verification API is not enabled for your account.',
          );

        case 'INVALID_API_KEY':
          throw Exception('Way2API API key is invalid or expired.');

        case 'MISSING_API_KEY':
          throw Exception('Way2API API key is missing.');

        case 'RATE_LIMITED':
          throw Exception(
            'Way2API rate limit exceeded. Please try again later.',
          );

        case 'INVALID_INPUT':
          throw Exception(
            message?.isNotEmpty == true
                ? message!
                : 'Invalid vehicle registration number.',
          );

        case 'NO_RECORD_FOUND':
          throw Exception('No RC record found for $registration.');

        case 'VERIFICATION_FAILED':
          throw Exception('Vehicle verification failed for $registration.');

        case 'SOURCE_UNAVAILABLE':
          throw Exception(
            'Vehicle verification source is temporarily unavailable. Please try again.',
          );

        default:
          throw Exception(
            message?.isNotEmpty == true ? message! : 'Vehicle lookup failed.',
          );
      }
    }

    // ------------------------------------------------------------
    // SUCCESS CHECK
    // ------------------------------------------------------------

    if (decoded['success'] != true) {
      switch (messageCode) {
        case 'NO_RECORD_FOUND':
          throw Exception('No RC record found for $registration.');

        case 'VERIFICATION_FAILED':
          throw Exception('Vehicle verification failed for $registration.');

        case 'SOURCE_UNAVAILABLE':
          throw Exception(
            'Vehicle verification source is temporarily unavailable.',
          );

        case 'ACCEPTED':
          throw Exception(
            'Vehicle verification is still being processed.'
            '${orderId == null ? '' : ' Order ID: $orderId'}',
          );

        case 'PROVIDER_NO_RESPONSE':
          throw Exception(
            'Vehicle verification is pending provider response.'
            '${orderId == null ? '' : ' Order ID: $orderId'}',
          );

        default:
          throw Exception(
            message?.isNotEmpty == true
                ? message!
                : 'Vehicle verification failed.',
          );
      }
    }

    // ------------------------------------------------------------
    // GET DATA
    // ------------------------------------------------------------

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Vehicle details were not returned by Way2API.');
    }

    // ------------------------------------------------------------
    // GET RESULT
    // ------------------------------------------------------------

    final result = data['result'];

    if (result is! Map<String, dynamic>) {
      throw Exception('Vehicle details were not returned by Way2API.');
    }

    // ------------------------------------------------------------
    // CONVERT RESPONSE TO MODEL
    // ------------------------------------------------------------

    return VehicleRcModel.fromJson(result);
  }
}
