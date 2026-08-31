import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stonefleet_erp/features/dashboard/screen/dashboard_screen.dart';

import 'core/database/database_helper.dart';

import 'data/services/vehicle_api_service.dart';

// ============================================================
// EXCAVATOR
// ============================================================

import 'features/dashboard/provider/dashboard_provider.dart';
import 'features/excavator/master/providers/excavator_master_provider.dart';
import 'features/excavator/master/providers/excavator_provider.dart';
import 'features/excavator/master/screens/excavator_master_screen.dart';

import 'features/excavator/maintenance/providers/excavator_maintenance_provider.dart';

import 'features/excavator/service/providers/excavator_service_provider.dart';

// ============================================================
// TRANSPORT
// ============================================================

import 'features/transport/maintenance/providers/transport_maintenance_provider.dart';
import 'features/transport/master/providers/transport_master_provider.dart';
import 'features/transport/service/providers/transport_service_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // SQLITE INITIALIZATION
  // ------------------------------------------------------------

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  final db = await DatabaseHelper.instance.database;

  debugPrint('DB PATH: ${db.path}');

  // ------------------------------------------------------------
  // TEST VEHICLE API
  // ------------------------------------------------------------

  await testVehicleApi();

  // ------------------------------------------------------------
  // APP
  // ------------------------------------------------------------

  runApp(const StoneFleetApp());
}

// ============================================================
// VEHICLE API TEST
// ============================================================

Future<void> testVehicleApi() async {
  final service = VehicleApiService(apiKey: 'pk_test_21wtgca020zjlcghkfo7038');

  try {
    final result = await service.getVehicleDetails('TN25CM5143');

    debugPrint('VEHICLE RESPONSE:');
    debugPrint(result.toString());
  } catch (e) {
    debugPrint('VEHICLE API ERROR:');
    debugPrint(e.toString());
  }
}

// ============================================================
// APP
// ============================================================

class StoneFleetApp extends StatelessWidget {
  const StoneFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ========================================================
        // REGISTERED EXCAVATORS
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => ExcavatorProvider()..loadExcavators(),
        ),

        // ========================================================
        // EXCAVATOR MASTER MODELS
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => ExcavatorMasterProvider()..loadModels(),
        ),

        // ========================================================
        // EXCAVATOR MAINTENANCE
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => ExcavatorMaintenanceProvider()..loadMaintenance(),
        ),

        // ========================================================
        // EXCAVATOR SERVICE
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => ExcavatorServiceProvider()..loadServices(),
        ),

        // ========================================================
        // TRANSPORT MASTER
        // ========================================================
        ChangeNotifierProvider(
          create: (_) => TransportProvider()..loadVehicles(),
        ),

        // ============================================================
        // TRANSPORT MAINTENANCE
        // ============================================================
        ChangeNotifierProvider(
          create: (_) => TransportMaintenanceProvider()..loadMaintenance(),
        ),
        // --------------------------------------------------------
        // TRANSPORT SERVICE
        // --------------------------------------------------------
        ChangeNotifierProvider(
          create: (_) => TransportServiceProvider()..loadServices(),
        ),
        // --------------------------------------------------------
        // Dashboard
        // --------------------------------------------------------
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],

      // ==========================================================
      // MATERIAL APP
      // ==========================================================
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'StoneFleet ERP Manager',

        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00652C)),

          scaffoldBackgroundColor: const Color(0xFFF8F9FB),

          fontFamily: 'Inter',

          inputDecorationTheme: const InputDecorationTheme(
            filled: true,

            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),

        // --------------------------------------------------------
        // INITIAL SCREEN
        // --------------------------------------------------------
        home: const DashboardScreen(),
      ),
    );
  }
}
