import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/database_helper.dart';
import '../models/retreading_model.dart';

class RetreadingRepository {
  final DatabaseHelper _dbHelper;
  RetreadingRepository({DatabaseHelper? databaseHelper})
      : _dbHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<RetreadingRecord>> getRecords({
    DateTime? fromDate,
    DateTime? toDate,
    String? registrationNumber,
    String? status,
    String? tyreSerialNumber,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) {
      where.add('sent_date >= ?');
      args.add(_dateOnly(fromDate));
    }
    if (toDate != null) {
      where.add('sent_date <= ?');
      args.add(_dateOnly(toDate));
    }
    if (registrationNumber != null && registrationNumber.trim().isNotEmpty) {
      where.add('LOWER(registration_number) LIKE ?');
      args.add('%${registrationNumber.trim().toLowerCase()}%');
    }
    if (status != null && status.trim().isNotEmpty) {
      where.add('status = ?');
      args.add(status.trim());
    }
    if (tyreSerialNumber != null && tyreSerialNumber.trim().isNotEmpty) {
      where.add('LOWER(tyre_serial_number) LIKE ?');
      args.add('%${tyreSerialNumber.trim().toLowerCase()}%');
    }
    final rows = await db.query(
      'tyre_retreading_records',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'sent_date DESC, id DESC',
    );
    return rows.map(RetreadingRecord.fromMap).toList();
  }

  Future<List<RetreadingRecord>> getOpenRecords({String? serial}) async {
    return getRecords(status: 'AT_RETREADING', tyreSerialNumber: serial);
  }

  Future<RetreadingRecord?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tyre_retreading_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : RetreadingRecord.fromMap(rows.first);
  }

  Future<RetreadingRecord?> getOpenBySerial(String serial) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'tyre_retreading_records',
      where: 'LOWER(tyre_serial_number) = ? AND status = ?',
      whereArgs: [serial.trim().toLowerCase(), 'AT_RETREADING'],
      orderBy: 'sent_date DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : RetreadingRecord.fromMap(rows.first);
  }

  Future<int> insert(RetreadingRecord record) async {
    final db = await _dbHelper.database;
    final data = record.toMap()..remove('id');
    return db.insert('tyre_retreading_records', data, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<int> update(RetreadingRecord record) async {
    if (record.id == null) throw ArgumentError('Record ID is required.');
    final db = await _dbHelper.database;
    final data = record.toMap()..remove('id');
    return db.update(
      'tyre_retreading_records',
      data,
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('tyre_retreading_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markReturned({
    required int id,
    required String returnDate,
    required double cost,
    String? billNumber,
    String? guarantee,
    String? remarks,
  }) async {
    final db = await _dbHelper.database;
    return db.update(
      'tyre_retreading_records',
      {
        'status': 'RETURNED',
        'return_date': returnDate,
        'retreading_cost': cost,
        'bill_number': _nullable(billNumber),
        'guarantee': _nullable(guarantee),
        'remarks': _nullable(remarks),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RetreadingSummary> getSummary({DateTime? fromDate, DateTime? toDate}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (fromDate != null) { where.add('sent_date >= ?'); args.add(_dateOnly(fromDate)); }
    if (toDate != null) { where.add('sent_date <= ?'); args.add(_dateOnly(toDate)); }
    final clause = where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}';
    final row = (await db.rawQuery('''
      SELECT COUNT(*) total_records,
             COALESCE(SUM(CASE WHEN status = 'AT_RETREADING' THEN 1 ELSE 0 END),0) at_retreading,
             COALESCE(SUM(CASE WHEN status = 'RETURNED' THEN 1 ELSE 0 END),0) returned,
             COALESCE(SUM(retreading_cost),0) total_cost
      FROM tyre_retreading_records$clause
    ''', args)).first;
    return RetreadingSummary(
      totalRecords: (row['total_records'] as num?)?.toInt() ?? 0,
      atRetreading: (row['at_retreading'] as num?)?.toInt() ?? 0,
      returned: (row['returned'] as num?)?.toInt() ?? 0,
      totalCost: (row['total_cost'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String? _nullable(String? value) {
    final v = value?.trim();
    return v == null || v.isEmpty ? null : v;
  }
}
