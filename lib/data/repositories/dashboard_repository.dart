import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_helper.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final DatabaseHelper _databaseHelper;

  DashboardRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // MAIN DASHBOARD
  // ============================================================

  Future<DashboardModel> getDashboard() async {
    final db = await _databaseHelper.database;

    final today = _today();

    final totalExcavators = await _getTotalExcavators(db);

    final workingExcavators = await _getWorkingExcavators(db, today);

    final totalTransportVehicles = await _getTotalTransportVehicles(db);

    final workingTransportVehicles = await _getWorkingTransportVehicles(
      db,
      today,
    );

    final workingSummary = await _getWorkingSummary(db, today);

    final transportSummary = await _getTransportSummary(db, today);

    final excavatorOperations = await _getExcavatorOperations(db, today);

    final transportOperations = await _getTransportOperations(db, today);

    final serviceOverview = await _getServiceOverview(db);

    final recentServices = await _getRecentServices(db);

    return DashboardModel(
      totalExcavators: totalExcavators,
      workingExcavators: workingExcavators,

      totalTransportVehicles: totalTransportVehicles,

      workingTransportVehicles: workingTransportVehicles,

      totalWorkingHours: workingSummary['working_hours'] as double,

      totalTransportKm: transportSummary['total_km'] as double,

      totalDieselUsed:
          (workingSummary['diesel'] as double) +
          (transportSummary['diesel'] as double),

      totalDieselExpense:
          (workingSummary['diesel_expense'] as double) +
          (transportSummary['diesel_expense'] as double),

      excavatorOperations: excavatorOperations,

      transportOperations: transportOperations,

      serviceOverview: serviceOverview,

      recentServices: recentServices,
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _today() {
    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');

    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  // ============================================================
  // TOTAL EXCAVATORS
  // ============================================================

  Future<int> _getTotalExcavators(Database db) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM excavators
      WHERE status = 1
      ''');

    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // WORKING EXCAVATORS
  // ============================================================

  Future<int> _getWorkingExcavators(Database db, String today) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT excavator_id) AS count
      FROM excavator_maintenance
      WHERE DATE(created_at) = DATE(?)
      ''',
      [today],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // TOTAL TRANSPORT VEHICLES
  // ============================================================

  Future<int> _getTotalTransportVehicles(Database db) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) AS count
      FROM transport_vehicles
      WHERE status = 1
      ''');

    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // WORKING TRANSPORT VEHICLES
  // ============================================================

  Future<int> _getWorkingTransportVehicles(Database db, String today) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT transport_vehicle_id) AS count
      FROM transport_maintenance
      WHERE DATE(created_at) = DATE(?)
      ''',
      [today],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // ============================================================
  // EXCAVATOR WORKING SUMMARY
  // ============================================================

  Future<Map<String, double>> _getWorkingSummary(
    Database db,
    String today,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT

        COALESCE(
          SUM(total_working_hour),
          0
        ) AS working_hours,

        COALESCE(
          SUM(diesel_filled),
          0
        ) AS diesel,

        COALESCE(
          SUM(diesel_expense),
          0
        ) AS diesel_expense

      FROM excavator_maintenance

      WHERE DATE(created_at) = DATE(?)
      ''',
      [today],
    );

    final row = result.first;

    return {
      'working_hours': _toDouble(row['working_hours']),

      'diesel': _toDouble(row['diesel']),

      'diesel_expense': _toDouble(row['diesel_expense']),
    };
  }

  // ============================================================
  // TRANSPORT SUMMARY
  // ============================================================

  Future<Map<String, double>> _getTransportSummary(
    Database db,
    String today,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT

        COALESCE(
          SUM(total_km),
          0
        ) AS total_km,

        COALESCE(
          SUM(diesel_filled),
          0
        ) AS diesel,

        COALESCE(
          SUM(diesel_expense),
          0
        ) AS diesel_expense

      FROM transport_maintenance

      WHERE DATE(created_at) = DATE(?)
      ''',
      [today],
    );

    final row = result.first;

    return {
      'total_km': _toDouble(row['total_km']),

      'diesel': _toDouble(row['diesel']),

      'diesel_expense': _toDouble(row['diesel_expense']),
    };
  }

  // ============================================================
  // EXCAVATOR OPERATIONS
  // ============================================================

  Future<List<ExcavatorOperationModel>> _getExcavatorOperations(
    Database db,
    String today,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT
        em.id,
        em.excavator_id,
        em.operator_name,
        em.shift,

        em.starting_hour,
        em.closing_hour,
        em.total_working_hour,

        em.units,
        em.diesel_filled,

        e.registration_number

      FROM excavator_maintenance em

      LEFT JOIN excavators e
        ON e.id = em.excavator_id

      WHERE DATE(em.created_at) = DATE(?)

      ORDER BY em.id DESC
      ''',
      [today],
    );

    return result.map((row) {
      return ExcavatorOperationModel(
        registrationNumber:
            row['registration_number']?.toString() ??
            'EX-${row['excavator_id']}',

        operatorName: row['operator_name']?.toString() ?? '-',

        shift: row['shift']?.toString() ?? '-',

        openingHours: _toDouble(row['starting_hour']),

        closingHours: _toDouble(row['closing_hour']),

        totalHours: _toDouble(row['total_working_hour']),

        // IMPORTANT
        loads: _toInt(row['number_of_loads']),

        tonnage: _toDouble(row['units']),

        dieselFilled: _toDouble(row['diesel_filled']),
      );
    }).toList();
  }

  // ============================================================
  // TRANSPORT OPERATIONS
  // ============================================================

  Future<List<TransportOperationModel>> _getTransportOperations(
    Database db,
    String today,
  ) async {
    final result = await db.rawQuery(
      '''
      SELECT
        tm.id,
        tm.transport_vehicle_id,
        tm.driver_name,

        tm.starting_km,
        tm.closing_km,
        tm.total_km,

        tm.number_of_loads,

        tm.loading_site,
        tm.unloading_site,

        tm.diesel_filled,

        tv.registration_number

      FROM transport_maintenance tm

      LEFT JOIN transport_vehicles tv
        ON tv.id = tm.transport_vehicle_id

      WHERE DATE(tm.created_at) = DATE(?)

      ORDER BY tm.id DESC
      ''',
      [today],
    );

    return result.map((row) {
      return TransportOperationModel(
        registrationNumber:
            row['registration_number']?.toString() ??
            'TR-${row['transport_vehicle_id']}',

        driverName: row['driver_name']?.toString() ?? '-',

        startingKm: _toDouble(row['starting_km']),

        closingKm: _toDouble(row['closing_km']),

        totalKm: _toDouble(row['total_km']),

        numberOfLoads: (row['number_of_loads'] as num?)?.toInt() ?? 0,

        loadingSite: row['loading_site']?.toString() ?? '-',

        unloadingSite: row['unloading_site']?.toString() ?? '-',

        dieselFilled: _toDouble(row['diesel_filled']),
      );
    }).toList();
  }

  // ============================================================
  // SERVICE OVERVIEW
  // ============================================================

  Future<List<ServiceOverviewModel>> _getServiceOverview(Database db) async {
    final result = await db.rawQuery('''
      SELECT
        es.id,
        es.excavator_id,
        es.service_date,
        es.current_hour_meter,

        e.registration_number

      FROM excavator_service es

      LEFT JOIN excavators e
        ON e.id = es.excavator_id

      ORDER BY es.service_date DESC

      LIMIT 10
      ''');

    return result.map((row) {
      return ServiceOverviewModel(
        registrationNumber:
            row['registration_number']?.toString() ??
            'EX-${row['excavator_id']}',

        serviceName: 'Excavator Service',

        description:
            'Current hour meter: '
            '${_toDouble(row['current_hour_meter']).toStringAsFixed(1)}',

        status: ServiceStatus.upcoming,
      );
    }).toList();
  }

  // ============================================================
  // RECENT SERVICES
  // ============================================================

  Future<List<RecentServiceModel>> _getRecentServices(Database db) async {
    final result = await db.rawQuery('''
      SELECT
        es.id,
        es.excavator_id,

        es.service_date,
        es.current_hour_meter,

        e.registration_number,

        COALESCE(
          (
            SELECT SUM(esi.cost * esi.quantity)
            FROM excavator_service_items esi
            WHERE esi.service_id = es.id
          ),
          0
        ) AS total_cost

      FROM excavator_service es

      LEFT JOIN excavators e
        ON e.id = es.excavator_id

      ORDER BY es.service_date DESC

      LIMIT 10
      ''');

    return result.map((row) {
      return RecentServiceModel(
        registrationNumber:
            row['registration_number']?.toString() ??
            'EX-${row['excavator_id']}',

        serviceDate: row['service_date']?.toString() ?? '-',

        serviceDescription: 'Excavator Service',

        currentKm: 0,

        currentHours: _toDouble(row['current_hour_meter']),

        totalCost: _toDouble(row['total_cost']),
      );
    }).toList();
  }

  // ============================================================
  // DOUBLE HELPER
  // ============================================================

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}
