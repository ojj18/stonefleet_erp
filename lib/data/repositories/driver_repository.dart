
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';

class DriverRepository {
  final DatabaseHelper _databaseHelper;
  DriverRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<String>> getDrivers() async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      'drivers',
      columns: ['name'],
      where: 'is_active = 1 AND LOWER(name) != ?',
      whereArgs: ['company'],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows
        .map((r) => r['name']?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<void> addDriver(String name) async {
    final value = name.trim();
    if (value.isEmpty || value.toLowerCase() == 'company') {
      throw ArgumentError('Invalid driver name.');
    }
    final db = await _databaseHelper.database;
    await db.insert(
      'drivers',
      {
        'name': value,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> ensureDriver(String name) async {
    final value = name.trim();
    if (value.isEmpty || value.toLowerCase() == 'company') return;
    await addDriver(value);
  }
}
