import 'package:flutter/material.dart';
import 'package:stonefleet_erp/features/transport/maintenance/screens/transport_maintenance_screen.dart';
import 'package:stonefleet_erp/features/transport/master/screens/transport_master_screen.dart';
import 'package:stonefleet_erp/features/transport/service/screens/transport_service_screen.dart';

import '../../features/dashboard/screen/dashboard_screen.dart';
import '../../features/excavator/maintenance/screens/excavator_maintenance_screen.dart';
import '../../features/excavator/master/screens/excavator_master_screen.dart';
import '../../features/excavator/service/screens/excavator_service_screen.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuTap;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          // Logo / App name
          _menuItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            index: 0,
          ),

          _menuItem(
            icon: Icons.agriculture_outlined,
            title: 'Excavators',
            index: 1,
          ),

          _menuItem(
            icon: Icons.build_outlined,
            title: 'Excavator Maintenance',
            index: 2,
          ),

          _menuItem(
            icon: Icons.handyman_outlined,
            title: 'Excavator Service',
            index: 3,
          ),

          _menuItem(
            icon: Icons.local_shipping_outlined,
            title: 'Transport',
            index: 4,
          ),

          _menuItem(
            icon: Icons.build_outlined,
            title: 'Transport Maintenance',
            index: 5,
          ),

          _menuItem(
            icon: Icons.handyman_outlined,
            title: 'Transport Service',
            index: 6,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = selectedIndex == index;

    return InkWell(
      onTap: () => onMenuTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF00652C) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void handleMenuTap(int index, {required BuildContext? context}) {
  switch (index) {
    case 0:
      // Dashboard
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      break;

    case 1:
      // Excavator
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ExcavatorMasterScreen()),
      );
      break;

    case 2:
      // Excavator Maintenance
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ExcavatorMaintenanceScreen()),
      );
      break;

    case 3:
      // Excavator Service
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ExcavatorServiceScreen()),
      );
      break;

    case 4:
      // Transport
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const TransportMasterScreen()),
      );
      break;

    case 5:
      // Transport
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const TransportMaintenanceScreen()),
      );
      break;
    case 6:
      // Transport
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const TransportServiceScreen()),
      );
      break;
  }
}
