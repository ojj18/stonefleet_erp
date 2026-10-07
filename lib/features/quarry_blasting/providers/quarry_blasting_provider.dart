import 'package:flutter/foundation.dart';

import '../../../data/models/quarry_blasting_purchase_model.dart';
import '../../../data/repositories/quarry_blasting_repository.dart';

class QuarryBlastingProvider extends ChangeNotifier {
  final QuarryBlastingRepository _repository;

  QuarryBlastingProvider({QuarryBlastingRepository? repository})
      : _repository = repository ?? QuarryBlastingRepository();

  QuarryPurchaseSummary summary = const QuarryPurchaseSummary();
  List<QuarryBlastingPurchase> purchases = [];
  bool isLoading = false;
  String? error;

  Future<void> loadDashboard() async {
    await _run(() async {
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
    });
  }

  Future<void> loadPurchases({
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    String? operatorName,
  }) async {
    await _run(() async {
      purchases = await _repository.getPurchases(
        search: search,
        fromDate: fromDate,
        toDate: toDate,
        operatorName: operatorName,
      );
      summary = await _repository.getSummary(
        fromDate: fromDate,
        toDate: toDate,
        operatorName: operatorName,
      );
    });
  }

  Future<void> loadReport({
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
    String? operatorName,
  }) async {
    DateTime? from = fromDate;
    DateTime? to = toDate;
    final now = DateTime.now();

    if (period == 'Daily') {
      from = DateTime(now.year, now.month, now.day);
      to = from;
    } else if (period == 'Weekly') {
      final dayOffset = now.weekday - DateTime.monday;
      from = DateTime(now.year, now.month, now.day - dayOffset);
      to = DateTime(now.year, now.month, now.day);
    } else if (period == 'Monthly') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0);
    } else if (period == 'Yearly') {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year, 12, 31);
    }

    await loadPurchases(fromDate: from, toDate: to, operatorName: operatorName);
  }

  Future<void> savePurchase({
    required String purchaseDate,
    required String operatorName,
    required double salary,
    required double bulletQuantity,
    required double bulletPrice,
    required double wire3mQuantity,
    required double wire3mPrice,
    required double wire4mQuantity,
    required double wire4mPrice,
    required double edQuantity,
    required double edPrice,
  }) async {
    await _run(() async {
      await _repository.createPurchase(
        purchaseDate: purchaseDate,
        operatorName: operatorName,
        salary: salary,
        bulletQuantity: bulletQuantity,
        bulletPrice: bulletPrice,
        wire3mQuantity: wire3mQuantity,
        wire3mPrice: wire3mPrice,
        wire4mQuantity: wire4mQuantity,
        wire4mPrice: wire4mPrice,
        edQuantity: edQuantity,
        edPrice: edPrice,
      );
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
    });
  }


  Future<void> updatePurchase({
    required int id,
    required String purchaseDate,
    required String operatorName,
    required double salary,
    required double bulletQuantity,
    required double bulletPrice,
    required double wire3mQuantity,
    required double wire3mPrice,
    required double wire4mQuantity,
    required double wire4mPrice,
    required double edQuantity,
    required double edPrice,
  }) async {
    await _run(() async {
      await _repository.updatePurchase(
        id: id,
        purchaseDate: purchaseDate,
        operatorName: operatorName,
        salary: salary,
        bulletQuantity: bulletQuantity,
        bulletPrice: bulletPrice,
        wire3mQuantity: wire3mQuantity,
        wire3mPrice: wire3mPrice,
        wire4mQuantity: wire4mQuantity,
        wire4mPrice: wire4mPrice,
        edQuantity: edQuantity,
        edPrice: edPrice,
      );
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
    });
  }

  Future<void> deletePurchase(int id) async {
    await _run(() async {
      await _repository.deletePurchase(id);
      summary = await _repository.getSummary();
      purchases = await _repository.getPurchases();
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
