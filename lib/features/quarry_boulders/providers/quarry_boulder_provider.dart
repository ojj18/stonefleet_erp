import 'package:flutter/foundation.dart';
import '../models/quarry_boulder_trip_model.dart';
import '../repositories/quarry_boulder_repository.dart';

class QuarryBoulderProvider extends ChangeNotifier {
  final QuarryBoulderRepository _repository;
  QuarryBoulderProvider({QuarryBoulderRepository? repository}) : _repository = repository ?? QuarryBoulderRepository();

  List<QuarryBoulderTrip> trips = [];
  List<Map<String, dynamic>> driverSummary = [];
  List<Map<String, dynamic>> lorrySummary = [];
  QuarryBoulderSummary summary = const QuarryBoulderSummary();
  bool isLoading = false;
  String? error;

  Future<void> loadTrips({DateTime? fromDate, DateTime? toDate, String? registrationNumber, String? driverName}) async {
    await _run(() async {
      trips = await _repository.getTrips(fromDate: fromDate, toDate: toDate, registrationNumber: registrationNumber, driverName: driverName);
      summary = await _repository.getSummary(fromDate: fromDate, toDate: toDate, driverName: driverName);
    });
  }

  Future<void> loadReports({DateTime? fromDate, DateTime? toDate, String? driverName}) async {
    await _run(() async {
      summary = await _repository.getSummary(fromDate: fromDate, toDate: toDate, driverName: driverName);
      driverSummary = await _repository.getDriverSummary(fromDate: fromDate, toDate: toDate);
      lorrySummary = await _repository.getLorrySummary(fromDate: fromDate, toDate: toDate);
      trips = await _repository.getTrips(fromDate: fromDate, toDate: toDate, driverName: driverName);
    });
  }

  Future<bool> saveTrip({required String tripDate, required int transportVehicleId, required String registrationNumber, required String driverName, required String producerName, required double unit, required int tripsCount}) async {
    return _save(QuarryBoulderTrip(
      tripDate: tripDate,
      transportVehicleId: transportVehicleId,
      registrationNumber: registrationNumber,
      driverName: driverName.trim(),
      producerName: producerName.trim(),
      unit: unit,
      trips: tripsCount,
      totalLoad: tripsCount * unit,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<bool> updateTrip({required int id, required String tripDate, required int transportVehicleId, required String registrationNumber, required String driverName, required String producerName, required double unit, required int tripsCount}) async {
    final old = await _repository.getById(id);
    if (old == null) { error = 'Trip record not found.'; notifyListeners(); return false; }
    return _save(QuarryBoulderTrip(
      id: id,
      tripDate: tripDate,
      transportVehicleId: transportVehicleId,
      registrationNumber: registrationNumber,
      driverName: driverName.trim(),
      producerName: producerName.trim(),
      unit: unit,
      trips: tripsCount,
      totalLoad: tripsCount * unit,
      createdAt: old.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    ), update: true);
  }

  Future<bool> _save(QuarryBoulderTrip trip, {bool update = false}) async {
    await _run(() async { if (update) { await _repository.update(trip); } else { await _repository.insert(trip); } });
    return error == null;
  }

  Future<bool> deleteTrip(int id) async {
    await _run(() async { await _repository.delete(id); });
    return error == null;
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true; error = null; notifyListeners();
    try { await action(); } catch (e) { error = e.toString(); }
    finally { isLoading = false; notifyListeners(); }
  }
}
