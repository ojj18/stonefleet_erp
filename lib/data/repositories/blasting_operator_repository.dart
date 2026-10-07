
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';

class BlastingOperatorRepository {
  final DatabaseHelper _databaseHelper;
  BlastingOperatorRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<String>> getOperators() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'blasting_operators',
      columns: ['name'],
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map((r) => r['name']?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<void> addOperator(String name) async {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Invalid operator name.');
    final db = await _databaseHelper.database;
    await db.insert(
      'blasting_operators',
      {
        'name': value,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
