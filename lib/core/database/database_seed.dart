import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/table_constants.dart';

class DatabaseSeed {
  static Future<void> seed(Database db) async {
    await _seedManufacturers(db);
    await _seedTransportModels(db);
    await _seedExcavatorModels(db);
    await _seedSpares(db);
  }

  // ============================================================
  // MANUFACTURERS
  // ============================================================

  static Future<void> _seedManufacturers(Database db) async {
    final manufacturers = [
      {'name': 'Tata', 'code': 'TATA'},
      {'name': 'Ashok Leyland', 'code': 'AL'},
      {'name': 'BharatBenz', 'code': 'BHARATBENZ'},
      {'name': 'Mahindra', 'code': 'MAHINDRA'},
      {'name': 'Volvo', 'code': 'VOLVO'},
      {'name': 'Komatsu', 'code': 'KOMATSU'},
      {'name': 'SDLG', 'code': 'SDLG'},
    ];

    for (final manufacturer in manufacturers) {
      await db.insert(TableConstants.manufacturers, {
        ...manufacturer,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ============================================================
  // TRANSPORT MODELS
  // ============================================================

  static Future<void> _seedTransportModels(Database db) async {
    final models = [
      // ---------------- TATA ----------------
      {
        'manufacturer_code': 'TATA',
        'model_name': 'LPT 3023',
        'model_code': 'LPT-3023',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'SIGNA 3023.T',
        'model_code': 'SIGNA-3023-T',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'LPT 3725',
        'model_code': 'LPT-3725',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'SIGNA 3725.T',
        'model_code': 'SIGNA-3725-T',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'LPT 4425',
        'model_code': 'LPT-4425',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'SIGNA 4425.T',
        'model_code': 'SIGNA-4425-T',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'TATA',
        'model_name': 'SIGNA 4830.T',
        'model_code': 'SIGNA-4830-T',
        'vehicle_type': 'HAULAGE',
      },

      // ---------------- ASHOK LEYLAND ----------------
      {
        'manufacturer_code': 'AL',
        'model_name': 'AVTR 4525H DTLA',
        'model_code': 'AVTR-4525H-DTLA',
        'vehicle_type': 'HAULAGE',
      },
      {
        'manufacturer_code': 'AL',
        'model_name': 'AVTR 4625H LA',
        'model_code': 'AVTR-4625H-LA',
        'vehicle_type': 'HAULAGE',
      },

      // ---------------- MAHINDRA ----------------
      {
        'manufacturer_code': 'MAHINDRA',
        'model_name': '575 DI XP Plus',
        'model_code': '575-DI-XP-PLUS',
        'vehicle_type': 'TRACTOR',
      },
    ];

    await _insertTransportModels(db, models);
  }

  // ============================================================
  // EXCAVATOR MODELS
  // ============================================================

  static Future<void> _seedExcavatorModels(Database db) async {
    final models = [
      // ---------------- VOLVO ----------------
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC210',
        'model_code': 'EC210',
      },
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC220',
        'model_code': 'EC220',
      },
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC300D',
        'model_code': 'EC300D',
      },
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC380D',
        'model_code': 'EC380D',
      },
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC480D',
        'model_code': 'EC480D',
      },
      {
        'manufacturer_code': 'VOLVO',
        'model_name': 'EC550E',
        'model_code': 'EC550E',
      },

      // ---------------- KOMATSU ----------------
      {
        'manufacturer_code': 'KOMATSU',
        'model_name': 'PC210',
        'model_code': 'PC210',
      },
      {
        'manufacturer_code': 'KOMATSU',
        'model_name': 'PC300',
        'model_code': 'PC300',
      },

      // ---------------- SDLG ----------------
      // Add confirmed Stone Crusher model when confirmed.
    ];

    await _insertExcavatorModels(db, models);
  }

  // ============================================================
  // SPARES
  // ============================================================

  static Future<void> _seedSpares(Database db) async {
    final spares = [
      // ==========================================================
      // EXCAVATOR SPARES - 33
      // ==========================================================
      {
        'name': 'Teeth Set Changing',
        'code': 'EXC-001',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Hydraulic Hose Changing',
        'code': 'EXC-002',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Teeth Lock Set Changing',
        'code': 'EXC-003',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Engine Oil Service',
        'code': 'EXC-004',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Diesel Filter, Oil Filter, Air Filter (Inner, Outer) Changing',
        'code': 'EXC-005',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Water Separator Changing',
        'code': 'EXC-006',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Swing Motor Oil Service',
        'code': 'EXC-007',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Truck Motor Oil Service (Left / Right Side)',
        'code': 'EXC-008',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Hydraulic Oil Service',
        'code': 'EXC-009',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Hydraulic Filter Changing',
        'code': 'EXC-010',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Hydraulic Strainer Filter Changing',
        'code': 'EXC-011',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Bucket Pin, Bush Changing',
        'code': 'EXC-012',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Connecting Link Pin, Bush',
        'code': 'EXC-013',
        'category': 'EXCAVATOR',
      },
      {'name': 'Arm Cylinder Seal', 'code': 'EXC-014', 'category': 'EXCAVATOR'},
      {
        'name': 'Boom Cylinder Seal',
        'code': 'EXC-015',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Bucket Cylinder Seal',
        'code': 'EXC-016',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'A.C. Air Compressor',
        'code': 'EXC-017',
        'category': 'EXCAVATOR',
      },
      {'name': 'A.C. Filter', 'code': 'EXC-018', 'category': 'EXCAVATOR'},
      {'name': 'Radiator Fan Belt', 'code': 'EXC-019', 'category': 'EXCAVATOR'},
      {'name': 'A.C. Motor Belt', 'code': 'EXC-020', 'category': 'EXCAVATOR'},
      {
        'name': 'Track Link Assembly',
        'code': 'EXC-021',
        'category': 'EXCAVATOR',
      },
      {'name': 'Shoe Plate', 'code': 'EXC-022', 'category': 'EXCAVATOR'},
      {'name': 'Shoe Plate Bolt', 'code': 'EXC-023', 'category': 'EXCAVATOR'},
      {'name': 'Turbo Charger', 'code': 'EXC-024', 'category': 'EXCAVATOR'},
      {
        'name': 'Boom Main Pin, Bush',
        'code': 'EXC-025',
        'category': 'EXCAVATOR',
      },
      {
        'name': 'Engine Valve Door Packing',
        'code': 'EXC-026',
        'category': 'EXCAVATOR',
      },
      {'name': 'Injector', 'code': 'EXC-027', 'category': 'EXCAVATOR'},
      {'name': 'Fuel Pump', 'code': 'EXC-028', 'category': 'EXCAVATOR'},
      {'name': 'Feed Pump', 'code': 'EXC-029', 'category': 'EXCAVATOR'},
      {'name': 'X Frame', 'code': 'EXC-030', 'category': 'EXCAVATOR'},
      {
        'name': 'Track Bottom Roller',
        'code': 'EXC-031',
        'category': 'EXCAVATOR',
      },
      {'name': 'Track Top Roller', 'code': 'EXC-032', 'category': 'EXCAVATOR'},
      {'name': 'A.C. Gas Filling', 'code': 'EXC-033', 'category': 'EXCAVATOR'},

      // ==========================================================
      // TRANSPORT SPARES - 22
      // ==========================================================
      {
        'name': 'Cabin Spares Changing',
        'code': 'TRN-001',
        'category': 'TRANSPORT',
      },
      {
        'name': 'Cabin Front, Left, Right Glass Changing',
        'code': 'TRN-002',
        'category': 'TRANSPORT',
      },
      {
        'name': 'Cabin Side Glass Changing Left, Right',
        'code': 'TRN-003',
        'category': 'TRANSPORT',
      },
      {'name': 'Gear Box', 'code': 'TRN-004', 'category': 'TRANSPORT'},
      {
        'name': 'Clutch Plate Assembly',
        'code': 'TRN-005',
        'category': 'TRANSPORT',
      },
      {'name': 'Steering Pump', 'code': 'TRN-006', 'category': 'TRANSPORT'},
      {
        'name': 'Radiator Service and Spares',
        'code': 'TRN-007',
        'category': 'TRANSPORT',
      },
      {
        'name': 'King Pin, A-Rod Bush Changing',
        'code': 'TRN-008',
        'category': 'TRANSPORT',
      },
      {'name': 'Front Axle', 'code': 'TRN-009', 'category': 'TRANSPORT'},
      {'name': 'Second Axle', 'code': 'TRN-010', 'category': 'TRANSPORT'},
      {'name': 'Centre Housing', 'code': 'TRN-011', 'category': 'TRANSPORT'},
      {'name': 'Back Housing', 'code': 'TRN-012', 'category': 'TRANSPORT'},
      {'name': 'Brake Drum', 'code': 'TRN-013', 'category': 'TRANSPORT'},
      {'name': 'Brake Shoe Plate', 'code': 'TRN-014', 'category': 'TRANSPORT'},
      {'name': 'Engine Bed', 'code': 'TRN-015', 'category': 'TRANSPORT'},
      {'name': 'Gear Box Bed', 'code': 'TRN-016', 'category': 'TRANSPORT'},
      {'name': 'Crown Service', 'code': 'TRN-017', 'category': 'TRANSPORT'},
      {
        'name': 'Wheel Grease Packing',
        'code': 'TRN-018',
        'category': 'TRANSPORT',
      },
      {
        'name': 'Engine Oil Service',
        'code': 'TRN-019',
        'category': 'TRANSPORT',
      },
      {
        'name': 'Air Filter Changing Inner, Outer',
        'code': 'TRN-020',
        'category': 'TRANSPORT',
      },
      {'name': 'Fuel Filter', 'code': 'TRN-021', 'category': 'TRANSPORT'},
      {'name': 'Oil Filter', 'code': 'TRN-022', 'category': 'TRANSPORT'},
    ];

    for (final spare in spares) {
      await db.insert(TableConstants.spares, {
        ...spare,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ============================================================
  // INSERT TRANSPORT MODELS
  // ============================================================

  static Future<void> _insertTransportModels(
    Database db,
    List<Map<String, String>> models,
  ) async {
    for (final model in models) {
      final manufacturer = await db.query(
        TableConstants.manufacturers,
        columns: ['id'],
        where: 'code = ?',
        whereArgs: [model['manufacturer_code']],
        limit: 1,
      );

      if (manufacturer.isEmpty) {
        continue;
      }

      final manufacturerId = manufacturer.first['id'] as int;

      await db.insert(
        TableConstants.transportModels,
        {
          'manufacturer_id': manufacturerId,
          'model_name': model['model_name'],
          'model_code': model['model_code'],
          'vehicle_type': model['vehicle_type'],
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // ============================================================
  // INSERT EXCAVATOR MODELS
  // ============================================================

  static Future<void> _insertExcavatorModels(
    Database db,
    List<Map<String, String>> models,
  ) async {
    for (final model in models) {
      final manufacturer = await db.query(
        TableConstants.manufacturers,
        columns: ['id'],
        where: 'code = ?',
        whereArgs: [model['manufacturer_code']],
        limit: 1,
      );

      if (manufacturer.isEmpty) {
        continue;
      }

      final manufacturerId = manufacturer.first['id'] as int;

      await db.insert(
        TableConstants.excavatorModels,
        {
          'manufacturer_id': manufacturerId,
          'model_name': model['model_name'],
          'model_code': model['model_code'],
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
