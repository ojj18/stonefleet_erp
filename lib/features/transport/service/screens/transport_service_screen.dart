import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/transport_vehicle_model.dart';
import '../../../../data/models/transport_service_model.dart';
import '../../../../data/repositories/transport_service_repository.dart';
import '../../master/providers/transport_master_provider.dart';
import '../providers/transport_service_provider.dart';
import 'transport_service_add_edit_screen.dart';

class TransportServiceScreen extends StatefulWidget {
  const TransportServiceScreen({super.key});

  @override
  State<TransportServiceScreen> createState() => _TransportServiceScreenState();
}

class _TransportServiceScreenState extends State<TransportServiceScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<TransportServiceProvider>().loadServices();
      context.read<TransportProvider>().loadVehicles();
    });

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 6,
            onMenuTap: (index) {
              handleMenuTap(index, context: context);
            },
          ),

          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageHeader(),

                            const SizedBox(height: 24),

                            _buildSummaryCards(),

                            const SizedBox(height: 24),

                            _buildFilterCard(),

                            const SizedBox(height: 20),

                            _buildServiceTable(),
                          ],
                        ),
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
  }

  // ============================================================
  // TOP BAR
  // ============================================================

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
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transport Service',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Track transport vehicle servicing, spare parts and service history.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        FilledButton.icon(
          onPressed: _openAddScreen,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Service'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return Consumer<TransportServiceProvider>(
      builder: (context, provider, child) {
        final services = provider.services;

        final now = DateTime.now();

        final thisMonth = services.where((service) {
          final date = DateTime.tryParse(service.serviceDate);

          if (date == null) {
            return false;
          }

          return date.year == now.year && date.month == now.month;
        }).length;

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Services',
                value: services.length.toString(),
                icon: Icons.build_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'This Month',
                value: thisMonth.toString(),
                icon: Icons.calendar_month_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Active Vehicles',
                value: context
                    .watch<TransportProvider>()
                    .vehicles
                    .where((vehicle) => vehicle.status)
                    .length
                    .toString(),
                icon: Icons.local_shipping_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF00652C), size: 22),
          ),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Color(0xFF68717D)),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search registration number, date or remarks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          OutlinedButton.icon(
            onPressed: () {
              context.read<TransportServiceProvider>().loadServices();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(110, 52)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildServiceTable() {
    return Consumer<TransportServiceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.services.isEmpty) {
          return _buildLoading();
        }

        if (provider.error != null && provider.services.isEmpty) {
          return _buildError(provider.error!);
        }

        final filtered = _filteredServices(
          provider.services,
          context.read<TransportProvider>().vehicles,
        );

        if (filtered.isEmpty) {
          return _buildEmpty();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E5E9)),
          ),
          child: Column(
            children: [
              _buildTableHeader(),

              const Divider(height: 1),

              ...filtered.map(
                (service) => _buildServiceRow(
                  service,
                  context.read<TransportProvider>().vehicles,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('REGISTRATION', style: _headerStyle)),

          Expanded(flex: 2, child: Text('SERVICE DATE', style: _headerStyle)),

          Expanded(flex: 2, child: Text('CURRENT KM', style: _headerStyle)),

          Expanded(
            flex: 1,
            child: Text(
              'ITEMS',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'TOTAL COST',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),

          SizedBox(
            width: 100,
            child: Text(
              'ACTION',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICE ROW
  // ============================================================

  Widget _buildServiceRow(
    TransportServiceModel service,
    List<TransportModel> vehicles,
  ) {
    final vehicle = _findVehicle(service.transportVehicleId, vehicles);

    return InkWell(
      onTap: service.id == null ? null : () => _openEditScreen(service),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
        ),
        child: Row(
          children: [
            // --------------------------------------------------
            // REGISTRATION
            // --------------------------------------------------
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF00652C),
                      size: 19,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      vehicle?.registrationNumber ?? 'Unknown Vehicle',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------
            Expanded(flex: 2, child: Text(_formatDate(service.serviceDate))),

            // --------------------------------------------------
            // CURRENT KM
            // --------------------------------------------------
            Expanded(flex: 2, child: Text(_formatNumber(service.currentKm))),

            // --------------------------------------------------
            // ITEMS
            // --------------------------------------------------
            Expanded(
              flex: 1,
              child: FutureBuilder<_ItemSummary>(
                future: _getItemSummary(service.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00652C),
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Text(
                      snapshot.data!.count.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),

            // --------------------------------------------------
            // TOTAL COST
            // --------------------------------------------------
            Expanded(
              flex: 2,
              child: FutureBuilder<_ItemSummary>(
                future: _getItemSummary(service.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00652C),
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatCurrency(snapshot.data!.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                },
              ),
            ),

            // --------------------------------------------------
            // ACTION
            // --------------------------------------------------
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: service.id == null
                        ? null
                        : () => _openEditScreen(service),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),

                  IconButton(
                    tooltip: 'Delete',
                    onPressed: service.id == null
                        ? null
                        : () => _confirmDelete(service),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FILTER LOGIC
  // ============================================================

  List<TransportServiceModel> _filteredServices(
    List<TransportServiceModel> services,
    List<TransportModel> vehicles,
  ) {
    if (_searchQuery.isEmpty) {
      return services;
    }

    return services.where((service) {
      final vehicle = _findVehicle(service.transportVehicleId, vehicles);

      final registration = vehicle?.registrationNumber.toLowerCase() ?? '';

      final date = _formatDate(service.serviceDate).toLowerCase();

      final remarks = service.remarks?.toLowerCase() ?? '';

      final km = service.currentKm.toString();

      return registration.contains(_searchQuery) ||
          date.contains(_searchQuery) ||
          remarks.contains(_searchQuery) ||
          km.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openAddScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TransportServiceAddEditScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      await context.read<TransportServiceProvider>().loadServices();
    }
  }

  Future<void> _openEditScreen(TransportServiceModel service) async {
    if (service.id == null) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransportServiceAddEditScreen(serviceId: service.id!),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await context.read<TransportServiceProvider>().loadServices();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _confirmDelete(TransportServiceModel service) async {
    if (service.id == null) {
      return;
    }

    final registration = _findVehicle(
      service.transportVehicleId,
      context.read<TransportProvider>().vehicles,
    )?.registrationNumber;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text(
            'Are you sure you want to delete '
            'the service record'
            '${registration == null ? '' : ' for $registration'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await context
        .read<TransportServiceProvider>()
        .deleteService(service.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Service deleted successfully.'
              : context.read<TransportServiceProvider>().error ??
                    'Unable to delete service.',
        ),
        backgroundColor: success
            ? const Color(0xFF00652C)
            : const Color(0xFFBA1A1A),
      ),
    );
  }

  // ============================================================
  // ITEM SUMMARY
  // ============================================================

  Future<_ItemSummary> _getItemSummary(int? serviceId) async {
    if (serviceId == null) {
      return const _ItemSummary(count: 0, total: 0);
    }

    final repository = TransportServiceRepository();

    final items = await repository.getItems(serviceId);

    var total = 0.0;

    for (final item in items) {
      total += item.quantity * item.cost;
    }

    return _ItemSummary(count: items.length, total: total);
  }

  // ============================================================
  // VEHICLE
  // ============================================================

  TransportModel? _findVehicle(int vehicleId, List<TransportModel> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              size: 32,
              color: Color(0xFF00652C),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _searchQuery.isEmpty
                ? 'No service records found'
                : 'No matching service records',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 7),

          Text(
            _searchQuery.isEmpty
                ? 'Add your first transport service record to get started.'
                : 'Try a different registration number or search term.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF68717D)),
          ),

          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _openAddScreen,
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF00652C)),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFFBA1A1A)),

          const SizedBox(height: 12),

          const Text(
            'Unable to load service records',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF68717D)),
          ),

          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: () {
              context.read<TransportServiceProvider>().loadServices();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}

// ============================================================
// ITEM SUMMARY
// ============================================================

class _ItemSummary {
  final int count;
  final double total;

  const _ItemSummary({required this.count, required this.total});
}

// ============================================================
// TABLE HEADER STYLE
// ============================================================

const TextStyle _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: Color(0xFF68717D),
  letterSpacing: 0.4,
);
