import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/database/database_helper.dart';
import '../models/transport_service_model.dart';
import '../models/transport_service_item_model.dart';

class TransportServiceRepository {
  final DatabaseHelper _databaseHelper;

  TransportServiceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // GET ALL SERVICES
  // ============================================================

  Future<List<TransportServiceModel>> getAll() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_service',
      orderBy: 'service_date DESC, id DESC',
    );

    return result.map((map) => TransportServiceModel.fromMap(map)).toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TransportServiceModel?> getById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_service',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return TransportServiceModel.fromMap(result.first);
  }

  // ============================================================
  // GET SERVICE ITEMS
  // ============================================================

  Future<List<TransportServiceItemModel>> getItems(int serviceId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_service_items',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'id ASC',
    );

    return result.map((map) => TransportServiceItemModel.fromMap(map)).toList();
  }

  // ============================================================
  // GET SERVICE WITH ITEMS
  // ============================================================

  Future<
    ({TransportServiceModel service, List<TransportServiceItemModel> items})?
  >
  getByIdWithItems(int id) async {
    final service = await getById(id);

    if (service == null) {
      return null;
    }

    final items = await getItems(id);

    return (service: service, items: items);
  }

  // ============================================================
  // INSERT SERVICE
  // ============================================================

  Future<int> insert(TransportServiceModel service) async {
    final db = await _databaseHelper.database;

    return await db.insert(
      'transport_service',
      service.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // INSERT SERVICE WITH ITEMS
  // ============================================================

  Future<int> insertWithItems({
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
  }) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // --------------------------------------------------------
      // INSERT SERVICE
      // --------------------------------------------------------

      final serviceId = await txn.insert(
        'transport_service',
        service.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // --------------------------------------------------------
      // INSERT ITEMS
      // --------------------------------------------------------

      for (final item in items) {
        await txn.insert(
          'transport_service_items',
          item.copyWith(serviceId: serviceId).toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      return serviceId;
    });
  }

  // ============================================================
  // UPDATE SERVICE
  // ============================================================

  Future<int> update(TransportServiceModel service) async {
    if (service.id == null) {
      throw ArgumentError('Service ID is required for update.');
    }

    final db = await _databaseHelper.database;

    final data = service.toMap()..remove('id');

    return await db.update(
      'transport_service',
      data,
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  // ============================================================
  // UPDATE SERVICE WITH ITEMS
  // ============================================================

  Future<void> updateWithItems({
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
  }) async {
    if (service.id == null) {
      throw ArgumentError('Service ID is required for update.');
    }

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // --------------------------------------------------------
      // UPDATE SERVICE
      // --------------------------------------------------------

      final serviceData = service.toMap()..remove('id');

      await txn.update(
        'transport_service',
        serviceData,
        where: 'id = ?',
        whereArgs: [service.id],
      );

      // --------------------------------------------------------
      // DELETE OLD ITEMS
      // --------------------------------------------------------

      await txn.delete(
        'transport_service_items',
        where: 'service_id = ?',
        whereArgs: [service.id],
      );

      // --------------------------------------------------------
      // INSERT UPDATED ITEMS
      // --------------------------------------------------------

      for (final item in items) {
        await txn.insert(
          'transport_service_items',
          item.copyWith(serviceId: service.id!).toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<int> delete(int id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'transport_service',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // DELETE SERVICE ITEM
  // ============================================================

  Future<int> deleteItem(int itemId) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'transport_service_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ============================================================
  // GET VEHICLE SERVICE HISTORY
  // ============================================================

  Future<List<TransportServiceModel>> getByVehicleId(
    int transportVehicleId,
  ) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'transport_service',
      where: 'transport_vehicle_id = ?',
      whereArgs: [transportVehicleId],
      orderBy: 'service_date DESC, id DESC',
    );

    return result.map((map) => TransportServiceModel.fromMap(map)).toList();
  }
}
