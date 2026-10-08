import 'package:flutter/foundation.dart';

import '../../../data/models/diesel_models.dart';
import '../../../data/repositories/diesel_repository.dart';

class DieselProvider extends ChangeNotifier {
  final DieselRepository _repository;

  DieselProvider({DieselRepository? repository})
      : _repository = repository ?? DieselRepository();

  DieselDashboardSummary summary = const DieselDashboardSummary();
  List<DieselVehicleOption> vehicles = [];
  List<DieselFillingRow> fillings = [];
  List<DieselReceiptRow> receipts = [];
  List<DieselStockMovementRow> movements = [];
  List<DieselVehicleConsumptionRow> consumption = [];
  List<DieselReportRow> reportRows = [];

  bool isLoading = false;
  String? error;

  Future<void> loadDashboard({DateTime? fromDate, DateTime? toDate}) async {
    await _run(() async {
      summary = await _repository.getSummary(fromDate: fromDate, toDate: toDate);
      fillings = await _repository.getFillings(fromDate: fromDate, toDate: toDate);
      consumption = await _repository.getConsumption(fromDate: fromDate, toDate: toDate);
    });
  }

  Future<void> loadVehicles() async {
    try {
      vehicles = await _repository.getVehicles();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFillingHistory({DateTime? fromDate, DateTime? toDate}) async {
    await _run(() async {
      fillings = await _repository.getFillings(
        fromDate: fromDate,
        toDate: toDate,
      );
    });
  }

  Future<void> loadStock() async {
    await _run(() async {
      summary = await _repository.getSummary();
      receipts = await _repository.getReceipts();
      movements = await _repository.getStockMovements();
    });
  }

  Future<void> loadConsumption({
    DateTime? fromDate,
    DateTime? toDate,
    String? vehicleType,
    int? vehicleId,
  }) async {
    await _run(() async {
      consumption = await _repository.getConsumption(
        fromDate: fromDate,
        toDate: toDate,
        vehicleType: vehicleType,
        vehicleId: vehicleId,
      );
    });
  }

  Future<void> loadReport({
    required DateTime fromDate,
    required DateTime toDate,
    String? vehicleType,
    int? vehicleId,
  }) async {
    await _run(() async {
      reportRows = await _repository.getReport(
        fromDate: fromDate,
        toDate: toDate,
        vehicleType: vehicleType,
        vehicleId: vehicleId,
      );
      summary = await _repository.getSummary(
        fromDate: fromDate,
        toDate: toDate,
      );
    });
  }

  Future<void> addReceipt({
    required String receiptDate,
    required String sourceName,
    required double quantityLitres,
    required double rate,
    String? supplierName,
    String? billNumber,
    String? remarks,
  }) async {
    await _run(() async {
      await _repository.createReceipt(
        receiptDate: receiptDate,
        sourceName: sourceName,
        quantityLitres: quantityLitres,
        rate: rate,
        supplierName: supplierName,
        billNumber: billNumber,
        remarks: remarks,
      );
      summary = await _repository.getSummary();
      receipts = await _repository.getReceipts();
      movements = await _repository.getStockMovements();
    });
  }

  Future<void> addFilling({
    required String fillingDate,
    required String vehicleType,
    required int vehicleId,
    required String vehicleRegistration,
    required double quantityLitres,
    required double rate,
    double? meterReading,
    String? operatorName,
    String? shift,
    String? remarks,
  }) async {
    await _run(() async {
      await _repository.createFilling(
        fillingDate: fillingDate,
        vehicleType: vehicleType,
        vehicleId: vehicleId,
        vehicleRegistration: vehicleRegistration,
        quantityLitres: quantityLitres,
        rate: rate,
        meterReading: meterReading,
        operatorName: operatorName,
        shift: shift,
        remarks: remarks,
      );
      summary = await _repository.getSummary();
      fillings = await _repository.getFillings();
    });
  }

  Future<void> updateReceipt({required int id, required String receiptDate, required String sourceName, required double quantityLitres, required double rate, String? supplierName, String? billNumber, String? remarks}) async {
    await _run(() async {
      await _repository.updateReceipt(id: id, receiptDate: receiptDate, sourceName: sourceName, quantityLitres: quantityLitres, rate: rate, supplierName: supplierName, billNumber: billNumber, remarks: remarks);
      summary = await _repository.getSummary();
      receipts = await _repository.getReceipts();
      movements = await _repository.getStockMovements();
    });
  }

  Future<void> deleteReceipt(int id) async {
    await _run(() async {
      await _repository.deleteReceipt(id);
      summary = await _repository.getSummary();
      receipts = await _repository.getReceipts();
      movements = await _repository.getStockMovements();
    });
  }

  Future<void> updateFilling({required int id, required String fillingDate, required String vehicleType, required int vehicleId, required String vehicleRegistration, required double quantityLitres, required double rate, double? meterReading, String? operatorName, String? shift, String? remarks}) async {
    await _run(() async {
      await _repository.updateFilling(id: id, fillingDate: fillingDate, vehicleType: vehicleType, vehicleId: vehicleId, vehicleRegistration: vehicleRegistration, quantityLitres: quantityLitres, rate: rate, meterReading: meterReading, operatorName: operatorName, shift: shift, remarks: remarks);
      summary = await _repository.getSummary();
      fillings = await _repository.getFillings();
    });
  }

  Future<void> deleteFilling(int id) async {
    await _run(() async {
      await _repository.deleteFilling(id);
      summary = await _repository.getSummary();
      fillings = await _repository.getFillings();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
