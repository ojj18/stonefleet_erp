import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/transport_service_item_model.dart';
import '../models/transport_service_model.dart';
import '../models/transport_service_schedule_model.dart';

class TransportServiceRepository {
  final DatabaseHelper _databaseHelper;

  TransportServiceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // SERVICE
  // ============================================================

  Future<List<TransportServiceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportService,
      orderBy: 'service_date DESC',
    );

    return result.map(TransportServiceModel.fromMap).toList();
  }

  Future<List<TransportServiceModel>> getByVehicle(int vehicleId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportService,
      where: 'transport_vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'service_date DESC',
    );

    return result.map(TransportServiceModel.fromMap).toList();
  }

  Future<TransportServiceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportService,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return TransportServiceModel.fromMap(result.first);
  }

  // ============================================================
  // SERVICE + ITEMS TRANSACTION
  // ============================================================

  Future<int> createServiceWithItems({
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
  }) async {
    final db = await _databaseHelper.database;

    return db.transaction<int>((txn) async {
      final serviceData = service.toMap()..remove('id');

      final serviceId = await txn.insert(
        TableConstants.transportService,
        serviceData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in items) {
        final itemData = item.toMap()
          ..remove('id')
          ..['service_id'] = serviceId;

        await txn.insert(
          TableConstants.transportServiceItems,
          itemData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      return serviceId;
    });
  }

  Future<int> updateService(TransportServiceModel service) async {
    if (service.id == null) {
      throw ArgumentError('Transport service ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = service.toMap()..remove('id');

    return db.update(
      TableConstants.transportService,
      data,
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int serviceId) async {
    final db = await _databaseHelper.database;

    return db.transaction<int>((txn) async {
      await txn.delete(
        TableConstants.transportServiceItems,
        where: 'service_id = ?',
        whereArgs: [serviceId],
      );

      return txn.delete(
        TableConstants.transportService,
        where: 'id = ?',
        whereArgs: [serviceId],
      );
    });
  }

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  Future<List<TransportServiceItemModel>> getItems(int serviceId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportServiceItems,
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'id ASC',
    );

    return result.map(TransportServiceItemModel.fromMap).toList();
  }

  Future<int> addItem(TransportServiceItemModel item) async {
    final db = await _databaseHelper.database;

    final data = item.toMap()..remove('id');

    return db.insert(
      TableConstants.transportServiceItems,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteItem(int itemId) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.transportServiceItems,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ============================================================
  // SERVICE SCHEDULE
  // ============================================================

  Future<List<TransportServiceScheduleModel>> getSchedulesByModel(
    int transportModelId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.transportServiceSchedules,
      where: 'transport_model_id = ?',
      whereArgs: [transportModelId],
      orderBy: 'id ASC',
    );

    return result.map(TransportServiceScheduleModel.fromMap).toList();
  }

  Future<int> insertSchedule(TransportServiceScheduleModel schedule) async {
    final db = await _databaseHelper.database;

    final data = schedule.toMap()..remove('id');

    return db.insert(
      TableConstants.transportServiceSchedules,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateSchedule(TransportServiceScheduleModel schedule) async {
    if (schedule.id == null) {
      throw ArgumentError('Transport service schedule ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = schedule.toMap()..remove('id');

    return db.update(
      TableConstants.transportServiceSchedules,
      data,
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.transportServiceSchedules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
