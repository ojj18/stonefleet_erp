import 'dart:developer';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_seed.dart';

class DatabaseMigrations {
  static Future<void> createTables(Database db) async {
    // ============================================================
    // 1. MANUFACTURERS
    // ============================================================
    await db.execute('''
      CREATE TABLE manufacturers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        code TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // ============================================================
    // 2. EXCAVATOR MODELS
    // ============================================================
    await db.execute('''
      CREATE TABLE excavator_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manufacturer_id INTEGER NOT NULL,
        model_name TEXT NOT NULL,
        model_code TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (manufacturer_id)
          REFERENCES manufacturers(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 3. TRANSPORT MODELS
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manufacturer_id INTEGER NOT NULL,
        model_name TEXT NOT NULL,
        model_code TEXT,
        vehicle_type TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (manufacturer_id)
          REFERENCES manufacturers(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 4. EXCAVATORS
    // ============================================================
    // ============================================================
    // 4. EXCAVATORS
    // ============================================================
    await db.execute('''
  CREATE TABLE excavators (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    registration_number TEXT NOT NULL UNIQUE,

    manufacturer_name TEXT,
    model_name TEXT,
    manufacturing_year INTEGER,

    status INTEGER NOT NULL DEFAULT 1,

    insurance_expiry TEXT,
    fc_expiry TEXT,
    permit_expiry TEXT,
    tax_expiry TEXT,

    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');
    // ============================================================
    // 5. TRANSPORT VEHICLES
    // ============================================================
    await db.execute('''
  CREATE TABLE transport_vehicles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    registration_number TEXT NOT NULL UNIQUE,

    manufacturer_name TEXT,
    model_name TEXT,

    manufacturing_year INTEGER,

    emission_standard TEXT,

    status INTEGER NOT NULL DEFAULT 1,

    insurance_expiry TEXT,
    fc_expiry TEXT,
    permit_expiry TEXT,
    tax_expiry TEXT,

    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

    // ============================================================
    // 6. SPARES
    // ============================================================
    await db.execute('''
      CREATE TABLE spares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        code TEXT,
        category TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // ============================================================
    // 7. EXCAVATOR MAINTENANCE
    // ============================================================
    await db.execute('''
      CREATE TABLE excavator_maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        excavator_id INTEGER NOT NULL,
        operator_name TEXT,
        shift TEXT,

        starting_hour REAL NOT NULL,
        closing_hour REAL NOT NULL,
        total_working_hour REAL NOT NULL,

        bucket_working_hour REAL DEFAULT 0,
        breaker_working_hour REAL DEFAULT 0,
        total_running_hour REAL NOT NULL,

        number_of_loads INTEGER DEFAULT 0,
        units REAL DEFAULT 0,

        diesel_filled REAL DEFAULT 0,
        diesel_rate REAL DEFAULT 0,
        diesel_expense REAL DEFAULT 0,
        diesel_expense_per_hour REAL DEFAULT 0,

        teeth_set_changed INTEGER NOT NULL DEFAULT 0,

        remarks TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (excavator_id)
          REFERENCES excavators(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 8. EXCAVATOR SERVICE
    // ============================================================
    await db.execute('''
      CREATE TABLE excavator_service (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        excavator_id INTEGER NOT NULL,

        service_date TEXT NOT NULL,
        current_hour_meter REAL NOT NULL,

        remarks TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (excavator_id)
          REFERENCES excavators(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 9. EXCAVATOR SERVICE ITEMS
    // ============================================================
    await db.execute('''
      CREATE TABLE excavator_service_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        service_id INTEGER NOT NULL,
        spare_id INTEGER NOT NULL,

        quantity REAL NOT NULL DEFAULT 1,
        cost REAL NOT NULL DEFAULT 0,

        remark TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (service_id)
          REFERENCES excavator_service(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,

        FOREIGN KEY (spare_id)
          REFERENCES spares(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        UNIQUE(service_id, spare_id)
      )
    ''');

    // ============================================================
    // 10. EXCAVATOR SERVICE SCHEDULES
    // ============================================================
    await db.execute('''
      CREATE TABLE excavator_service_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        excavator_model_id INTEGER NOT NULL,
        spare_id INTEGER NOT NULL,

        interval_hours REAL NOT NULL,
        warning_hours REAL NOT NULL DEFAULT 0,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (excavator_model_id)
          REFERENCES excavator_models(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (spare_id)
          REFERENCES spares(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        UNIQUE(excavator_model_id, spare_id)
      )
    ''');

    // ============================================================
    // 11. TRANSPORT MAINTENANCE
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        transport_vehicle_id INTEGER NOT NULL,
        driver_name TEXT,

        starting_km REAL NOT NULL,
        closing_km REAL NOT NULL,
        total_km REAL NOT NULL,

        number_of_loads INTEGER DEFAULT 0,

        loading_site TEXT,
        unloading_site TEXT,

        diesel_filled REAL DEFAULT 0,
        diesel_rate REAL DEFAULT 0,
        diesel_expense REAL DEFAULT 0,

        remarks TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (transport_vehicle_id)
          REFERENCES transport_vehicles(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 12. TRANSPORT SERVICE
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_service (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        transport_vehicle_id INTEGER NOT NULL,

        service_date TEXT NOT NULL,
        current_km REAL NOT NULL,

        remarks TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (transport_vehicle_id)
          REFERENCES transport_vehicles(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 13. TRANSPORT SERVICE ITEMS
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_service_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        service_id INTEGER NOT NULL,
        spare_id INTEGER NOT NULL,

        quantity REAL NOT NULL DEFAULT 1,
        cost REAL NOT NULL DEFAULT 0,

        remark TEXT,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (service_id)
          REFERENCES transport_service(id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,

        FOREIGN KEY (spare_id)
          REFERENCES spares(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        UNIQUE(service_id, spare_id)
      )
    ''');

    // ============================================================
    // 14. TRANSPORT SERVICE SCHEDULES
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_service_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        transport_model_id INTEGER NOT NULL,
        spare_id INTEGER NOT NULL,

        interval_km REAL NOT NULL,
        warning_km REAL NOT NULL DEFAULT 0,

        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (transport_model_id)
          REFERENCES transport_models(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (spare_id)
          REFERENCES spares(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        UNIQUE(transport_model_id, spare_id)
      )
    ''');

    log('All 14 StoneFleet tables created successfully.');
    await DatabaseSeed.seed(db);
  }

  static Future<bool> _hasColumn(
    Database db,
    String tableName,
    String columnName,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($tableName)');

    return result.any((column) => column['name'] == columnName);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // ============================================================
    // VERSION 2
    // EXCAVATOR MIGRATION
    // ============================================================

    if (oldVersion < 2) {
      final excavatorHasManufacturerId = await _hasColumn(
        db,
        'excavators',
        'manufacturer_id',
      );

      final excavatorHasModelId = await _hasColumn(
        db,
        'excavators',
        'model_id',
      );

      // ----------------------------------------------------------
      // Only migrate if the OLD columns actually exist.
      //
      // This is important because some development databases
      // may already contain the new excavator schema.
      // ----------------------------------------------------------

      if (excavatorHasManufacturerId || excavatorHasModelId) {
        await db.transaction((txn) async {
          // --------------------------------------------------------
          // 1. Create new excavators table
          // --------------------------------------------------------

          await txn.execute('''
          CREATE TABLE excavators_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            registration_number TEXT NOT NULL UNIQUE,

            manufacturer_name TEXT,
            model_name TEXT,
            manufacturing_year INTEGER,

            status INTEGER NOT NULL DEFAULT 1,

            insurance_expiry TEXT,
            fc_expiry TEXT,
            permit_expiry TEXT,
            tax_expiry TEXT,

            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

          // --------------------------------------------------------
          // 2. Copy old data
          // --------------------------------------------------------

          await txn.execute('''
          INSERT INTO excavators_new (
            id,
            registration_number,
            manufacturer_name,
            model_name,
            manufacturing_year,
            status,
            insurance_expiry,
            fc_expiry,
            permit_expiry,
            tax_expiry,
            created_at,
            updated_at
          )
          SELECT
            e.id,
            e.registration_number,
            m.name,
            em.model_name,
            e.manufacturing_year,
            e.status,
            e.insurance_expiry,
            e.fc_expiry,
            e.permit_expiry,
            e.tax_expiry,
            e.created_at,
            e.updated_at
          FROM excavators e
          LEFT JOIN manufacturers m
            ON m.id = e.manufacturer_id
          LEFT JOIN excavator_models em
            ON em.id = e.model_id
        ''');

          // --------------------------------------------------------
          // 3. Drop old table
          // --------------------------------------------------------

          await txn.execute('DROP TABLE excavators');

          // --------------------------------------------------------
          // 4. Rename new table
          // --------------------------------------------------------

          await txn.execute(
            'ALTER TABLE excavators_new '
            'RENAME TO excavators',
          );
        });

        log(
          'Database migrated to version 2: '
          'excavator schema updated.',
        );
      } else {
        log(
          'Database version 2: '
          'excavator schema already updated. '
          'Migration skipped.',
        );
      }
    }

    // ============================================================
    // VERSION 3
    // TRANSPORT MIGRATION
    // ============================================================

    if (oldVersion < 3) {
      final transportHasManufacturerId = await _hasColumn(
        db,
        'transport_vehicles',
        'manufacturer_id',
      );

      final transportHasModelId = await _hasColumn(
        db,
        'transport_vehicles',
        'model_id',
      );

      // ----------------------------------------------------------
      // Only migrate if old Transport columns exist.
      // ----------------------------------------------------------

      if (transportHasManufacturerId || transportHasModelId) {
        await db.transaction((txn) async {
          // --------------------------------------------------------
          // 1. Create new transport table
          // --------------------------------------------------------

          await txn.execute('''
          CREATE TABLE transport_vehicles_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            registration_number TEXT NOT NULL UNIQUE,

            manufacturer_name TEXT,
            model_name TEXT,
            manufacturing_year INTEGER,

            emission_standard TEXT,

            status INTEGER NOT NULL DEFAULT 1,

            insurance_expiry TEXT,
            fc_expiry TEXT,
            permit_expiry TEXT,
            tax_expiry TEXT,

            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

          // --------------------------------------------------------
          // 2. Copy existing Transport data
          // --------------------------------------------------------

          await txn.execute('''
          INSERT INTO transport_vehicles_new (
            id,
            registration_number,
            manufacturer_name,
            model_name,
            manufacturing_year,
            emission_standard,
            status,
            insurance_expiry,
            fc_expiry,
            permit_expiry,
            tax_expiry,
            created_at,
            updated_at
          )
          SELECT
            t.id,
            t.registration_number,
            m.name,
            tm.model_name,
            t.manufacturing_year,
            t.emission_standard,
            t.status,
            t.insurance_expiry,
            t.fc_expiry,
            t.permit_expiry,
            t.tax_expiry,
            t.created_at,
            t.updated_at
          FROM transport_vehicles t
          LEFT JOIN manufacturers m
            ON m.id = t.manufacturer_id
          LEFT JOIN transport_models tm
            ON tm.id = t.model_id
        ''');

          // --------------------------------------------------------
          // 3. Drop old Transport table
          // --------------------------------------------------------

          await txn.execute('DROP TABLE transport_vehicles');

          // --------------------------------------------------------
          // 4. Rename new table
          // --------------------------------------------------------

          await txn.execute(
            'ALTER TABLE transport_vehicles_new '
            'RENAME TO transport_vehicles',
          );
        });

        log(
          'Database migrated to version 3: '
          'transport schema updated.',
        );
      } else {
        log(
          'Database version 3: '
          'transport schema already updated. '
          'Migration skipped.',
        );
      }
    }
  }
}
