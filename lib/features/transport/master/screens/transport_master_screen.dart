import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/transport_vehicle_model.dart';
import '../providers/transport_master_provider.dart';
import 'transport_add_edit_screen.dart';

class TransportMasterScreen extends StatefulWidget {
  const TransportMasterScreen({super.key});

  @override
  State<TransportMasterScreen> createState() => _TransportMasterScreenState();
}

class _TransportMasterScreenState extends State<TransportMasterScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportProvider>().loadVehicles();
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

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
          // ======================================================
          // SIDEBAR
          // ======================================================
          AppSidebar(
            selectedIndex: 4,
            onMenuTap: (index) {
              handleMenuTap(index, context: context);
            },
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          _buildFilters(),

          const SizedBox(height: 24),

          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transport Master',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage registered transport vehicles across the fleet.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        FilledButton.icon(
          onPressed: _addVehicle,
          icon: const Icon(Icons.add),
          label: const Text('Add Vehicle'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Row(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Search Vehicle',
                hintText: 'Registration number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // ======================================================
          // STATUS
          // ======================================================
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _statusFilter,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _statusFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildTable() {
    return Consumer<TransportProvider>(
      builder: (context, provider, child) {
        // --------------------------------------------------------
        // LOADING
        // --------------------------------------------------------

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00652C)),
          );
        }

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        if (provider.error != null) {
          return _buildError(provider.error!);
        }

        // --------------------------------------------------------
        // FILTER
        // --------------------------------------------------------

        final vehicles = _filteredVehicles(provider.vehicles);

        // --------------------------------------------------------
        // EMPTY
        // --------------------------------------------------------

        if (vehicles.isEmpty) {
          return _buildEmpty();
        }

        // --------------------------------------------------------
        // DATA TABLE
        // --------------------------------------------------------

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBECABC)),
          ),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: DataTable(
                          columnSpacing: 32,

                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFF3F4F6),
                          ),

                          columns: const [
                            DataColumn(label: Text('REGISTRATION')),
                            DataColumn(label: Text('MANUFACTURER')),
                            DataColumn(label: Text('MODEL')),
                            DataColumn(label: Text('YEAR')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('COMPLIANCE')),
                            DataColumn(label: Text('ACTIONS')),
                          ],

                          rows: vehicles.map((vehicle) {
                            return DataRow(
                              cells: [
                                // =================================
                                // REGISTRATION
                                // =================================
                                DataCell(
                                  Text(
                                    vehicle.registrationNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // =================================
                                // MANUFACTURER
                                // =================================
                                DataCell(Text(vehicle.manufacturerName ?? '-')),

                                // =================================
                                // MODEL
                                // =================================
                                DataCell(Text(vehicle.modelName ?? '-')),

                                // =================================
                                // YEAR
                                // =================================
                                DataCell(
                                  Text('${vehicle.manufacturingYear ?? '-'}'),
                                ),

                                // =================================
                                // STATUS
                                // =================================
                                DataCell(_statusChip(vehicle.status)),

                                // =================================
                                // COMPLIANCE
                                // =================================
                                DataCell(_complianceStatus(vehicle)),

                                // =================================
                                // ACTIONS
                                // =================================
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _editVehicle(vehicle.id!);
                                        },
                                      ),

                                      IconButton(
                                        tooltip: 'Delete',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        color: const Color(0xFFBA1A1A),
                                        onPressed: () {
                                          _deleteVehicle(vehicle.id!);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ==================================================
              // FOOTER
              // ==================================================
              _buildFooter(vehicles.length),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<TransportModel> _filteredVehicles(List<TransportModel> vehicles) {
    final query = _searchController.text.trim().toLowerCase();

    return vehicles.where((vehicle) {
      final matchesSearch =
          query.isEmpty ||
          vehicle.registrationNumber.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Active' && vehicle.status) ||
          (_statusFilter == 'Inactive' && !vehicle.status);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFE7E8EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF00652C) : const Color(0xFF4E5867),
        ),
      ),
    );
  }

  // ============================================================
  // COMPLIANCE
  // ============================================================

  Widget _complianceStatus(TransportModel vehicle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _complianceDot(vehicle.insuranceExpiry),
        _complianceDot(vehicle.fcExpiry),
        _complianceDot(vehicle.permitExpiry),
        _complianceDot(vehicle.taxExpiry),
      ],
    );
  }

  Widget _complianceDot(String? expiry) {
    final date = expiry == null ? null : DateTime.tryParse(expiry);

    final valid = date != null && !date.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: expiry ?? 'Not configured',
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: valid ? const Color(0xFF00652C) : const Color(0xFFBA1A1A),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter(int count) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        border: Border(top: BorderSide(color: Color(0xFFBECABC))),
      ),
      child: Row(
        children: [
          Text(
            'Showing $count entries',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          IconButton(onPressed: null, icon: const Icon(Icons.chevron_left)),

          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF00652C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(onPressed: null, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 52,
              color: Color(0xFF6F7A6E),
            ),

            SizedBox(height: 12),

            Text(
              'No transport vehicles found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 6),

            Text(
              'Add a vehicle to your fleet.',
              style: TextStyle(color: Color(0xFF4E5867)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),

          const SizedBox(height: 12),

          const Text(
            'Unable to load transport vehicles',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Text(error),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: () {
              context.read<TransportProvider>().loadVehicles();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _addVehicle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransportAddEditScreen()),
    );

    if (result == true && mounted) {
      await context.read<TransportProvider>().loadVehicles();
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editVehicle(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransportAddEditScreen(vehicleId: id)),
    );

    if (result == true && mounted) {
      await context.read<TransportProvider>().loadVehicles();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteVehicle(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Vehicle?'),
          content: const Text(
            'Are you sure you want to delete this transport vehicle?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await context.read<TransportProvider>().deleteVehicle(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Vehicle deleted successfully' : 'Failed to delete vehicle',
        ),
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
}
