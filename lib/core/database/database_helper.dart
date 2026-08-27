import 'dart:developer';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_migrations.dart';
import '../constants/database_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationSupportDirectory();

    final dbPath = join(directory.path, DatabaseConstants.databaseName);

    log('DATABASE PATH: $dbPath');

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DatabaseConstants.databaseVersion,
        onCreate: (db, version) async {
          await DatabaseMigrations.createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await DatabaseMigrations.onUpgrade(db, oldVersion, newVersion);
        },
      ),
    );
  }
}
