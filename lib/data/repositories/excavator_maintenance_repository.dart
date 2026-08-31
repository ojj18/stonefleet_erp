import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/excavator_maintenance_list_model.dart';
import '../models/excavator_maintenance_model.dart';

class ExcavatorMaintenanceRepository {
  final DatabaseHelper _databaseHelper;

  ExcavatorMaintenanceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ExcavatorMaintenanceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorMaintenance,
      orderBy: 'created_at DESC',
    );

    return result.map(ExcavatorMaintenanceModel.fromMap).toList();
  }

  Future<List<ExcavatorMaintenanceModel>> getByExcavator(
    int excavatorId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorMaintenance,
      where: 'excavator_id = ?',
      whereArgs: [excavatorId],
      orderBy: 'created_at DESC',
    );

    return result.map(ExcavatorMaintenanceModel.fromMap).toList();
  }

  Future<ExcavatorMaintenanceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorMaintenance,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ExcavatorMaintenanceModel.fromMap(result.first);
  }

  Future<int> insert(ExcavatorMaintenanceModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.excavatorMaintenance,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(ExcavatorMaintenanceModel model) async {
    if (model.id == null) {
      throw ArgumentError('Excavator maintenance ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.excavatorMaintenance,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.excavatorMaintenance,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM ${TableConstants.excavatorMaintenance}
      ''');

    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<ExcavatorMaintenanceListModel>> getAllWithExcavator() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
    SELECT
      em.*,
      e.registration_number AS registration_number
    FROM excavator_maintenance em
    INNER JOIN excavators e
      ON e.id = em.excavator_id
    ORDER BY em.created_at DESC
  ''');

    return result.map(ExcavatorMaintenanceListModel.fromMap).toList();
  }
}
