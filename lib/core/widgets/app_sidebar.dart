import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stonefleet_erp/features/transport/maintenance/screens/transport_maintenance_screen.dart';
import 'package:stonefleet_erp/features/transport/master/screens/transport_master_screen.dart';
import 'package:stonefleet_erp/features/transport/service/screens/transport_service_screen.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/compliance/screens/compliance_screen.dart';
import '../../features/dashboard/screen/dashboard_screen.dart';
import '../../features/excavator/maintenance/screens/excavator_maintenance_screen.dart';
import '../../features/excavator/master/screens/excavator_master_screen.dart';
import '../../features/excavator/service/screens/excavator_service_screen.dart';
import '../../features/report/screens/reports_screen.dart';
import '../../features/service_notification/screens/service_notification_screen.dart';

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
        crossAxisAlignment: .center,
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
          _menuItem(
            icon: Icons.notifications_active_outlined,
            title: 'Service Notifications',
            index: 7,
          ),

          _menuItem(
            icon: Icons.assessment_outlined,
            title: 'Reports',
            index: 8,
          ),
          _menuItem(
            icon: Icons.verified_outlined,
            title: 'Compliance',
            index: 9,
          ),

          const Spacer(),

          _buildUserSection(context),
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

  Widget _buildUserSection(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final isAdmin = user.isAdmin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E5E9))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline_rounded,
                  color: const Color(0xFF00652C),
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF20242A),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      isAdmin ? 'Administrator' : 'User',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF68717D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () {
                authProvider.logout();

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 17),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF68717D),
                side: const BorderSide(color: Color(0xFFE1E5E9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
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

    case 7:
      // Service Notifications
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ServiceNotificationScreen()),
      );
      break;

    case 8:
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      );
      break;
    case 9:
      // Compliance
      Navigator.pushReplacement(
        context!,
        MaterialPageRoute(builder: (_) => const ComplianceScreen()),
      );
      break;
  }
}
