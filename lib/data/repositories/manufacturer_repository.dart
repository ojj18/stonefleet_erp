import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/manufacturer_model.dart';

class ManufacturerRepository {
  final DatabaseHelper _databaseHelper;

  ManufacturerRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ManufacturerModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.manufacturers,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return result.map(ManufacturerModel.fromMap).toList();
  }

  Future<ManufacturerModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.manufacturers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ManufacturerModel.fromMap(result.first);
  }

  Future<int> insert(ManufacturerModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.manufacturers,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(ManufacturerModel model) async {
    if (model.id == null) {
      throw ArgumentError('Manufacturer ID is required for update.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.manufacturers,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.manufacturers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
