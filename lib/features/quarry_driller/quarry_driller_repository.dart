import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/database_helper.dart';

class QuarryDrillerRepository {
  final DatabaseHelper _helper;
  QuarryDrillerRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;

  Future<List<String>> getDrillers() async {
    final db = await _helper.database;
    final rows = await db.query(
      'quarry_drillers',
      columns: ['name'],
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<void> ensureDriller(String name) async {
    final db = await _helper.database;
    await db.insert('quarry_drillers', {
      'name': name.trim(),
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> save(Map<String, dynamic> data, {int? id}) async {
    final db = await _helper.database;
    if (id == null) return db.insert('quarry_driller_records', data);
    return db.update(
      'quarry_driller_records',
      {...data, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _helper.database;
    final where = <String>[];
    final args = <Object?>[];
    String date(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (from != null) {
      where.add('record_date >= ?');
      args.add(date(from));
    }
    if (to != null) {
      where.add('record_date <= ?');
      args.add(date(to));
    }
    return db.query(
      'quarry_driller_records',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'record_date DESC, id DESC',
    );
  }

  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('quarry_driller_records', where: 'id = ?', whereArgs: [id]);
  }
}
