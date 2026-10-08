import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/database_helper.dart';
import '../models/quarry_boulder_trip_model.dart';

class QuarryBoulderSummary {
  final int records;
  final int trips;
  final double load;
  final int drivers;

  const QuarryBoulderSummary({
    this.records = 0,
    this.trips = 0,
    this.load = 0,
    this.drivers = 0,
  });
}

class QuarryBoulderRepository {
  final DatabaseHelper _dbHelper;
  QuarryBoulderRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<QuarryBoulderTrip>> getTrips({
    DateTime? fromDate,
    DateTime? toDate,
    String? registrationNumber,
    String? driverName,
    String? producerName,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) {
      where.add('trip_date >= ?');
      args.add(_dateOnly(fromDate));
    }
    if (toDate != null) {
      where.add('trip_date <= ?');
      args.add(_dateOnly(toDate));
    }
    if (registrationNumber != null && registrationNumber.trim().isNotEmpty) {
      where.add('LOWER(registration_number) LIKE ?');
      args.add('%${registrationNumber.trim().toLowerCase()}%');
    }
    if (driverName != null && driverName.trim().isNotEmpty) {
      where.add('LOWER(driver_name) LIKE ?');
      args.add('%${driverName.trim().toLowerCase()}%');
    }
    if (producerName != null && producerName.trim().isNotEmpty) {
      where.add('LOWER(producer_name) LIKE ?');
      args.add('%${producerName.trim().toLowerCase()}%');
    }
    final rows = await db.query(
      'quarry_boulder_trips',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'trip_date DESC, id DESC',
    );
    return rows.map(QuarryBoulderTrip.fromMap).toList();
  }

  Future<QuarryBoulderTrip?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('quarry_boulder_trips', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : QuarryBoulderTrip.fromMap(rows.first);
  }

  Future<int> insert(QuarryBoulderTrip trip) async {
    final db = await _dbHelper.database;
    final data = trip.toMap()..remove('id');
    return db.insert('quarry_boulder_trips', data, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> update(QuarryBoulderTrip trip) async {
    if (trip.id == null) throw ArgumentError('Trip ID is required for update');
    final db = await _dbHelper.database;
    final data = trip.toMap()..remove('id');
    return db.update('quarry_boulder_trips', data, where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('quarry_boulder_trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<QuarryBoulderSummary> getSummary({DateTime? fromDate, DateTime? toDate, String? driverName}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) { where.add('trip_date >= ?'); args.add(_dateOnly(fromDate)); }
    if (toDate != null) { where.add('trip_date <= ?'); args.add(_dateOnly(toDate)); }
    if (driverName != null && driverName.trim().isNotEmpty) { where.add('LOWER(driver_name) = ?'); args.add(driverName.trim().toLowerCase()); }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    final row = (await db.rawQuery('''
      SELECT COUNT(*) records,
             COALESCE(SUM(trips),0) trips,
             COALESCE(SUM(total_load),0) load,
             COUNT(DISTINCT driver_name) drivers
      FROM quarry_boulder_trips$clause
    ''', args)).first;
    return QuarryBoulderSummary(
      records: (row['records'] as num?)?.toInt() ?? 0,
      trips: (row['trips'] as num?)?.toInt() ?? 0,
      load: (row['load'] as num?)?.toDouble() ?? 0,
      drivers: (row['drivers'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> getDriverSummary({DateTime? fromDate, DateTime? toDate}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) { where.add('trip_date >= ?'); args.add(_dateOnly(fromDate)); }
    if (toDate != null) { where.add('trip_date <= ?'); args.add(_dateOnly(toDate)); }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    return db.rawQuery('''
      SELECT driver_name, COUNT(*) records, SUM(trips) trips, SUM(total_load) total_load
      FROM quarry_boulder_trips$clause
      GROUP BY driver_name
      ORDER BY driver_name COLLATE NOCASE
    ''', args);
  }

  Future<List<Map<String, dynamic>>> getLorrySummary({DateTime? fromDate, DateTime? toDate}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) { where.add('trip_date >= ?'); args.add(_dateOnly(fromDate)); }
    if (toDate != null) { where.add('trip_date <= ?'); args.add(_dateOnly(toDate)); }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    return db.rawQuery('''
      SELECT registration_number, COUNT(*) records, SUM(trips) trips, SUM(total_load) total_load
      FROM quarry_boulder_trips$clause
      GROUP BY registration_number
      ORDER BY registration_number COLLATE NOCASE
    ''', args);
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
