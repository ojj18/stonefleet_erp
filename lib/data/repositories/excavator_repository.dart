import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/excavator_model.dart';

class ExcavatorRepository {
  final DatabaseHelper _databaseHelper;

  ExcavatorRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<ExcavatorModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavators,
      orderBy: 'registration_number ASC',
    );

    return result.map(ExcavatorModel.fromMap).toList();
  }

  Future<List<ExcavatorModel>> getActive() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavators,
      where: 'status = ?',
      whereArgs: [1],
      orderBy: 'registration_number ASC',
    );

    return result.map(ExcavatorModel.fromMap).toList();
  }

  Future<ExcavatorModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavators,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ExcavatorModel.fromMap(result.first);
  }

  Future<int> insert(ExcavatorModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.excavators,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(ExcavatorModel model) async {
    if (model.id == null) {
      throw ArgumentError('Excavator ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.excavators,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.excavators,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> registrationExists(
    String registrationNumber, {
    int? excludeId,
  }) async {
    final db = await _databaseHelper.database;

    final normalized = registrationNumber.trim().toUpperCase();

    String where = 'registration_number = ?';
    final List<Object?> whereArgs = [normalized];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      TableConstants.excavators,
      columns: ['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
