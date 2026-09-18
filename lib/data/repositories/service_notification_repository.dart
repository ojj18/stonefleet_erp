import '../../core/constants/table_constants.dart';
import '../../core/database/database_helper.dart';

class ServiceNotificationRepository {
  final DatabaseHelper _databaseHelper;

  ServiceNotificationRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getExcavatorNotificationData() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        e.id AS equipment_id,
        e.registration_number,
        e.model_name,

        s.id AS spare_id,
        s.name AS spare_name,

        sch.interval_hours,
        sch.warning_hours,

        (
          SELECT es2.current_hour_meter
          FROM ${TableConstants.excavatorService} es2
          INNER JOIN ${TableConstants.excavatorServiceItems} esi2
            ON esi2.service_id = es2.id
          WHERE es2.excavator_id = e.id
            AND esi2.spare_id = sch.spare_id
          ORDER BY es2.service_date DESC, es2.id DESC
          LIMIT 1
        ) AS last_service_meter,

        (
          SELECT es2.service_date
          FROM ${TableConstants.excavatorService} es2
          INNER JOIN ${TableConstants.excavatorServiceItems} esi2
            ON esi2.service_id = es2.id
          WHERE es2.excavator_id = e.id
            AND esi2.spare_id = sch.spare_id
          ORDER BY es2.service_date DESC, es2.id DESC
          LIMIT 1
        ) AS last_service_date,

        (
          SELECT es3.current_hour_meter
          FROM ${TableConstants.excavatorService} es3
          WHERE es3.excavator_id = e.id
          ORDER BY es3.service_date DESC, es3.id DESC
          LIMIT 1
        ) AS current_meter

      FROM ${TableConstants.excavators} e

      INNER JOIN ${TableConstants.excavatorModels} em
        ON UPPER(TRIM(em.model_name)) =
           UPPER(TRIM(e.model_name))

      INNER JOIN ${TableConstants.excavatorServiceSchedules} sch
        ON sch.excavator_model_id = em.id

      INNER JOIN ${TableConstants.spares} s
        ON s.id = sch.spare_id

      WHERE e.status = 1
        AND s.is_active = 1

      ORDER BY e.registration_number ASC, s.name ASC
    ''');

    return result;
  }

  Future<List<Map<String, dynamic>>> getTransportNotificationData() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT
        t.id AS equipment_id,
        t.registration_number,
        t.model_name,

        s.id AS spare_id,
        s.name AS spare_name,

        sch.interval_km,
        sch.warning_km,

        (
          SELECT ts2.current_km
          FROM ${TableConstants.transportService} ts2
          INNER JOIN ${TableConstants.transportServiceItems} tsi2
            ON tsi2.service_id = ts2.id
          WHERE ts2.transport_vehicle_id = t.id
            AND tsi2.spare_id = sch.spare_id
          ORDER BY ts2.service_date DESC, ts2.id DESC
          LIMIT 1
        ) AS last_service_meter,

        (
          SELECT ts2.service_date
          FROM ${TableConstants.transportService} ts2
          INNER JOIN ${TableConstants.transportServiceItems} tsi2
            ON tsi2.service_id = ts2.id
          WHERE ts2.transport_vehicle_id = t.id
            AND tsi2.spare_id = sch.spare_id
          ORDER BY ts2.service_date DESC, ts2.id DESC
          LIMIT 1
        ) AS last_service_date,

        (
          SELECT ts3.current_km
          FROM ${TableConstants.transportService} ts3
          WHERE ts3.transport_vehicle_id = t.id
          ORDER BY ts3.service_date DESC, ts3.id DESC
          LIMIT 1
        ) AS current_meter

      FROM ${TableConstants.transportVehicles} t

      INNER JOIN ${TableConstants.transportModels} tm
        ON UPPER(TRIM(tm.model_name)) =
           UPPER(TRIM(t.model_name))

      INNER JOIN ${TableConstants.transportServiceSchedules} sch
        ON sch.transport_model_id = tm.id

      INNER JOIN ${TableConstants.spares} s
        ON s.id = sch.spare_id

      WHERE t.status = 1
        AND s.is_active = 1

      ORDER BY t.registration_number ASC, s.name ASC
    ''');

    return result;
  }
}
