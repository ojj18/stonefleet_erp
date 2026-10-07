import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/database/database_helper.dart';

class TransportSiteRepository {
  final DatabaseHelper _databaseHelper;

  TransportSiteRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  String _table(bool isLoadingSite) =>
      isLoadingSite ? 'transport_loading_sites' : 'transport_unloading_sites';

  Future<List<String>> getSites({required bool isLoadingSite}) async {
    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table(isLoadingSite),
      columns: ['name'],
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE',
    );

    return rows
        .map((r) => r['name']?.toString().trim() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<void> addSite(String name, {required bool isLoadingSite}) async {
    final value = name.trim();
    if (value.isEmpty) {
      throw ArgumentError('Invalid site name.');
    }

    final db = await _databaseHelper.database;
    await db.insert(
      _table(isLoadingSite),
      {
        'name': value,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> ensureSite(
    String name, {
    required bool isLoadingSite,
  }) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await addSite(value, isLoadingSite: isLoadingSite);
  }
}
