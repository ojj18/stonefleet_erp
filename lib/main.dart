import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/database/database_helper.dart';

import 'features/excavator/master/providers/excavator_master_provider.dart';

import 'features/excavator/master/providers/excavator_provider.dart';
import 'features/excavator/master/screens/excavator_master_screen.dart';

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
  // APP
  // ------------------------------------------------------------

  runApp(const StoneFleetApp());
}

class StoneFleetApp extends StatelessWidget {
  const StoneFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --------------------------------------------------------
        // REGISTERED EXCAVATORS
        // --------------------------------------------------------
        ChangeNotifierProvider(
          create: (_) => ExcavatorProvider()..loadExcavators(),
        ),

        // --------------------------------------------------------
        // EXCAVATOR MASTER MODELS
        // --------------------------------------------------------
        ChangeNotifierProvider(
          create: (_) => ExcavatorMasterProvider()..loadModels(),
        ),
      ],

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

        home: const ExcavatorMasterScreen(),
      ),
    );
  }
}
