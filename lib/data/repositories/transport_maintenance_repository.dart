import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/transport_maintenance_model.dart';

class TransportMaintenanceRepository {
  final DatabaseHelper _databaseHelper;

  TransportMaintenanceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<TransportMaintenanceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportMaintenance,
      orderBy: 'created_at DESC',
    );

    return result.map(TransportMaintenanceModel.fromMap).toList();
  }

  Future<List<TransportMaintenanceModel>> getByVehicle(int vehicleId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportMaintenance,
      where: 'transport_vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'created_at DESC',
    );

    return result.map(TransportMaintenanceModel.fromMap).toList();
  }

  Future<TransportMaintenanceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportMaintenance,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TransportMaintenanceModel.fromMap(result.first);
  }

  Future<int> insert(TransportMaintenanceModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.transportMaintenance,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(TransportMaintenanceModel model) async {
    if (model.id == null) {
      throw ArgumentError('Transport maintenance ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.transportMaintenance,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.transportMaintenance,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${TableConstants.transportMaintenance}
      ''');

    return (result.first['count'] as int?) ?? 0;
  }
}
