import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/excavator_service_item_model.dart';
import '../models/excavator_service_model.dart';
import '../models/excavator_service_schedule_model.dart';

class ExcavatorServiceRepository {
  final DatabaseHelper _databaseHelper;

  ExcavatorServiceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // SERVICE
  // ============================================================

  Future<List<ExcavatorServiceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorService,
      orderBy: 'service_date DESC',
    );

    return result.map(ExcavatorServiceModel.fromMap).toList();
  }

  Future<List<ExcavatorServiceModel>> getByExcavator(int excavatorId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorService,
      where: 'excavator_id = ?',
      whereArgs: [excavatorId],
      orderBy: 'service_date DESC',
    );

    return result.map(ExcavatorServiceModel.fromMap).toList();
  }

  Future<ExcavatorServiceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorService,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return ExcavatorServiceModel.fromMap(result.first);
  }

  // ============================================================
  // SERVICE + ITEMS TRANSACTION
  // ============================================================

  Future<int> createServiceWithItems({
    required ExcavatorServiceModel service,
    required List<ExcavatorServiceItemModel> items,
  }) async {
    final db = await _databaseHelper.database;

    return db.transaction<int>((txn) async {
      final serviceData = service.toMap()..remove('id');

      final serviceId = await txn.insert(
        TableConstants.excavatorService,
        serviceData,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      for (final item in items) {
        final itemData = item.toMap()
          ..remove('id')
          ..['service_id'] = serviceId;

        await txn.insert(
          TableConstants.excavatorServiceItems,
          itemData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      return serviceId;
    });
  }

  Future<int> updateService(ExcavatorServiceModel service) async {
    if (service.id == null) {
      throw ArgumentError('Excavator service ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = service.toMap()..remove('id');

    return db.update(
      TableConstants.excavatorService,
      data,
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int serviceId) async {
    final db = await _databaseHelper.database;

    return db.transaction<int>((txn) async {
      await txn.delete(
        TableConstants.excavatorServiceItems,
        where: 'service_id = ?',
        whereArgs: [serviceId],
      );

      return txn.delete(
        TableConstants.excavatorService,
        where: 'id = ?',
        whereArgs: [serviceId],
      );
    });
  }

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  Future<List<ExcavatorServiceItemModel>> getItems(int serviceId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorServiceItems,
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'id ASC',
    );

    return result.map(ExcavatorServiceItemModel.fromMap).toList();
  }

  Future<int> addItem(ExcavatorServiceItemModel item) async {
    final db = await _databaseHelper.database;

    final data = item.toMap()..remove('id');

    return db.insert(
      TableConstants.excavatorServiceItems,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteItem(int itemId) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.excavatorServiceItems,
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ============================================================
  // SERVICE SCHEDULE
  // ============================================================

  Future<List<ExcavatorServiceScheduleModel>> getSchedulesByModel(
    int excavatorModelId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      TableConstants.excavatorServiceSchedules,
      where: 'excavator_model_id = ?',
      whereArgs: [excavatorModelId],
      orderBy: 'id ASC',
    );

    return result.map(ExcavatorServiceScheduleModel.fromMap).toList();
  }

  Future<int> insertSchedule(ExcavatorServiceScheduleModel schedule) async {
    final db = await _databaseHelper.database;

    final data = schedule.toMap()..remove('id');

    return db.insert(
      TableConstants.excavatorServiceSchedules,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateSchedule(ExcavatorServiceScheduleModel schedule) async {
    if (schedule.id == null) {
      throw ArgumentError('Excavator service schedule ID is required.');
    }

    final db = await _databaseHelper.database;

    final data = schedule.toMap()..remove('id');

    return db.update(
      TableConstants.excavatorServiceSchedules,
      data,
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      TableConstants.excavatorServiceSchedules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
