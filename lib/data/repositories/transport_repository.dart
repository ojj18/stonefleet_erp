import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/transport_master_model.dart';

class TransportRepository {
  final DatabaseHelper _databaseHelper;

  TransportRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<TransportModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportModels,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'model_name ASC',
    );

    return result.map(TransportModel.fromMap).toList();
  }

  Future<List<TransportModel>> getByManufacturer(int manufacturerId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportModels,
      where: 'manufacturer_id = ? AND is_active = ?',
      whereArgs: [manufacturerId, 1],
      orderBy: 'model_name ASC',
    );

    return result.map(TransportModel.fromMap).toList();
  }

  Future<TransportModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportModels,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TransportModel.fromMap(result.first);
  }

  Future<int> insert(TransportModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.transportModels,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(TransportModel model) async {
    if (model.id == null) {
      throw ArgumentError('Transport model ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.transportModels,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.transportModels,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
