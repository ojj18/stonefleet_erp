import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/transport_vehicle_model.dart';

class TransportVehicleRepository {
  final DatabaseHelper _databaseHelper;

  TransportVehicleRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<TransportVehicleModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportVehicles,
      orderBy: 'registration_number ASC',
    );

    return result.map(TransportVehicleModel.fromMap).toList();
  }

  Future<List<TransportVehicleModel>> getActive() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportVehicles,
      where: 'status = ?',
      whereArgs: [1],
      orderBy: 'registration_number ASC',
    );

    return result.map(TransportVehicleModel.fromMap).toList();
  }

  Future<TransportVehicleModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportVehicles,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TransportVehicleModel.fromMap(result.first);
  }

  Future<int> insert(TransportVehicleModel model) async {
    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.insert(
      TableConstants.transportVehicles,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(TransportVehicleModel model) async {
    if (model.id == null) {
      throw ArgumentError('Transport vehicle ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = model.toMap()..remove('id');

    return db.update(
      TableConstants.transportVehicles,
      data,
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.transportVehicles,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
