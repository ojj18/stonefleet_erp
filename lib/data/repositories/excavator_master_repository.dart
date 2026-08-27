import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/excavator_master_model.dart';

class ExcavatorMasterRepository {
  final DatabaseHelper _databaseHelper;

  ExcavatorMasterRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ExcavatorMasterModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorModels,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'model_name ASC',
    );

    return result.map(ExcavatorMasterModel.fromMap).toList();
  }

  Future<List<ExcavatorMasterModel>> getByManufacturer(
    int manufacturerId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorModels,
      where: 'manufacturer_id = ? AND is_active = ?',
      whereArgs: [manufacturerId, 1],
      orderBy: 'model_name ASC',
    );

    return result.map(ExcavatorMasterModel.fromMap).toList();
  }

  Future<ExcavatorMasterModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorModels,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ExcavatorMasterModel.fromMap(result.first);
  }

  Future<int> insert(ExcavatorMasterModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.excavatorModels,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(ExcavatorMasterModel model) async {
    if (model.id == null) {
      throw ArgumentError('Excavator model ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.excavatorModels,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.excavatorModels,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
