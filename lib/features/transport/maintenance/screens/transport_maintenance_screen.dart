import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/transport_maintenance_model.dart';
import '../../../transport/master/providers/transport_master_provider.dart';
import '../providers/transport_maintenance_provider.dart';
import 'transport_maintenance_add_edit_screen.dart';

class TransportMaintenanceScreen extends StatefulWidget {
  const TransportMaintenanceScreen({super.key});

  @override
  State<TransportMaintenanceScreen> createState() =>
      _TransportMaintenanceScreenState();
}

class _TransportMaintenanceScreenState
    extends State<TransportMaintenanceScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportMaintenanceProvider>().loadMaintenance();
    });

    _searchController.addListener(() {
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
          // ========================================================
          // COMMON SIDEBAR
          // ========================================================
          AppSidebar(
            selectedIndex: 5,
            onMenuTap: (index) {
              handleMenuTap(index, context: context);
            },
          ),

          // ========================================================
          // MAIN CONTENT
          // ========================================================
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

                            _buildMaintenanceTable(),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transport Maintenance',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Track daily transport vehicle operation, fuel usage and maintenance activities.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        FilledButton.icon(
          onPressed: _openAddScreen,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Maintenance'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    return Consumer<TransportMaintenanceProvider>(
      builder: (context, provider, child) {
        final records = provider.maintenance;

        final totalKm = records.fold<double>(
          0,
          (sum, item) => sum + item.totalKm,
        );

        final totalDiesel = records.fold<double>(
          0,
          (sum, item) => sum + item.dieselFilled,
        );

        final totalExpense = records.fold<double>(
          0,
          (sum, item) => sum + item.dieselExpense,
        );

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Records',
                value: records.length.toString(),
                icon: Icons.receipt_long_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Total KM',
                value: _formatNumber(totalKm),
                suffix: ' KM',
                icon: Icons.speed_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Diesel Used',
                value: _formatNumber(totalDiesel),
                suffix: ' L',
                icon: Icons.local_gas_station_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Diesel Expense',
                value: _formatCurrency(totalExpense),
                icon: Icons.currency_rupee,
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
    String suffix = '',
  }) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(18),
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
            child: Icon(icon, color: const Color(0xFF00652C), size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68717D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$value$suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1E),
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
  // FILTER CARD
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
                hintText:
                    'Search driver, vehicle ID, loading or unloading site...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<TransportMaintenanceProvider>().loadMaintenance();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildMaintenanceTable() {
    return Consumer<TransportMaintenanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.maintenance.isEmpty) {
          return _buildLoading();
        }

        if (provider.error != null && provider.maintenance.isEmpty) {
          return _buildError(provider.error!);
        }

        final records = _filteredRecords(provider.maintenance);

        if (records.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E5E9)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                _buildTableHeader(),

                const Divider(height: 1),

                ...records.map((record) => _buildTableRow(record)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: const Color(0xFFF8F9FB),
      child: Row(
        children: [
          _headerCell('VEHICLE', width: 130),

          _headerCell('DRIVER', width: 150),

          _headerCell('KM', width: 90),

          _headerCell('LOADS', width: 80),

          _headerCell('DIESEL', width: 100),

          _headerCell('EXPENSE', width: 110),

          _headerCell('ROUTE', width: 190),

          const Expanded(
            child: Text(
              'ACTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF68717D),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {required double width}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF68717D),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _buildTableRow(TransportMaintenanceModel record) {
    return InkWell(
      onTap: () => _openEditScreen(record),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFECEFF1))),
        ),
        child: Row(
          children: [
            // VEHICLE
            SizedBox(
              width: 130,
              child: _vehicleBadge(record.transportVehicleId),
            ),

            // DRIVER
            SizedBox(
              width: 150,
              child: Text(
                record.driverName?.isNotEmpty == true
                    ? record.driverName!
                    : '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // KM
            SizedBox(
              width: 90,
              child: Text(
                '${_formatNumber(record.totalKm)} KM',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // LOADS
            SizedBox(
              width: 80,
              child: Text(
                record.numberOfLoads.toString(),
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // DIESEL
            SizedBox(
              width: 100,
              child: Text(
                '${_formatNumber(record.dieselFilled)} L',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            // EXPENSE
            SizedBox(
              width: 110,
              child: Text(
                _formatCurrency(record.dieselExpense),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ROUTE
            SizedBox(
              width: 190,
              child: Text(
                _routeText(record),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4E5867)),
              ),
            ),

            // ACTION
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openEditScreen(record),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: const Color(0xFF00652C),
                  ),

                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(record),
                    icon: const Icon(Icons.delete_outline, size: 19),
                    color: const Color(0xFFBA1A1A),
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
  // VEHICLE BADGE
  // ============================================================

  Widget _vehicleBadge(int vehicleId) {
    return FutureBuilder(
      future: context.read<TransportProvider>().getById(vehicleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'TRN-$vehicleId',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00652C),
              ),
            ),
          );
        }

        final vehicle = snapshot.data;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            vehicle?.registrationNumber ?? 'TRN-$vehicleId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00652C),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ROUTE
  // ============================================================

  String _routeText(TransportMaintenanceModel record) {
    final loading = record.loadingSite?.trim() ?? '';

    final unloading = record.unloadingSite?.trim() ?? '';

    if (loading.isEmpty && unloading.isEmpty) {
      return '-';
    }

    if (loading.isEmpty) {
      return unloading;
    }

    if (unloading.isEmpty) {
      return loading;
    }

    return '$loading → $unloading';
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<TransportMaintenanceModel> _filteredRecords(
    List<TransportMaintenanceModel> records,
  ) {
    if (_searchQuery.isEmpty) {
      return records;
    }

    return records.where((record) {
      final driver = record.driverName?.toLowerCase() ?? '';

      final vehicleId = record.transportVehicleId.toString();

      final loading = record.loadingSite?.toLowerCase() ?? '';

      final unloading = record.unloadingSite?.toLowerCase() ?? '';

      return driver.contains(_searchQuery) ||
          vehicleId.contains(_searchQuery) ||
          loading.contains(_searchQuery) ||
          unloading.contains(_searchQuery);
    }).toList();
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _openAddScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransportMaintenanceAddEditScreen(),
      ),
    );

    if (!mounted) return;

    await context.read<TransportMaintenanceProvider>().loadMaintenance();
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _openEditScreen(TransportMaintenanceModel record) async {
    if (record.id == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransportMaintenanceAddEditScreen(maintenance: record),
      ),
    );

    if (!mounted) return;

    await context.read<TransportMaintenanceProvider>().loadMaintenance();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _confirmDelete(TransportMaintenanceModel record) async {
    if (record.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Maintenance Record?'),
          content: const Text(
            'This maintenance record will be permanently deleted. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
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

    final provider = context.read<TransportMaintenanceProvider>();

    final success = await provider.deleteMaintenance(record.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Maintenance record deleted.'
              : provider.error ?? 'Unable to delete record.',
        ),
        backgroundColor: success
            ? const Color(0xFF00652C)
            : const Color(0xFFBA1A1A),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
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
              Icons.local_shipping_outlined,
              size: 30,
              color: Color(0xFF00652C),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No maintenance records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 7),

          const Text(
            'Add your first transport maintenance record to get started.',
            style: TextStyle(fontSize: 13, color: Color(0xFF68717D)),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _openAddScreen,
            icon: const Icon(Icons.add),
            label: const Text('Add Maintenance'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00652C),
            ),
          ),
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
            'Unable to load maintenance records',
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
              context.read<TransportMaintenanceProvider>().loadMaintenance();
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
}
