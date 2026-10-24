import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';

import '../../../data/models/inventory_models.dart';
import '../../../data/models/ocr/spare_purchase_ocr_model.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/services/ocr_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  final OcrService _ocrService;

  InventoryProvider({InventoryRepository? repository, OcrService? ocrService})
      : _repository = repository ?? InventoryRepository(),
        _ocrService = ocrService ?? const OcrService();

  InventorySummary summary = const InventorySummary();
  List<InventoryPurchaseRow> purchases = [];
  List<InventoryStockRow> stock = [];
  List<InventoryUsageRow> usage = [];
  List<Map<String, dynamic>> reportRows = [];
  List<InventoryItemModel> items = [];

  bool isLoading = false;
  bool isExtracting = false;
  String? error;

  Future<void> loadDashboard() async {
    await _run(() async {
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
      usage = await _repository.getUsage();
    });
  }

  Future<void> loadPurchases({String? search, DateTime? fromDate, DateTime? toDate}) async {
    await _run(() async {
      purchases = await _repository.getPurchases(search: search, fromDate: fromDate, toDate: toDate);
      summary = await _repository.getSummary();
    });
  }

  Future<void> loadStock({String? search}) async {
    await _run(() async {
      stock = await _repository.getStock(search: search);
      summary = await _repository.getSummary();
    });
  }

  Future<void> loadUsage({String? search}) async {
    await _run(() async {
      usage = await _repository.getUsage(search: search);
      summary = await _repository.getSummary();
    });
  }

  Future<void> loadItems() async {
    items = await _repository.getItems();
    notifyListeners();
  }

  Future<void> loadReport({
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String? itemName,
  }) async {
    await _run(() async {
      reportRows = await _repository.getReport(
        period: period,
        fromDate: fromDate,
        toDate: toDate,
        itemName: itemName,
      );
    });
  }

  Future<SparePurchaseOcrModel> extractBill(XFile file) async {
    isExtracting = true;
    error = null;
    notifyListeners();
    try {
      return await _ocrService.extractSparePurchase(file);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isExtracting = false;
      notifyListeners();
    }
  }

  Future<void> savePurchase(InventoryPurchaseInput input) async {
    await _run(() async {
      await _repository.createPurchase(input);
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
      stock = await _repository.getStock();
      items = await _repository.getItems();
    });
  }

  Future<void> saveUsage({
    required String itemName,
    required double quantityUsed,
    required String usageDate,
    String? usedFor,
    String? remarks,
  }) async {
    await _run(() async {
      await _repository.createUsage(
        itemName: itemName,
        quantityUsed: quantityUsed,
        usageDate: usageDate,
        usedFor: usedFor,
        remarks: remarks,
      );
      usage = await _repository.getUsage();
      stock = await _repository.getStock();
      summary = await _repository.getSummary();
    });
  }



  Future<void> updateStockItem({
    required int itemId,
    required String itemName,
    String? unit,
  }) async {
    await _run(() async {
      await _repository.updateStockItem(itemId: itemId, itemName: itemName, unit: unit);
      stock = await _repository.getStock();
      items = await _repository.getItems();
      summary = await _repository.getSummary();
    });
  }

  Future<void> deleteStockItem(int itemId) async {
    await _run(() async {
      await _repository.deleteStockItem(itemId);
      stock = await _repository.getStock();
      items = await _repository.getItems();
      summary = await _repository.getSummary();
    });
  }

  Future<void> updateUsage({
    required int id,
    required String itemName,
    required double quantityUsed,
    required String usageDate,
    String? usedFor,
    String? remarks,
  }) async {
    await _run(() async {
      await _repository.updateUsage(
        id: id,
        itemName: itemName,
        quantityUsed: quantityUsed,
        usageDate: usageDate,
        usedFor: usedFor,
        remarks: remarks,
      );
      usage = await _repository.getUsage();
      stock = await _repository.getStock();
      summary = await _repository.getSummary();
    });
  }

  Future<void> deleteUsage(int id) async {
    await _run(() async {
      await _repository.deleteUsage(id);
      usage = await _repository.getUsage();
      stock = await _repository.getStock();
      summary = await _repository.getSummary();
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
