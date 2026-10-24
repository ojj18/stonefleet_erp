import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/database_helper.dart';

class AirBlowerOilRepository {
  final DatabaseHelper _helper;
  AirBlowerOilRepository({DatabaseHelper? databaseHelper})
    : _helper = databaseHelper ?? DatabaseHelper.instance;

  Future<Map<String, dynamic>> getStock() async {
    final db = await _helper.database;
    final rows = await db.query(
      'air_blower_oil_stock',
      where: 'id = 1',
      limit: 1,
    );
    return rows.isEmpty
        ? {'quantity_litres': 0.0, 'average_cost_per_litre': 0.0}
        : rows.first;
  }

  Future<void> addStock({
    required double litres,
    required double costPerLitre,
    required bool canWise,
    required String date,
    String? note,
  }) async {
    if (litres <= 0 || costPerLitre < 0) {
      throw ArgumentError('Enter a valid quantity and cost.');
    }
    final db = await _helper.database;
    await db.transaction((txn) async {
      final row = (await txn.query(
        'air_blower_oil_stock',
        where: 'id = 1',
        limit: 1,
      )).first;
      final oldQty = (row['quantity_litres'] as num).toDouble();
      final oldCost = (row['average_cost_per_litre'] as num).toDouble();
      final nextQty = oldQty + litres;
      final nextCost = nextQty == 0
          ? 0
          : ((oldQty * oldCost) + (litres * costPerLitre)) / nextQty;
      await txn.update('air_blower_oil_stock', {
        'quantity_litres': nextQty,
        'average_cost_per_litre': nextCost,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = 1');
      await txn.insert('air_blower_oil_movements', {
        'movement_type': 'purchase',
        'quantity_litres': litres,
        'unit_cost': costPerLitre,
        'movement_date': date,
        'note':
            '${canWise ? 'Can-wise' : 'Litre-wise'}${note == null || note.trim().isEmpty ? '' : ': ${note.trim()}'}',
      });
    });
  }

  static Future<void> replaceUsage({
    required DatabaseExecutor txn,
    required String serviceType,
    required int serviceId,
    required double litres,
    required double rate,
    required int vehicleId,
    required double meterReading,
    required String date,
  }) async {
    final previous = await txn.query(
      'air_blower_oil_movements',
      where: 'service_type = ? AND service_id = ? AND movement_type = ?',
      whereArgs: [serviceType, serviceId, 'usage'],
      limit: 1,
    );
    if (previous.isNotEmpty) {
      final old = previous.first;
      final oldQty = (old['quantity_litres'] as num).toDouble();
      final stock = (await txn.query(
        'air_blower_oil_stock',
        where: 'id = 1',
        limit: 1,
      )).first;
      await txn.update('air_blower_oil_stock', {
        'quantity_litres':
            (stock['quantity_litres'] as num).toDouble() + oldQty,
        'updated_at': DateTime.now().toIso8601String(),
      }, where: 'id = 1');
      await txn.delete(
        'air_blower_oil_movements',
        where: 'id = ?',
        whereArgs: [old['id']],
      );
    }
    if (litres <= 0) return;
    final stock = (await txn.query(
      'air_blower_oil_stock',
      where: 'id = 1',
      limit: 1,
    )).first;
    final available = (stock['quantity_litres'] as num).toDouble();
    if (available + 0.000001 < litres) {
      throw StateError(
        'Insufficient AdBlue Oil stock. Available: ${available.toStringAsFixed(2)} L. Required: ${litres.toStringAsFixed(2)} L.',
      );
    }
    await txn.update('air_blower_oil_stock', {
      'quantity_litres': available - litres,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = 1');
    await txn.insert('air_blower_oil_movements', {
      'movement_type': 'usage',
      'quantity_litres': litres,
      'unit_cost': rate,
      'service_type': serviceType,
      'service_id': serviceId,
      'vehicle_id': vehicleId,
      'meter_reading': meterReading,
      'movement_date': date,
    });
  }

  static Future<void> reverseUsage({
    required DatabaseExecutor txn,
    required String serviceType,
    required int serviceId,
  }) async {
    final rows = await txn.query(
      'air_blower_oil_movements',
      where: 'service_type = ? AND service_id = ? AND movement_type = ?',
      whereArgs: [serviceType, serviceId, 'usage'],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final row = rows.first;
    final stock = (await txn.query(
      'air_blower_oil_stock',
      where: 'id = 1',
      limit: 1,
    )).first;
    await txn.update('air_blower_oil_stock', {
      'quantity_litres':
          (stock['quantity_litres'] as num).toDouble() +
          (row['quantity_litres'] as num).toDouble(),
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = 1');
    await txn.delete(
      'air_blower_oil_movements',
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
}
