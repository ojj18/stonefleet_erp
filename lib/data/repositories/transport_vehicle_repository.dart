import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/database_helper.dart';
import '../models/transport_vehicle_model.dart';

class TransportRepository {
  final DatabaseHelper _databaseHelper;

  TransportRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<TransportModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query('transport_vehicles', orderBy: 'id DESC');

    return result.map((map) => TransportModel.fromMap(map)).toList();
  }

  // ============================================================
  // GET ACTIVE
  // ============================================================

  Future<List<TransportModel>> getActive() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_vehicles',
      where: 'status = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return result.map((map) => TransportModel.fromMap(map)).toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TransportModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_vehicles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return TransportModel.fromMap(result.first);
  }

  // ============================================================
  // GET BY REGISTRATION NUMBER
  // ============================================================

  Future<TransportModel?> getByRegistrationNumber(
    String registrationNumber,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_vehicles',
      where: 'registration_number = ?',
      whereArgs: [registrationNumber.trim()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return TransportModel.fromMap(result.first);
  }

  // ============================================================
  // INSERT
  // ============================================================

  Future<int> insert(TransportModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap();

    // SQLite generates the ID.
    data.remove('id');

    return await db.insert(
      'transport_vehicles',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> update(TransportModel model) async {
    if (model.id == null) {
      throw ArgumentError('Transport ID is required for update');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap();

    // ID should not be updated.
    data.remove('id');

    return await db.update(
      'transport_vehicles',
      data,
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
      'transport_vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // COUNT
  // ============================================================
}
