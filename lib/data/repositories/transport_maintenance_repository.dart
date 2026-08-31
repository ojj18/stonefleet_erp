import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/database_helper.dart';
import '../models/transport_maintenance_model.dart';

class TransportMaintenanceRepository {
  final DatabaseHelper _databaseHelper;

  TransportMaintenanceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // INSERT
  // ============================================================

  Future<int> insert(TransportMaintenanceModel model) async {
    final db = await _databaseHelper.database;

    return await db.insert(
      'transport_maintenance',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<TransportMaintenanceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query('transport_maintenance', orderBy: 'id DESC');

    return result.map((map) => TransportMaintenanceModel.fromMap(map)).toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TransportMaintenanceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_maintenance',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return TransportMaintenanceModel.fromMap(result.first);
  }

  // ============================================================
  // GET BY VEHICLE
  // ============================================================

  Future<List<TransportMaintenanceModel>> getByVehicleId(
    int transportVehicleId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_maintenance',
      where: 'transport_vehicle_id = ?',
      whereArgs: [transportVehicleId],
      orderBy: 'id DESC',
    );

    return result.map((map) => TransportMaintenanceModel.fromMap(map)).toList();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> update(TransportMaintenanceModel model) async {
    if (model.id == null) {
      throw ArgumentError('Maintenance ID is required for update.');
    }

    final db = await _databaseHelper.database;

    return await db.update(
      'transport_maintenance',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'transport_maintenance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // TOTAL KM
  // ============================================================

  Future<double> getTotalKm() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_km), 0) AS total_km
      FROM transport_maintenance
      ''');

    return ((result.first['total_km'] as num?) ?? 0).toDouble();
  }

  // ============================================================
  // TOTAL DIESEL
  // ============================================================

  Future<double> getTotalDiesel() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(diesel_filled), 0) AS total_diesel
      FROM transport_maintenance
      ''');

    return ((result.first['total_diesel'] as num?) ?? 0).toDouble();
  }

  // ============================================================
  // TOTAL DIESEL EXPENSE
  // ============================================================

  Future<double> getTotalDieselExpense() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(diesel_expense), 0)
      AS total_expense
      FROM transport_maintenance
      ''');

    return ((result.first['total_expense'] as num?) ?? 0).toDouble();
  }
}
