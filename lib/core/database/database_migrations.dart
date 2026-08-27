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
    await db.execute('''
      CREATE TABLE excavators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        registration_number TEXT NOT NULL UNIQUE,
        manufacturer_id INTEGER NOT NULL,
        model_id INTEGER NOT NULL,
        manufacturing_year INTEGER,
        status INTEGER NOT NULL DEFAULT 1,
        insurance_expiry TEXT,
        fc_expiry TEXT,
        permit_expiry TEXT,
        tax_expiry TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (manufacturer_id)
          REFERENCES manufacturers(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (model_id)
          REFERENCES excavator_models(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      )
    ''');

    // ============================================================
    // 5. TRANSPORT VEHICLES
    // ============================================================
    await db.execute('''
      CREATE TABLE transport_vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        registration_number TEXT NOT NULL UNIQUE,
        manufacturer_id INTEGER NOT NULL,
        model_id INTEGER NOT NULL,
        manufacturing_year INTEGER,
        emission_standard TEXT,
        status INTEGER NOT NULL DEFAULT 1,
        insurance_expiry TEXT,
        fc_expiry TEXT,
        permit_expiry TEXT,
        tax_expiry TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (manufacturer_id)
          REFERENCES manufacturers(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE,

        FOREIGN KEY (model_id)
          REFERENCES transport_models(id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
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

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Database migrations will be added here
    // when the schema version changes.
  }
}
