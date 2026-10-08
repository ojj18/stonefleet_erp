import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';

class BoulderProducerRepository {
  final DatabaseHelper _databaseHelper;
  BoulderProducerRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<String>> getProducers() async {
    final db = await _databaseHelper.database;
    final rows = await db.query('quarry_boulder_producers', columns: ['name'], where: 'is_active = 1', orderBy: 'name COLLATE NOCASE');
    return rows.map((r) => r['name']?.toString().trim() ?? '').where((v) => v.isNotEmpty).toList();
  }

  Future<void> addProducer(String name) async {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Invalid boulder producer name.');
    final db = await _databaseHelper.database;
    await db.insert('quarry_boulder_producers', {
      'name': value,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
