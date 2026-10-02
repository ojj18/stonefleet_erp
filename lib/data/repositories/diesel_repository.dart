import '../../core/database/database_helper.dart';
import '../models/diesel_models.dart';

class DieselRepository {
  final DatabaseHelper _databaseHelper;

  DieselRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<double> getCurrentStock() async {
    final db = await _databaseHelper.database;
    final row = (await db.rawQuery('''
      SELECT COALESCE(SUM(
        CASE
          WHEN transaction_type = 'RECEIPT' THEN quantity
          WHEN transaction_type = 'FILLING' THEN -quantity
          WHEN transaction_type = 'ADJUSTMENT' THEN quantity
          ELSE 0
        END
      ), 0) AS stock
      FROM diesel_stock_movements
    '''))[0];
    return (row['stock'] as num?)?.toDouble() ?? 0;
  }

  Future<DieselDashboardSummary> getSummary({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await _databaseHelper.database;
    final currentStock = await getCurrentStock();
    final fill = _dateConditions('filling_date', fromDate, toDate);
    final receipt = _dateConditions('receipt_date', fromDate, toDate);

    final fillingRow = (await db.rawQuery('''
      SELECT
        COALESCE(SUM(quantity_litres), 0) AS used,
        COALESCE(SUM(total_cost), 0) AS cost
      FROM diesel_fillings
      ${fill.whereSql}
    ''', fill.args))[0];

    final receiptRow = (await db.rawQuery('''
      SELECT COALESCE(SUM(quantity_litres), 0) AS received
      FROM diesel_receipts
      ${receipt.whereSql}
    ''', receipt.args))[0];

    final used = (fillingRow['used'] as num?)?.toDouble() ?? 0;
    final cost = (fillingRow['cost'] as num?)?.toDouble() ?? 0;
    final received = (receiptRow['received'] as num?)?.toDouble() ?? 0;

    return DieselDashboardSummary(
      currentStock: currentStock,
      received: received,
      used: used,
      totalCost: cost,
      openingStock: currentStock - received + used,
    );
  }

  Future<List<DieselVehicleOption>> getVehicles() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT id, registration_number, 'Excavator' AS vehicle_type
      FROM excavators
      WHERE status = 1
      UNION ALL
      SELECT id, registration_number, 'Transport' AS vehicle_type
      FROM transport_vehicles
      WHERE status = 1
      ORDER BY registration_number ASC
    ''');
    return rows.map(DieselVehicleOption.fromMap).toList();
  }

  Future<List<DieselFillingRow>> getFillings({
    DateTime? fromDate,
    DateTime? toDate,
    String? vehicleType,
    int? vehicleId,
  }) async {
    final db = await _databaseHelper.database;
    final c = _dateConditions('filling_date', fromDate, toDate);
    final conditions = <String>[...c.conditions];
    final args = <dynamic>[...c.args];

    if (vehicleType != null && vehicleType.isNotEmpty) {
      conditions.add('vehicle_type = ?');
      args.add(vehicleType);
    }
    if (vehicleId != null) {
      conditions.add('vehicle_id = ?');
      args.add(vehicleId);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT * FROM diesel_fillings
      $where
      ORDER BY filling_date DESC, id DESC
    ''', args);
    return rows.map(DieselFillingRow.fromMap).toList();
  }

  Future<List<DieselReceiptRow>> getReceipts() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT * FROM diesel_receipts
      ORDER BY receipt_date DESC, id DESC
    ''');
    return rows.map(DieselReceiptRow.fromMap).toList();
  }

  Future<List<DieselStockMovementRow>> getStockMovements() async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery('''
      SELECT * FROM diesel_stock_movements
      ORDER BY transaction_date DESC, id DESC
    ''');
    return rows.map(DieselStockMovementRow.fromMap).toList();
  }

  Future<List<DieselVehicleConsumptionRow>> getConsumption({
    DateTime? fromDate,
    DateTime? toDate,
    String? vehicleType,
    int? vehicleId,
  }) async {
    final db = await _databaseHelper.database;
    final c = _dateConditions('filling_date', fromDate, toDate);
    final conditions = <String>[...c.conditions];
    final args = <dynamic>[...c.args];

    if (vehicleType != null && vehicleType.isNotEmpty) {
      conditions.add('vehicle_type = ?');
      args.add(vehicleType);
    }
    if (vehicleId != null) {
      conditions.add('vehicle_id = ?');
      args.add(vehicleId);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT
        vehicle_type,
        vehicle_registration,
        COALESCE(SUM(quantity_litres), 0) AS quantity_litres,
        COALESCE(SUM(total_cost), 0) AS total_cost,
        COUNT(*) AS filling_count
      FROM diesel_fillings
      $where
      GROUP BY vehicle_type, vehicle_id, vehicle_registration
      ORDER BY quantity_litres DESC, vehicle_registration ASC
    ''', args);
    return rows.map(DieselVehicleConsumptionRow.fromMap).toList();
  }

  Future<List<DieselReportRow>> getReport({
    required DateTime fromDate,
    required DateTime toDate,
    String? vehicleType,
    int? vehicleId,
  }) async {
    final rows = await getFillings(
      fromDate: fromDate,
      toDate: toDate,
      vehicleType: vehicleType,
      vehicleId: vehicleId,
    );
    return rows
        .map((row) => DieselReportRow(
              date: row.fillingDate,
              vehicleType: row.vehicleType,
              vehicleRegistration: row.vehicleRegistration,
              litres: row.quantityLitres,
              rate: row.rate,
              cost: row.totalCost,
            ))
        .toList();
  }

  Future<void> createReceipt({
    required String receiptDate,
    required String sourceName,
    required double quantityLitres,
    required double rate,
    String? supplierName,
    String? billNumber,
    String? remarks,
  }) async {
    if (quantityLitres <= 0) throw ArgumentError('Quantity must be greater than 0.');
    if (rate < 0) throw ArgumentError('Rate cannot be negative.');

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final previous = await _stockFromTxn(txn);
      final totalCost = quantityLitres * rate;

      final id = await txn.insert('diesel_receipts', {
        'receipt_date': receiptDate,
        'source_name': sourceName.trim(),
        'quantity_litres': quantityLitres,
        'rate': rate,
        'total_cost': totalCost,
        'supplier_name': _nullable(supplierName),
        'bill_number': _nullable(billNumber),
        'remarks': _nullable(remarks),
        'created_at': now,
      });

      await txn.insert('diesel_stock_movements', {
        'transaction_type': 'RECEIPT',
        'quantity': quantityLitres,
        'previous_stock': previous,
        'current_stock': previous + quantityLitres,
        'reference_id': id,
        'transaction_date': receiptDate,
        'remarks': _nullable(remarks),
        'created_at': now,
      });
    });
  }

  Future<void> createFilling({
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
    if (quantityLitres <= 0) throw ArgumentError('Quantity must be greater than 0.');
    if (rate < 0) throw ArgumentError('Rate cannot be negative.');

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final previous = await _stockFromTxn(txn);

      if (quantityLitres > previous) {
        throw Exception(
          'Insufficient diesel stock. Available: ${previous.toStringAsFixed(2)} L',
        );
      }

      final id = await txn.insert('diesel_fillings', {
        'filling_date': fillingDate,
        'vehicle_type': vehicleType,
        'vehicle_id': vehicleId,
        'vehicle_registration': vehicleRegistration,
        'quantity_litres': quantityLitres,
        'rate': rate,
        'total_cost': quantityLitres * rate,
        'meter_reading': meterReading,
        'operator_name': _nullable(operatorName),
        'shift': _nullable(shift),
        'remarks': _nullable(remarks),
        'created_at': now,
      });

      await txn.insert('diesel_stock_movements', {
        'transaction_type': 'FILLING',
        'quantity': quantityLitres,
        'previous_stock': previous,
        'current_stock': previous - quantityLitres,
        'reference_id': id,
        'transaction_date': fillingDate,
        'remarks': _nullable(remarks),
        'created_at': now,
      });
    });
  }

  Future<double> _stockFromTxn(dynamic txn) async {
    final rows = await txn.rawQuery('''
      SELECT COALESCE(SUM(
        CASE
          WHEN transaction_type = 'RECEIPT' THEN quantity
          WHEN transaction_type = 'FILLING' THEN -quantity
          WHEN transaction_type = 'ADJUSTMENT' THEN quantity
          ELSE 0
        END
      ), 0) AS stock
      FROM diesel_stock_movements
    ''');
    return (rows.first['stock'] as num?)?.toDouble() ?? 0;
  }

  _DateConditions _dateConditions(String column, DateTime? from, DateTime? to) {
    final conditions = <String>[];
    final args = <dynamic>[];
    if (from != null) {
      conditions.add('date($column) >= date(?)');
      args.add(_dateOnly(from));
    }
    if (to != null) {
      conditions.add('date($column) <= date(?)');
      args.add(_dateOnly(to));
    }
    final whereSql =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    return _DateConditions(whereSql, conditions, args);
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _DateConditions {
  final String whereSql;
  final List<String> conditions;
  final List<dynamic> args;
  const _DateConditions(this.whereSql, this.conditions, this.args);
}
