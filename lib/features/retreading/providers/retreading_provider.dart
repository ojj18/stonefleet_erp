import 'package:flutter/foundation.dart';
import '../models/retreading_model.dart';
import '../repositories/retreading_repository.dart';

class RetreadingProvider extends ChangeNotifier {
  final RetreadingRepository _repository;
  RetreadingProvider({RetreadingRepository? repository}) : _repository = repository ?? RetreadingRepository();

  List<RetreadingRecord> records = [];
  RetreadingSummary summary = const RetreadingSummary();
  bool isLoading = false;
  String? error;

  Future<void> load({DateTime? fromDate, DateTime? toDate, String? registrationNumber, String? status, String? serial}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      records = await _repository.getRecords(
        fromDate: fromDate,
        toDate: toDate,
        registrationNumber: registrationNumber,
        status: status,
        tyreSerialNumber: serial,
      );
      summary = await _repository.getSummary(fromDate: fromDate, toDate: toDate);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required int transportVehicleId,
    required String registrationNumber,
    required String tyreBrand,
    required String tyreSerialNumber,
    required String tyreSize,
    required String retreadingCompany,
    required String sentDate,
    String? remarks,
  }) async {
    try {
      error = null;
      final existing = await _repository.getOpenBySerial(tyreSerialNumber);
      if (existing != null) {
        error = 'This tyre is already marked as At Retreading.';
        notifyListeners();
        return false;
      }
      await _repository.insert(RetreadingRecord(
        transportVehicleId: transportVehicleId,
        registrationNumber: registrationNumber.trim(),
        tyreBrand: tyreBrand.trim(),
        tyreSerialNumber: tyreSerialNumber.trim(),
        tyreSize: tyreSize.trim(),
        retreadingCompany: retreadingCompany.trim(),
        sentDate: sentDate,
        status: 'AT_RETREADING',
        remarks: remarks,
        createdAt: DateTime.now().toIso8601String(),
      ));
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(RetreadingRecord record) async {
    try {
      error = null;
      await _repository.update(record);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markReturned({
    required int id,
    required String returnDate,
    required double cost,
    String? billNumber,
    String? guarantee,
    String? remarks,
  }) async {
    try {
      error = null;
      await _repository.markReturned(
        id: id,
        returnDate: returnDate,
        cost: cost,
        billNumber: billNumber,
        guarantee: guarantee,
        remarks: remarks,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      error = null;
      await _repository.delete(id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
