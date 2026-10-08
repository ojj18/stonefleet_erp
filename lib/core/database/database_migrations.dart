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

    owner_name TEXT,
    permanent_address TEXT,
    vehicle_chasi_number TEXT,
    vehicle_engine_number TEXT,
    color TEXT,
    insurance_company TEXT,
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

    owner_name TEXT,
    permanent_address TEXT,
    vehicle_chasi_number TEXT,
    vehicle_engine_number TEXT,
    color TEXT,
    insurance_company TEXT,
    emission_standard TEXT,
    unit REAL NOT NULL DEFAULT 0,

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
        maintenance_date TEXT,
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
        maintenance_date TEXT NOT NULL,
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

    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

    // ============================================================
    // 15. INVENTORY ITEMS
    // ============================================================
    await db.execute('''
  CREATE TABLE inventory_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_name TEXT NOT NULL,
    category TEXT,
    unit TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

    // ============================================================
    // 16. INVENTORY PURCHASES
    // ============================================================
    await db.execute('''
  CREATE TABLE inventory_purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_number TEXT,
    supplier_name TEXT,
    purchase_date TEXT NOT NULL,
    bill_image_path TEXT,
    subtotal REAL NOT NULL DEFAULT 0,
    gst_amount REAL NOT NULL DEFAULT 0,
    grand_total REAL NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

    // ============================================================
    // 17. INVENTORY PURCHASE ITEMS
    // ============================================================
    await db.execute('''
  CREATE TABLE inventory_purchase_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity REAL NOT NULL DEFAULT 0,
    unit_price REAL NOT NULL DEFAULT 0,
    gst_percentage REAL NOT NULL DEFAULT 0,
    subtotal REAL NOT NULL DEFAULT 0,
    gst_amount REAL NOT NULL DEFAULT 0,
    total_cost REAL NOT NULL DEFAULT 0,

    created_at TEXT NOT NULL,

    FOREIGN KEY (purchase_id)
      REFERENCES inventory_purchases(id)
      ON DELETE CASCADE
      ON UPDATE CASCADE,

    FOREIGN KEY (item_id)
      REFERENCES inventory_items(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE
  )
''');

    // ============================================================
    // 18. INVENTORY USAGE
    // ============================================================
    await db.execute('''
  CREATE TABLE inventory_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    quantity_used REAL NOT NULL DEFAULT 0,
    usage_date TEXT NOT NULL,
    used_for TEXT,
    remarks TEXT,
    created_at TEXT NOT NULL,

    FOREIGN KEY (item_id)
      REFERENCES inventory_items(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE
  )
''');

    // ============================================================
    // 19. INVENTORY STOCK MOVEMENTS
    // ============================================================
    await db.execute('''
  CREATE TABLE inventory_stock_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id INTEGER NOT NULL,
    transaction_type TEXT NOT NULL,
    quantity REAL NOT NULL,
    previous_stock REAL NOT NULL DEFAULT 0,
    current_stock REAL NOT NULL DEFAULT 0,
    reference_id INTEGER,
    transaction_date TEXT NOT NULL,
    remarks TEXT,
    created_at TEXT NOT NULL,

    FOREIGN KEY (item_id)
      REFERENCES inventory_items(id)
      ON DELETE RESTRICT
      ON UPDATE CASCADE
  )
''');

    // ============================================================
    // 20. QUARRY BLASTING PURCHASES
    // ============================================================
    await db.execute('''
      CREATE TABLE quarry_blasting_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_date TEXT NOT NULL,
        operator_name TEXT NOT NULL DEFAULT 'Company',
        salary REAL NOT NULL DEFAULT 0,

        bullet_quantity REAL NOT NULL DEFAULT 0,
        bullet_price REAL NOT NULL DEFAULT 0,
        bullet_total REAL NOT NULL DEFAULT 0,

        wire_3m_quantity REAL NOT NULL DEFAULT 0,
        wire_3m_price REAL NOT NULL DEFAULT 0,
        wire_3m_total REAL NOT NULL DEFAULT 0,

        wire_4m_quantity REAL NOT NULL DEFAULT 0,
        wire_4m_price REAL NOT NULL DEFAULT 0,
        wire_4m_total REAL NOT NULL DEFAULT 0,

        ed_quantity REAL NOT NULL DEFAULT 0,
        ed_price REAL NOT NULL DEFAULT 0,
        ed_total REAL NOT NULL DEFAULT 0,

        total_cost REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quarry_boulder_trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_date TEXT NOT NULL,
        transport_vehicle_id INTEGER NOT NULL,
        registration_number TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        producer_name TEXT NOT NULL DEFAULT 'Company',
        unit REAL NOT NULL DEFAULT 0,
        trips INTEGER NOT NULL DEFAULT 0,
        total_load REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (transport_vehicle_id) REFERENCES transport_vehicles(id)
          ON DELETE RESTRICT ON UPDATE CASCADE
      )
    ''');


    await db.execute('''
      CREATE TABLE IF NOT EXISTS quarry_boulder_producers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    final producerSeedNow = DateTime.now().toIso8601String();
    for (final name in ['Murugan', 'Madhavan', 'Company']) {
      await db.insert(
        'quarry_boulder_producers',
        {'name': name, 'is_active': 1, 'created_at': producerSeedNow},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blasting_operators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transport_sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transport_loading_sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transport_unloading_sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    final seedNow = DateTime.now().toIso8601String();
    for (final name in ['Madhavan', 'Murugan', 'Company']) {
      await db.insert(
        'blasting_operators',
        {'name': name, 'is_active': 1, 'created_at': seedNow},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }


    // ============================================================
    // DIESEL MANAGEMENT
    // ============================================================
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diesel_receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_date TEXT NOT NULL,
        source_name TEXT NOT NULL,
        quantity_litres REAL NOT NULL DEFAULT 0,
        rate REAL NOT NULL DEFAULT 0,
        total_cost REAL NOT NULL DEFAULT 0,
        supplier_name TEXT,
        bill_number TEXT,
        remarks TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS diesel_fillings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filling_date TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        vehicle_id INTEGER NOT NULL,
        vehicle_registration TEXT NOT NULL,
        quantity_litres REAL NOT NULL DEFAULT 0,
        rate REAL NOT NULL DEFAULT 0,
        total_cost REAL NOT NULL DEFAULT 0,
        meter_reading REAL,
        operator_name TEXT,
        shift TEXT,
        remarks TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS diesel_stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        previous_stock REAL NOT NULL DEFAULT 0,
        current_stock REAL NOT NULL DEFAULT 0,
        reference_id INTEGER,
        transaction_date TEXT NOT NULL,
        remarks TEXT,
        created_at TEXT NOT NULL
      )
    ''');


    // ============================================================
    // 21. TYRE RETREADING MANAGEMENT
    // ============================================================
    await db.execute('''
      CREATE TABLE tyre_retreading_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transport_vehicle_id INTEGER NOT NULL,
        registration_number TEXT NOT NULL,
        tyre_brand TEXT,
        tyre_serial_number TEXT NOT NULL,
        tyre_size TEXT NOT NULL,
        retreading_company TEXT NOT NULL,
        sent_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'AT_RETREADING',
        return_date TEXT,
        retreading_cost REAL NOT NULL DEFAULT 0,
        bill_number TEXT,
        guarantee TEXT,
        remarks TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (transport_vehicle_id) REFERENCES transport_vehicles(id)
          ON DELETE RESTRICT ON UPDATE CASCADE
      )
    ''');

    await DatabaseSeed.seed(db);

    log('All StoneFleet tables created successfully.');
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
    if (oldVersion < 2) {
      final tables = ['excavators', 'transport_vehicles'];
      final columns = [
        'owner_name',
        'permanent_address',
        'vehicle_chasi_number',
        'vehicle_engine_number',
        'color',
        'insurance_company',
      ];
      for (final table in tables) {
        for (final column in columns) {
          if (!await _hasColumn(db, table, column)) {
            await db.execute('ALTER TABLE $table ADD COLUMN $column TEXT');
          }
        }
      }
    }

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

                owner_name TEXT,
                permanent_address TEXT,
                vehicle_chasi_number TEXT,
                vehicle_engine_number TEXT,
                color TEXT,
                insurance_company TEXT,
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

    if (oldVersion < 2) {
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

                owner_name TEXT,
                permanent_address TEXT,
                vehicle_chasi_number TEXT,
                vehicle_engine_number TEXT,
                color TEXT,
                insurance_company TEXT,
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
    // ============================================================
    // VERSION 4
    // USERS / AUTHENTICATION
    // ============================================================

    if (oldVersion < 2) {
      await db.execute('''
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT
  )
''');

      final now = DateTime.now().toIso8601String();

      await db.insert('users', {
        'username': 'admin',
        'password': 'admin@194',
        'role': 'admin',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await db.insert('users', {
        'username': 'user',
        'password': 'user@123',
        'role': 'user',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      log('Database migrated to version 4: users table created.');
    }

    // ============================================================
    // VERSION 4
    // INVENTORY SCHEMA
    //
    // Development DB reset:
    // - inventory_purchase_items uses item_id (not spare_id)
    // - inventory_stock_movements uses item_id (not spare_id)
    // - inventory_usage uses item_id
    // - inventory tables remain separate from the Spare Master (spares)
    // ============================================================

    if (oldVersion < 3) {
      // ------------------------------------------------------------
      // 1. Inventory item master
      // ------------------------------------------------------------
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_name TEXT NOT NULL,
          category TEXT,
          unit TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // ------------------------------------------------------------
      // 2. Inventory purchases
      // ------------------------------------------------------------
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventory_purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bill_number TEXT,
          supplier_name TEXT,
          purchase_date TEXT NOT NULL,
          bill_image_path TEXT,
          subtotal REAL NOT NULL DEFAULT 0,
          gst_amount REAL NOT NULL DEFAULT 0,
          grand_total REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // ------------------------------------------------------------
      // 3. Recreate purchase items with item_id.
      //
      // This is intentionally destructive because this is the
      // development database and the old spare_id schema is being
      // replaced by the separate Inventory Item schema.
      // ------------------------------------------------------------
      await db.execute('DROP TABLE IF EXISTS inventory_purchase_items');

      await db.execute('''
        CREATE TABLE inventory_purchase_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_id INTEGER NOT NULL,
          item_id INTEGER NOT NULL,
          quantity REAL NOT NULL DEFAULT 0,
          unit_price REAL NOT NULL DEFAULT 0,
          gst_percentage REAL NOT NULL DEFAULT 0,
          subtotal REAL NOT NULL DEFAULT 0,
          gst_amount REAL NOT NULL DEFAULT 0,
          total_cost REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,

          FOREIGN KEY (purchase_id)
            REFERENCES inventory_purchases(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE,

          FOREIGN KEY (item_id)
            REFERENCES inventory_items(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
        )
      ''');

      // ------------------------------------------------------------
      // 4. Inventory usage
      // ------------------------------------------------------------
      await db.execute('DROP TABLE IF EXISTS inventory_usage');

      await db.execute('''
        CREATE TABLE inventory_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          quantity_used REAL NOT NULL DEFAULT 0,
          usage_date TEXT NOT NULL,
          used_for TEXT,
          remarks TEXT,
          created_at TEXT NOT NULL,

          FOREIGN KEY (item_id)
            REFERENCES inventory_items(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
        )
      ''');

      // ------------------------------------------------------------
      // 5. Recreate stock movements with item_id.
      // ------------------------------------------------------------
      await db.execute('DROP TABLE IF EXISTS inventory_stock_movements');

      await db.execute('''
        CREATE TABLE inventory_stock_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          transaction_type TEXT NOT NULL,
          quantity REAL NOT NULL,
          previous_stock REAL NOT NULL DEFAULT 0,
          current_stock REAL NOT NULL DEFAULT 0,
          reference_id INTEGER,
          transaction_date TEXT NOT NULL,
          remarks TEXT,
          created_at TEXT NOT NULL,

          FOREIGN KEY (item_id)
            REFERENCES inventory_items(id)
            ON DELETE RESTRICT
            ON UPDATE CASCADE
        )
      ''');

      log(
        'Database migrated to version 4: '
        'inventory schema updated.',
      );
    }

    // ============================================================
    // VERSION 6
    // QUARRY BLASTING PURCHASES
    // ============================================================
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quarry_blasting_purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_date TEXT NOT NULL,

          bullet_quantity REAL NOT NULL DEFAULT 0,
          bullet_price REAL NOT NULL DEFAULT 0,
          bullet_total REAL NOT NULL DEFAULT 0,

          wire_3m_quantity REAL NOT NULL DEFAULT 0,
          wire_3m_price REAL NOT NULL DEFAULT 0,
          wire_3m_total REAL NOT NULL DEFAULT 0,

          wire_4m_quantity REAL NOT NULL DEFAULT 0,
          wire_4m_price REAL NOT NULL DEFAULT 0,
          wire_4m_total REAL NOT NULL DEFAULT 0,

          ed_quantity REAL NOT NULL DEFAULT 0,
          ed_price REAL NOT NULL DEFAULT 0,
          ed_total REAL NOT NULL DEFAULT 0,

          total_cost REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      log('Database migrated to version 6: quarry blasting purchases created.');
    }
    // ============================================================
    // VERSION 4
    // TRANSPORT UNIT + QUARRY BOULDER TRIPS
    // ============================================================
    if (oldVersion < 4) {
      if (!await _hasColumn(db, 'transport_vehicles', 'unit')) {
        await db.execute(
          'ALTER TABLE transport_vehicles ADD COLUMN unit REAL NOT NULL DEFAULT 0',
        );
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS quarry_boulder_trips (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trip_date TEXT NOT NULL,
          transport_vehicle_id INTEGER NOT NULL,
          registration_number TEXT NOT NULL,
          driver_name TEXT NOT NULL,
          unit REAL NOT NULL DEFAULT 0,
          trips INTEGER NOT NULL DEFAULT 0,
          total_load REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (transport_vehicle_id) REFERENCES transport_vehicles(id)
            ON DELETE RESTRICT ON UPDATE CASCADE
        )
      ''');
      log('Database migrated to version 4: transport unit and quarry boulder trips created.');
    }

    // ============================================================
    // VERSION 6
    // EXCAVATOR MAINTENANCE DATE
    // ============================================================
    if (oldVersion < 6) {
      if (!await _hasColumn(db, 'excavator_maintenance', 'maintenance_date')) {
        await db.execute(
          'ALTER TABLE excavator_maintenance ADD COLUMN maintenance_date TEXT',
        );
        await db.execute('''
          UPDATE excavator_maintenance
          SET maintenance_date = substr(created_at, 1, 10)
          WHERE maintenance_date IS NULL OR maintenance_date = ''
        ''');
      }
      log('Database migrated to version 6: excavator maintenance date created.');
    }

    // ============================================================
    // VERSION 5
    // DRIVER MASTER + TRANSPORT MAINTENANCE DATE +
    // BLASTING OPERATORS / OPERATOR-SPECIFIC PURCHASES
    // ============================================================
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS drivers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      // Preserve existing driver/operator names as selectable drivers.
      await db.execute('''
        INSERT OR IGNORE INTO drivers (name, is_active, created_at)
        SELECT DISTINCT TRIM(driver_name), 1, ?
        FROM transport_maintenance
        WHERE TRIM(COALESCE(driver_name, '')) <> ''
          AND LOWER(TRIM(driver_name)) <> 'company'
      ''', [DateTime.now().toIso8601String()]);

      await db.execute('''
        INSERT OR IGNORE INTO drivers (name, is_active, created_at)
        SELECT DISTINCT TRIM(operator_name), 1, ?
        FROM excavator_maintenance
        WHERE TRIM(COALESCE(operator_name, '')) <> ''
          AND LOWER(TRIM(operator_name)) <> 'company'
      ''', [DateTime.now().toIso8601String()]);

      await db.execute('''
        INSERT OR IGNORE INTO drivers (name, is_active, created_at)
        SELECT DISTINCT TRIM(driver_name), 1, ?
        FROM quarry_boulder_trips
        WHERE TRIM(COALESCE(driver_name, '')) <> ''
          AND LOWER(TRIM(driver_name)) <> 'company'
      ''', [DateTime.now().toIso8601String()]);

      if (!await _hasColumn(db, 'transport_maintenance', 'maintenance_date')) {
        await db.execute(
          'ALTER TABLE transport_maintenance ADD COLUMN maintenance_date TEXT',
        );
        await db.execute('''
          UPDATE transport_maintenance
          SET maintenance_date = substr(created_at, 1, 10)
          WHERE maintenance_date IS NULL OR maintenance_date = ''
        ''');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS blasting_operators (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      final seedNow = DateTime.now().toIso8601String();
      for (final name in ['Madhavan', 'Murugan', 'Company']) {
        await db.insert(
          'blasting_operators',
          {'name': name, 'is_active': 1, 'created_at': seedNow},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      if (!await _hasColumn(db, 'quarry_blasting_purchases', 'operator_name')) {
        await db.execute(
          "ALTER TABLE quarry_blasting_purchases ADD COLUMN operator_name TEXT NOT NULL DEFAULT 'Company'",
        );
      }
      if (!await _hasColumn(db, 'quarry_blasting_purchases', 'salary')) {
        await db.execute(
          'ALTER TABLE quarry_blasting_purchases ADD COLUMN salary REAL NOT NULL DEFAULT 0',
        );
      }

      log('Database migrated to version 5: drivers, maintenance date and blasting operators created.');
    }

    // ============================================================
    // VERSION 7
    // TRANSPORT LOADING / UNLOADING SITE MASTER
    // ============================================================
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transport_sites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      log('Database migrated to version 7: transport site master created.');
    }

    // ============================================================
    // VERSION 8
    // SEPARATE TRANSPORT LOADING / UNLOADING SITE MASTERS
    // ============================================================
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transport_loading_sites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS transport_unloading_sites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      // Migrate only the values actually used in existing records.
      // Loading values go only to loading master; unloading values go only
      // to unloading master. This prevents one type from appearing in the other.
      final loadingRows = await db.rawQuery('''
        SELECT DISTINCT TRIM(loading_site) AS name
        FROM transport_maintenance
        WHERE loading_site IS NOT NULL AND TRIM(loading_site) <> ''
      ''');
      for (final row in loadingRows) {
        final name = row['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          await db.insert(
            'transport_loading_sites',
            {'name': name, 'is_active': 1, 'created_at': DateTime.now().toIso8601String()},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      final unloadingRows = await db.rawQuery('''
        SELECT DISTINCT TRIM(unloading_site) AS name
        FROM transport_maintenance
        WHERE unloading_site IS NOT NULL AND TRIM(unloading_site) <> ''
      ''');
      for (final row in unloadingRows) {
        final name = row['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          await db.insert(
            'transport_unloading_sites',
            {'name': name, 'is_active': 1, 'created_at': DateTime.now().toIso8601String()},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      log('Database migrated to version 8: separate loading and unloading site masters created.');
    }
    // ============================================================
    // VERSION 9
    // DIESEL MANAGEMENT
    // ============================================================
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS diesel_receipts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          receipt_date TEXT NOT NULL,
          source_name TEXT NOT NULL,
          quantity_litres REAL NOT NULL DEFAULT 0,
          rate REAL NOT NULL DEFAULT 0,
          total_cost REAL NOT NULL DEFAULT 0,
          supplier_name TEXT,
          bill_number TEXT,
          remarks TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS diesel_fillings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          filling_date TEXT NOT NULL,
          vehicle_type TEXT NOT NULL,
          vehicle_id INTEGER NOT NULL,
          vehicle_registration TEXT NOT NULL,
          quantity_litres REAL NOT NULL DEFAULT 0,
          rate REAL NOT NULL DEFAULT 0,
          total_cost REAL NOT NULL DEFAULT 0,
          meter_reading REAL,
          operator_name TEXT,
          shift TEXT,
          remarks TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS diesel_stock_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_type TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 0,
          previous_stock REAL NOT NULL DEFAULT 0,
          current_stock REAL NOT NULL DEFAULT 0,
          reference_id INTEGER,
          transaction_date TEXT NOT NULL,
          remarks TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      log('Database migrated to version 9: diesel management tables created.');
    }


    // ============================================================
    // VERSION 10
    // QUARRY BOULDER PRODUCER MASTER + PRODUCER FIELD
    // ============================================================
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quarry_boulder_producers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      final producerNow = DateTime.now().toIso8601String();
      for (final name in ['Murugan', 'Madhavan', 'Company']) {
        await db.insert(
          'quarry_boulder_producers',
          {'name': name, 'is_active': 1, 'created_at': producerNow},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      if (!await _hasColumn(db, 'quarry_boulder_trips', 'producer_name')) {
        await db.execute(
          "ALTER TABLE quarry_boulder_trips ADD COLUMN producer_name TEXT NOT NULL DEFAULT 'Company'",
        );
      }

      log('Database migrated to version 10: quarry boulder producer created.');
    }

    // ============================================================
    // VERSION 11
    // TYRE RETREADING MANAGEMENT
    // ============================================================
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tyre_retreading_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transport_vehicle_id INTEGER NOT NULL,
          registration_number TEXT NOT NULL,
          tyre_brand TEXT,
          tyre_serial_number TEXT NOT NULL,
          tyre_size TEXT NOT NULL,
          retreading_company TEXT NOT NULL,
          sent_date TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'AT_RETREADING',
          return_date TEXT,
          retreading_cost REAL NOT NULL DEFAULT 0,
          bill_number TEXT,
          guarantee TEXT,
          remarks TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (transport_vehicle_id) REFERENCES transport_vehicles(id)
            ON DELETE RESTRICT ON UPDATE CASCADE
        )
      ''');
      log('Database migrated to version 11: tyre retreading management created.');
    }


  }
}
