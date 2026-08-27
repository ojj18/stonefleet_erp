import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/spare_model.dart';

class SpareRepository {
  final DatabaseHelper _databaseHelper;

  SpareRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<SpareModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.spares,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return result.map(SpareModel.fromMap).toList();
  }

  Future<List<SpareModel>> getByCategory(String category) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.spares,
      where: 'category = ? AND is_active = ?',
      whereArgs: [category, 1],
      orderBy: 'name ASC',
    );

    return result.map(SpareModel.fromMap).toList();
  }

  Future<SpareModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.spares,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return SpareModel.fromMap(result.first);
  }

  Future<int> insert(SpareModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.spares,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(SpareModel model) async {
    if (model.id == null) {
      throw ArgumentError('Spare ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.spares,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(TableConstants.spares, where: 'id = ?', whereArgs: [id]);
  }
}
