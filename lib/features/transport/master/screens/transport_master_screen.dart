import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_config.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../../data/models/transport_vehicle_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../service_notification/providers/service_notification_provider.dart';
import '../providers/transport_master_provider.dart';
import 'transport_add_edit_screen.dart';

class TransportMasterScreen extends StatefulWidget {
  const TransportMasterScreen({super.key});

  @override
  State<TransportMasterScreen> createState() => _TransportMasterScreenState();
}

class _TransportMasterScreenState extends State<TransportMasterScreen> {
  _TransportMasterScreenState();

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  int _rowsPerPage = 10;

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.t('Transport Master'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              SizedBox(height: 6),

              Text(
                AppLocalization.t(
                  'Manage registered transport vehicles across the fleet.',
                ),
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        FilledButton.icon(
          onPressed: _addVehicle,
          icon: const Icon(Icons.add),
          label: Text(AppLocalization.t('Add Vehicle')),
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
                labelText: AppLocalization.t('Search Vehicle'),
                hintText: AppLocalization.t('Registration number...'),
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
                labelText: AppLocalization.t('Status'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'All',
                  child: Text(AppLocalization.t('All Statuses')),
                ),
                DropdownMenuItem(
                  value: 'Active',
                  child: Text(AppLocalization.t('Active')),
                ),
                DropdownMenuItem(
                  value: 'Inactive',
                  child: Text(AppLocalization.t('Inactive')),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _statusFilter = value;
                  _currentPage = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<T> _pageItems<T>(List<T> items) {
    final maxPage = items.isEmpty ? 1 : (items.length / _rowsPerPage).ceil();
    if (_currentPage > maxPage) _currentPage = maxPage;
    final start = (_currentPage - 1) * _rowsPerPage;
    if (start >= items.length) return <T>[];
    final end = (start + _rowsPerPage).clamp(0, items.length).toInt();
    return items.sublist(start, end);
  }

  Widget _pagination(int totalItems) {
    return PaginationFooter(
      currentPage: _currentPage,
      rowsPerPage: _rowsPerPage,
      totalItems: totalItems,
      onPageChanged: (page) => setState(() => _currentPage = page),
      onRowsPerPageChanged: (value) => setState(() {
        _rowsPerPage = value;
        _currentPage = 1;
      }),
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
          return Center(
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

                          columns: [
                            DataColumn(
                              label: Text(AppLocalization.t('REGISTRATION')),
                            ),
                            DataColumn(
                              label: Text(AppLocalization.t('MANUFACTURER')),
                            ),
                            DataColumn(label: Text(AppLocalization.t('MODEL'))),
                            DataColumn(label: Text(AppLocalization.t('UNIT'))),
                            DataColumn(label: Text(AppLocalization.t('YEAR'))),
                            DataColumn(
                              label: Text(AppLocalization.t('STATUS')),
                            ),
                            DataColumn(
                              label: Text(AppLocalization.t('COMPLIANCE')),
                            ),
                            DataColumn(
                              label: Text(AppLocalization.t('ACTIONS')),
                            ),
                          ],

                          rows: _pageItems(vehicles).map((vehicle) {
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
                                // UNIT
                                // =================================
                                DataCell(Text(vehicle.unit == 0 ? '-' : _formatUnit(vehicle.unit))),

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
                                        tooltip: AppLocalization.t('View'),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _viewVehicle(vehicle);
                                        },
                                      ),
                                      IconButton(
                                        tooltip: AppLocalization.t('Edit'),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _editVehicle(vehicle.id!);
                                        },
                                      ),
                                      if (context.watch<AuthProvider>().isAdmin)
                                        IconButton(
                                          tooltip: AppLocalization.t('Delete'),
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
              _pagination(vehicles.length),
            ],
          ),
        );
      },
    );
  }

  String _formatUnit(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

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
        message: expiry ?? AppLocalization.t('Not configured'),
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

  // Widget _buildFooter(int count) {
  //   return Container(
  //     height: 56,
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     decoration: const BoxDecoration(
  //       color: Color(0xFFF3F4F6),
  //       border: Border(top: BorderSide(color: Color(0xFFBECABC))),
  //     ),
  //     child: Row(
  //       children: [
  //         Text(
  //           'Showing $count entries',
  //           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  //         ),

  //         const Spacer(),

  //         IconButton(onPressed: null, icon: const Icon(Icons.chevron_left)),

  //         Container(
  //           width: 32,
  //           height: 32,
  //           alignment: Alignment.center,
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF00652C),
  //             borderRadius: BorderRadius.circular(6),
  //           ),
  //           child: const Text(
  //             '1',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),

  //         IconButton(onPressed: null, icon: const Icon(Icons.chevron_right)),
  //       ],
  //     ),
  //   );
  // }

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
      child: Center(
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
              AppLocalization.t('No transport vehicles found'),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            SizedBox(height: 6),

            Text(
              AppLocalization.t('Add a vehicle to your fleet.'),
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

          Text(
            AppLocalization.t('Unable to load transport vehicles'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 8),

          Text(error),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: () {
              context.read<TransportProvider>().loadVehicles();
            },
            child: Text(AppLocalization.t('Retry')),
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

  Future<void> _viewVehicle(TransportModel item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TransportDetailsDialog(
        title: AppLocalization.t('Transport Details'),
        children: [
          _detail(AppLocalization.t('Registration'), item.registrationNumber),
          _detail(AppLocalization.t('Manufacturer'), item.manufacturerName),
          _detail(AppLocalization.t('Model'), item.modelName),
          _detail(AppLocalization.t('Unit'), item.unit == 0 ? '-' : _formatUnit(item.unit)),
          _detail(AppLocalization.t('Manufacturing Year'), item.manufacturingYear?.toString()),
          _detail(AppLocalization.t('Owner Name'), item.ownerName),
          _detail(AppLocalization.t('Permanent Address'), item.permanentAddress),
          _detail(AppLocalization.t('Chassis Number'), item.vehicleChasiNumber),
          _detail(AppLocalization.t('Engine Number'), item.vehicleEngineNumber),
          _detail(AppLocalization.t('Color'), item.color),
          _detail(AppLocalization.t('Insurance Company'), item.insuranceCompany),
          _detail(AppLocalization.t('Emission Standard'), item.emissionStandard),
          _detail(AppLocalization.t('Insurance Expiry'), item.insuranceExpiry),
          _detail(AppLocalization.t('FC Expiry'), item.fcExpiry),
          _detail(AppLocalization.t('Permit Expiry'), item.permitExpiry),
          _detail(AppLocalization.t('Tax Expiry'), item.taxExpiry),
          _detail(AppLocalization.t('Status'), item.status ? AppLocalization.t('Active') : AppLocalization.t('Inactive')),
        ],
      ),
    );
  }

  Widget _detail(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 155, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF68717D)))),
      const SizedBox(width: 12), Expanded(child: Text(value == null || value.trim().isEmpty ? '-' : value)),
    ]),
  );


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
          title: Text(AppLocalization.t('Delete Vehicle?')),
          content: Text(
            AppLocalization.t(
              'Are you sure you want to delete this transport vehicle?',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(AppLocalization.t('Cancel')),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(AppLocalization.t('Delete')),
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
          success ? AppLocalization.t('Vehicle deleted successfully') : AppLocalization.t('Failed to delete vehicle'),
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
            AppConfig.appName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          // ======================================================
          // SERVICE NOTIFICATION
          // ======================================================
          Consumer<ServiceNotificationProvider>(
            builder: (context, notificationProvider, _) {
              final alertCount = notificationProvider.alertCount;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: AppLocalization.t('Service Notifications'),
                    onPressed: () {
                      handleMenuTap(7, context: context);
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 23),
                  ),

                  // Badge
                  if (alertCount > 0)
                    Positioned(
                      right: 5,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD93025),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            alertCount > 99 ? '99+' : '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TransportDetailsDialog extends StatelessWidget {
  final String title; final List<Widget> children;
  const _TransportDetailsDialog({required this.title, required this.children});
  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(width: 620, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: children))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalization.t('Close')))],
  );
}
