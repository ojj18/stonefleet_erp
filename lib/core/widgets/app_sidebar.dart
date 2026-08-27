import 'package:flutter/material.dart';

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFBECABC))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF00652C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STONEFLEET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00652C),
                    ),
                  ),
                  Text(
                    'ERP MANAGER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFF4E5867),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          _navItem(icon: Icons.dashboard_outlined, title: 'Dashboard'),
          _navItem(icon: Icons.construction_outlined, title: 'Maintenance'),
          _navItem(icon: Icons.engineering_outlined, title: 'Service'),
          _navItem(
            icon: Icons.local_shipping,
            title: 'Excavator Master',
            active: true,
          ),
          _navItem(icon: Icons.build_outlined, title: 'Build'),

          const Spacer(),

          const Divider(color: Color(0xFFBECABC)),

          _navItem(icon: Icons.account_circle_outlined, title: 'Profile'),
          _navItem(icon: Icons.logout_outlined, title: 'Logout'),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String title,
    bool active = false,
  }) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7E8EA) : Colors.transparent,
        border: active
            ? const Border(left: BorderSide(color: Color(0xFF00652C), width: 4))
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 20,
            color: active ? const Color(0xFF00652C) : const Color(0xFF3F493F),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? const Color(0xFF00652C) : const Color(0xFF3F493F),
            ),
          ),
        ],
      ),
    );
  }
}
