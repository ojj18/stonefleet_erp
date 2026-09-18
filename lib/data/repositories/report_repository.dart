import '../../core/database/database_helper.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // EXCAVATOR MAINTENANCE REPORT
  // ============================================================

  Future<List<Map<String, dynamic>>> getExcavatorMaintenanceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? excavatorId,
    String? search,
  }) async {
    final db = await _databaseHelper.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('em.created_at >= ?');
      args.add(_startOfDay(fromDate));
    }

    if (toDate != null) {
      conditions.add('em.created_at <= ?');
      args.add(_endOfDay(toDate));
    }

    if (excavatorId != null) {
      conditions.add('em.excavator_id = ?');
      args.add(excavatorId);
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('''
        (
          LOWER(COALESCE(e.registration_number, '')) LIKE ?
          OR LOWER(COALESCE(e.manufacturer_name, '')) LIKE ?
          OR LOWER(COALESCE(e.model_name, '')) LIKE ?
          OR LOWER(COALESCE(em.operator_name, '')) LIKE ?
          OR LOWER(COALESCE(em.remarks, '')) LIKE ?
        )
      ''');

      final value = '%${search.trim().toLowerCase()}%';

      args.addAll([value, value, value, value, value]);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        em.id AS maintenance_id,

        em.excavator_id,
        e.registration_number,
        e.manufacturer_name,
        e.model_name,
        e.manufacturing_year,

        em.operator_name,
        em.shift,

        em.starting_hour,
        em.closing_hour,
        em.total_working_hour,
        em.bucket_working_hour,
        em.breaker_working_hour,
        em.total_running_hour,

        em.number_of_loads,
        em.units,

        em.diesel_filled,
        em.diesel_rate,
        em.diesel_expense,
        em.diesel_expense_per_hour,

        em.teeth_set_changed,
        em.remarks,

        em.created_at,
        em.updated_at

      FROM excavator_maintenance em

      INNER JOIN excavators e
        ON e.id = em.excavator_id

      $whereClause

      ORDER BY em.created_at DESC, em.id DESC
      ''', args);
  }

  // ============================================================
  // TRANSPORT MAINTENANCE REPORT
  // ============================================================

  Future<List<Map<String, dynamic>>> getTransportMaintenanceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? transportVehicleId,
    String? search,
  }) async {
    final db = await _databaseHelper.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('tm.created_at >= ?');
      args.add(_startOfDay(fromDate));
    }

    if (toDate != null) {
      conditions.add('tm.created_at <= ?');
      args.add(_endOfDay(toDate));
    }

    if (transportVehicleId != null) {
      conditions.add('tm.transport_vehicle_id = ?');
      args.add(transportVehicleId);
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('''
        (
          LOWER(COALESCE(t.registration_number, '')) LIKE ?
          OR LOWER(COALESCE(t.manufacturer_name, '')) LIKE ?
          OR LOWER(COALESCE(t.model_name, '')) LIKE ?
          OR LOWER(COALESCE(tm.driver_name, '')) LIKE ?
          OR LOWER(COALESCE(tm.loading_site, '')) LIKE ?
          OR LOWER(COALESCE(tm.unloading_site, '')) LIKE ?
          OR LOWER(COALESCE(tm.remarks, '')) LIKE ?
        )
      ''');

      final value = '%${search.trim().toLowerCase()}%';

      args.addAll([value, value, value, value, value, value, value]);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        tm.id AS maintenance_id,

        tm.transport_vehicle_id,
        t.registration_number,
        t.manufacturer_name,
        t.model_name,
        t.manufacturing_year,

        tm.driver_name,

        tm.starting_km,
        tm.closing_km,
        tm.total_km,

        tm.number_of_loads,

        tm.loading_site,
        tm.unloading_site,

        tm.diesel_filled,
        tm.diesel_rate,
        tm.diesel_expense,

        tm.remarks,

        tm.created_at,
        tm.updated_at

      FROM transport_maintenance tm

      INNER JOIN transport_vehicles t
        ON t.id = tm.transport_vehicle_id

      $whereClause

      ORDER BY tm.created_at DESC, tm.id DESC
      ''', args);
  }

  // ============================================================
  // EXCAVATOR SERVICE REPORT
  // ============================================================

  Future<List<Map<String, dynamic>>> getExcavatorServiceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? excavatorId,
    String? search,
  }) async {
    final db = await _databaseHelper.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('es.service_date >= ?');
      args.add(_startOfDay(fromDate));
    }

    if (toDate != null) {
      conditions.add('es.service_date <= ?');
      args.add(_endOfDay(toDate));
    }

    if (excavatorId != null) {
      conditions.add('es.excavator_id = ?');
      args.add(excavatorId);
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('''
        (
          LOWER(COALESCE(e.registration_number, '')) LIKE ?
          OR LOWER(COALESCE(e.manufacturer_name, '')) LIKE ?
          OR LOWER(COALESCE(e.model_name, '')) LIKE ?
          OR LOWER(COALESCE(s.name, '')) LIKE ?
          OR LOWER(COALESCE(es.remarks, '')) LIKE ?
          OR LOWER(COALESCE(esi.remark, '')) LIKE ?
        )
      ''');

      final value = '%${search.trim().toLowerCase()}%';

      args.addAll([value, value, value, value, value, value]);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        es.id AS service_id,

        es.excavator_id,
        e.registration_number,
        e.manufacturer_name,
        e.model_name,
        e.manufacturing_year,

        es.service_date,
        es.current_hour_meter,
        es.remarks AS service_remarks,

        esi.id AS service_item_id,
        esi.spare_id,
        s.name AS spare_name,
        s.code AS spare_code,

        esi.quantity,
        esi.cost AS spare_cost,
        esi.remark AS spare_remark,

        es.created_at,
        es.updated_at

      FROM excavator_service es

      INNER JOIN excavators e
        ON e.id = es.excavator_id

      LEFT JOIN excavator_service_items esi
        ON esi.service_id = es.id

      LEFT JOIN spares s
        ON s.id = esi.spare_id

      $whereClause

      ORDER BY es.service_date DESC, es.id DESC, esi.id ASC
      ''', args);
  }

  // ============================================================
  // TRANSPORT SERVICE REPORT
  // ============================================================

  Future<List<Map<String, dynamic>>> getTransportServiceReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? transportVehicleId,
    String? search,
  }) async {
    final db = await _databaseHelper.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (fromDate != null) {
      conditions.add('ts.service_date >= ?');
      args.add(_startOfDay(fromDate));
    }

    if (toDate != null) {
      conditions.add('ts.service_date <= ?');
      args.add(_endOfDay(toDate));
    }

    if (transportVehicleId != null) {
      conditions.add('ts.transport_vehicle_id = ?');
      args.add(transportVehicleId);
    }

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('''
        (
          LOWER(COALESCE(t.registration_number, '')) LIKE ?
          OR LOWER(COALESCE(t.manufacturer_name, '')) LIKE ?
          OR LOWER(COALESCE(t.model_name, '')) LIKE ?
          OR LOWER(COALESCE(s.name, '')) LIKE ?
          OR LOWER(COALESCE(ts.remarks, '')) LIKE ?
          OR LOWER(COALESCE(tsi.remark, '')) LIKE ?
        )
      ''');

      final value = '%${search.trim().toLowerCase()}%';

      args.addAll([value, value, value, value, value, value]);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    return db.rawQuery('''
      SELECT
        ts.id AS service_id,

        ts.transport_vehicle_id,
        t.registration_number,
        t.manufacturer_name,
        t.model_name,
        t.manufacturing_year,

        ts.service_date,
        ts.current_km,
        ts.remarks AS service_remarks,

        tsi.id AS service_item_id,
        tsi.spare_id,
        s.name AS spare_name,
        s.code AS spare_code,

        tsi.quantity,
        tsi.cost AS spare_cost,
        tsi.remark AS spare_remark,

        ts.created_at,
        ts.updated_at

      FROM transport_service ts

      INNER JOIN transport_vehicles t
        ON t.id = ts.transport_vehicle_id

      LEFT JOIN transport_service_items tsi
        ON tsi.service_id = ts.id

      LEFT JOIN spares s
        ON s.id = tsi.spare_id

      $whereClause

      ORDER BY ts.service_date DESC, ts.id DESC, tsi.id ASC
      ''', args);
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  String _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  String _endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();
  }
}
