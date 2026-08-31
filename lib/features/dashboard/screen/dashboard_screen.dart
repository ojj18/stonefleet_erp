import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_sidebar.dart';
import '../../../data/models/dashboard_model.dart';
import '../provider/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.dashboard == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.dashboard == null) {
          return _ErrorView(
            message: provider.error!,
            onRetry: provider.loadDashboard,
          );
        }

        final dashboard = provider.dashboard ?? const DashboardModel();

        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                selectedIndex: 0,
                onMenuTap: (index) {
                  handleMenuTap(index, context: context);
                },
              ),

              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: provider.refreshDashboard,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(provider),

                              const SizedBox(height: 24),

                              _buildKpiSection(dashboard),

                              const SizedBox(height: 24),

                              _buildExcavatorSection(dashboard),

                              const SizedBox(height: 24),

                              _buildServiceOverview(dashboard),

                              const SizedBox(height: 24),

                              _buildTransportSection(dashboard),

                              const SizedBox(height: 24),

                              _buildRecentServices(dashboard),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
      ),
      child: Row(
        children: [
          const Text(
            'StoneFleet ERP Manager',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.notifications_outlined),
          // ),
          const SizedBox(width: 8),

          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person_outline, color: Color(0xFF00652C)),
          ),

          const SizedBox(width: 8),

          const Text('Admin', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(DashboardProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'StoneFleet Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Overview of your fleet operations',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // KPI SECTION
  // ============================================================

  Widget _buildKpiSection(DashboardModel dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns = 3;

        if (width >= 1300) {
          columns = 6;
        } else if (width >= 900) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;

        final cardWidth = (width - ((columns - 1) * spacing)) / columns;

        final cards = [
          _KpiCard(
            title: 'Total Excavators',
            value: '${dashboard.totalExcavators}',
            subtitle: '${dashboard.workingExcavators} working',
            icon: Icons.construction_outlined,
          ),
          _KpiCard(
            title: 'Transport Vehicles',
            value: '${dashboard.totalTransportVehicles}',
            subtitle: '${dashboard.workingTransportVehicles} working',
            icon: Icons.local_shipping_outlined,
          ),
          _KpiCard(
            title: 'Working Hours',
            value: dashboard.totalWorkingHours.toStringAsFixed(1),
            subtitle: 'Today',
            icon: Icons.access_time_outlined,
          ),
          _KpiCard(
            title: 'Transport KM',
            value: dashboard.totalTransportKm.toStringAsFixed(1),
            subtitle: 'Today',
            icon: Icons.route_outlined,
          ),
          _KpiCard(
            title: 'Diesel Used',
            value: '${dashboard.totalDieselUsed.toStringAsFixed(1)} L',
            subtitle: 'Today',
            icon: Icons.local_gas_station_outlined,
          ),
          _KpiCard(
            title: 'Diesel Expense',
            value: '₹${dashboard.totalDieselExpense.toStringAsFixed(0)}',
            subtitle: 'Today',
            icon: Icons.currency_rupee_outlined,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: cardWidth, child: card);
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // EXCAVATOR OPERATIONS
  // ============================================================

  Widget _buildExcavatorSection(DashboardModel dashboard) {
    return _DashboardCard(
      title: "Today's Excavator Operations",
      icon: Icons.construction_outlined,
      child: dashboard.excavatorOperations.isEmpty
          ? const _EmptyState(
              message: 'No excavator operations recorded today.',
            )
          : _ExcavatorTable(operations: dashboard.excavatorOperations),
    );
  }

  // ============================================================
  // SERVICE OVERVIEW
  // ============================================================

  Widget _buildServiceOverview(DashboardModel dashboard) {
    return _DashboardCard(
      title: 'Service Overview',
      icon: Icons.build_outlined,
      child: dashboard.serviceOverview.isEmpty
          ? const _EmptyState(message: 'No service records available.')
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: dashboard.serviceOverview.map((service) {
                return SizedBox(
                  width: 300,
                  child: _ServiceOverviewTile(service: service),
                );
              }).toList(),
            ),
    );
  }

  // ============================================================
  // TRANSPORT OPERATIONS
  // ============================================================

  Widget _buildTransportSection(DashboardModel dashboard) {
    return _DashboardCard(
      title: "Today's Transport Operations",
      icon: Icons.local_shipping_outlined,
      child: dashboard.transportOperations.isEmpty
          ? const _EmptyState(
              message: 'No transport operations recorded today.',
            )
          : _TransportTable(operations: dashboard.transportOperations),
    );
  }

  // ============================================================
  // RECENT SERVICES
  // ============================================================

  Widget _buildRecentServices(DashboardModel dashboard) {
    return _DashboardCard(
      title: 'Recent Service Activity',
      icon: Icons.history_outlined,
      child: dashboard.recentServices.isEmpty
          ? const _EmptyState(message: 'No recent service activity.')
          : _RecentServiceTable(services: dashboard.recentServices),
    );
  }

  String _todayText() {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }
}

// ================================================================
// KPI CARD
// ================================================================

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DASHBOARD CARD
// ================================================================

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            child,
          ],
        ),
      ),
    );
  }
}

// ================================================================
// EXCAVATOR TABLE
// ================================================================

class _ExcavatorTable extends StatelessWidget {
  final List<ExcavatorOperationModel> operations;

  const _ExcavatorTable({required this.operations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 58,
        columns: const [
          DataColumn(label: Text('Vehicle')),
          DataColumn(label: Text('Operator')),
          DataColumn(label: Text('Shift')),
          DataColumn(label: Text('Opening')),
          DataColumn(label: Text('Closing')),
          DataColumn(label: Text('Hours')),
          DataColumn(label: Text('Tonnage')),
          DataColumn(label: Text('Diesel')),
        ],
        rows: operations.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.registrationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(item.operatorName)),
              DataCell(Text(item.shift)),
              DataCell(Text(item.openingHours.toStringAsFixed(1))),
              DataCell(Text(item.closingHours.toStringAsFixed(1))),
              DataCell(Text(item.totalHours.toStringAsFixed(1))),
              DataCell(Text(item.tonnage.toStringAsFixed(1))),
              DataCell(Text('${item.dieselFilled.toStringAsFixed(1)} L')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// TRANSPORT TABLE
// ================================================================

class _TransportTable extends StatelessWidget {
  final List<TransportOperationModel> operations;

  const _TransportTable({required this.operations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 58,
        columns: const [
          DataColumn(label: Text('Vehicle')),
          DataColumn(label: Text('Driver')),
          DataColumn(label: Text('Start KM')),
          DataColumn(label: Text('Closing KM')),
          DataColumn(label: Text('Total KM')),
          DataColumn(label: Text('Loads')),
          DataColumn(label: Text('Loading Site')),
          DataColumn(label: Text('Unloading Site')),
          DataColumn(label: Text('Diesel')),
        ],
        rows: operations.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.registrationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(item.driverName)),
              DataCell(Text(item.startingKm.toStringAsFixed(1))),
              DataCell(Text(item.closingKm.toStringAsFixed(1))),
              DataCell(Text(item.totalKm.toStringAsFixed(1))),
              DataCell(Text('${item.numberOfLoads}')),
              DataCell(Text(item.loadingSite)),
              DataCell(Text(item.unloadingSite)),
              DataCell(Text('${item.dieselFilled.toStringAsFixed(1)} L')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// SERVICE OVERVIEW TILE
// ================================================================

class _ServiceOverviewTile extends StatelessWidget {
  final ServiceOverviewModel service;

  const _ServiceOverviewTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final status = _statusDetails(service.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.build_outlined,
              size: 19,
              color: status.foreground,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.registrationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  service.serviceName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  service.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: status.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusDetails _statusDetails(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.overdue:
        return const _StatusDetails(
          label: 'Overdue',
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFC62828),
        );

      case ServiceStatus.due:
        return const _StatusDetails(
          label: 'Due',
          background: Color(0xFFFFF8E1),
          foreground: Color(0xFFF57F17),
        );

      case ServiceStatus.upcoming:
        return const _StatusDetails(
          label: 'Upcoming',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
    }
  }
}

class _StatusDetails {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusDetails({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

// ================================================================
// RECENT SERVICE TABLE
// ================================================================

class _RecentServiceTable extends StatelessWidget {
  final List<RecentServiceModel> services;

  const _RecentServiceTable({required this.services});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 58,
        columns: const [
          DataColumn(label: Text('Vehicle')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Service')),
          DataColumn(label: Text('Current KM')),
          DataColumn(label: Text('Current Hours')),
          DataColumn(label: Text('Cost')),
        ],
        rows: services.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.registrationNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(item.serviceDate)),
              DataCell(Text(item.serviceDescription)),
              DataCell(
                Text(
                  item.currentKm > 0 ? item.currentKm.toStringAsFixed(1) : '-',
                ),
              ),
              DataCell(
                Text(
                  item.currentHours > 0
                      ? item.currentHours.toStringAsFixed(1)
                      : '-',
                ),
              ),
              DataCell(Text('₹${item.totalCost.toStringAsFixed(0)}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }
}

// ================================================================
// ERROR
// ================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          Text(
            'Unable to load dashboard',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
