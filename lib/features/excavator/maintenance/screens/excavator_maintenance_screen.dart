import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_config.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../../data/models/excavator_maintenance_list_model.dart';
import '../../../../data/models/excavator_maintenance_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../service_notification/providers/service_notification_provider.dart';
import '../../master/providers/excavator_provider.dart';
import '../providers/excavator_maintenance_provider.dart';
import 'excavator_maintenance_add_edit_screen.dart';

class ExcavatorMaintenanceScreen extends StatefulWidget {
  const ExcavatorMaintenanceScreen({super.key});

  @override
  State<ExcavatorMaintenanceScreen> createState() =>
      _ExcavatorMaintenanceScreenState();
}

class _ExcavatorMaintenanceScreenState
    extends State<ExcavatorMaintenanceScreen> {
  _ExcavatorMaintenanceScreenState();

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  int _rowsPerPage = 10;

  String _searchQuery = '';
  String _selectedShift = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
    });

    _searchController.addListener(() {
      setState(() {
        _currentPage = 1;
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
            selectedIndex: 2,
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
            AppConfig.appName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.notifications_outlined),
          // ),
          const SizedBox(width: 8),
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
              Text(
                AppLocalization.t('Excavator Maintenance'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                AppLocalization.t(
                  'Track daily excavator operation, fuel usage and maintenance activities.',
                ),
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        FilledButton.icon(
          onPressed: _openAddScreen,
          icon: const Icon(Icons.add, size: 20),
          label: Text(AppLocalization.t('Add Maintenance')),
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
    return Consumer<ExcavatorMaintenanceProvider>(
      builder: (context, provider, child) {
        final records = provider.records;

        final totalHours = records.fold<double>(
          0,
          (sum, item) => sum + item.totalWorkingHour,
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
                title: AppLocalization.t('Total Records'),
                value: records.length.toString(),
                icon: Icons.receipt_long_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: AppLocalization.t('Working Hours'),
                value: _formatNumber(totalHours),
                icon: Icons.timer_outlined,
                suffix: ' hrs',
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: AppLocalization.t('Diesel Used'),
                value: _formatNumber(totalDiesel),
                icon: Icons.local_gas_station_outlined,
                suffix: ' L',
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: AppLocalization.t('Diesel Expense'),
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
                hintText: AppLocalization.t(
                  'Search operator, excavator ID or remarks...',
                ),
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

          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedShift,
              decoration: InputDecoration(
                labelText: AppLocalization.t('Shift'),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'All',
                  child: Text(AppLocalization.t('All Shifts')),
                ),
                DropdownMenuItem(
                  value: 'Day',
                  child: Text(AppLocalization.t('Day')),
                ),
                DropdownMenuItem(
                  value: 'Night',
                  child: Text(AppLocalization.t('Night')),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedShift = value;
                });
              },
            ),
          ),

          const SizedBox(width: 12),

          IconButton(
            tooltip: AppLocalization.t('Refresh'),
            onPressed: () {
              context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
            },
            icon: const Icon(Icons.refresh),
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

  Widget _buildMaintenanceTable() {
    return Consumer<ExcavatorMaintenanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.records.isEmpty) {
          return _buildLoading();
        }

        if (provider.error != null && provider.records.isEmpty) {
          return _buildError(provider.error!);
        }

        final records = _filteredRecords(provider.records);

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
                _buildTableHeader(records.length),

                const Divider(height: 1),

                ..._pageItems(
                  records,
                ).map((record) => _buildTableRow(record, provider.listRecords)),
                _pagination(records.length),
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

  Widget _buildTableHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: const Color(0xFFF8F9FB),
      child: Row(
        children: [
          _headerCell(AppLocalization.t('DATE'), width: 105),

          _headerCell(AppLocalization.t('EXCAVATOR'), width: 120),

          _headerCell(AppLocalization.t('OPERATOR'), width: 150),

          _headerCell(AppLocalization.t('SHIFT'), width: 85),

          _headerCell(AppLocalization.t('HOURS'), width: 90),

          _headerCell(AppLocalization.t('LOADS'), width: 80),

          _headerCell(AppLocalization.t('DIESEL'), width: 100),

          _headerCell(AppLocalization.t('EXPENSE'), width: 110),

          Expanded(
            child: Text(
              AppLocalization.t('ACTION'),
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

  String _getRegistrationNumber(
    int excavatorId,
    List<ExcavatorMaintenanceListModel> listRecords,
  ) {
    for (final item in listRecords) {
      if (item.excavatorId == excavatorId) {
        return item.registrationNumber;
      }
    }

    return '-';
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  Widget _buildTableRow(
    ExcavatorMaintenanceModel record,
    List<ExcavatorMaintenanceListModel> listRecords,
  ) {
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
            SizedBox(
              width: 105,
              child: Text(
                _formatDate(record.createdAt),
                style: const TextStyle(fontSize: 13, color: Color(0xFF4E5867)),
              ),
            ),

            SizedBox(
              width: 120,
              child: _machineBadge(
                _getRegistrationNumber(record.excavatorId, listRecords),
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                record.operatorName ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            SizedBox(width: 85, child: _shiftBadge(record.shift)),

            SizedBox(
              width: 90,
              child: Text(
                '${_formatNumber(record.totalWorkingHour)} h',
                style: const TextStyle(fontSize: 13),
              ),
            ),

            SizedBox(
              width: 80,
              child: Text(
                record.numberOfLoads.toString(),
                style: const TextStyle(fontSize: 13),
              ),
            ),

            SizedBox(
              width: 150,
              child: Text(
                '${_formatNumber(record.dieselFilled)} L',
                style: const TextStyle(fontSize: 13),
              ),
            ),

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

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: AppLocalization.t('View'),
                    onPressed: () => _viewMaintenance(record),
                    icon: const Icon(Icons.visibility_outlined, size: 19),
                    color: const Color(0xFF00652C),
                  ),
                  IconButton(
                    tooltip: AppLocalization.t('Edit'),
                    onPressed: () => _openEditScreen(record),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: const Color(0xFF00652C),
                  ),
                  if (context.watch<AuthProvider>().isAdmin)
                    IconButton(
                      tooltip: AppLocalization.t('Delete'),
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
  // MACHINE BADGE
  // ============================================================

  Widget _machineBadge(String registrationNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        registrationNumber.isEmpty ? '-' : registrationNumber,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF00652C),
        ),
      ),
    );
  }

  // ============================================================
  // SHIFT BADGE
  // ============================================================

  Widget _shiftBadge(String? shift) {
    if (shift == null || shift.isEmpty) {
      return const Text('-');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        shift,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<ExcavatorMaintenanceModel> _filteredRecords(
    List<ExcavatorMaintenanceModel> records,
  ) {
    final listRecords = context
        .read<ExcavatorMaintenanceProvider>()
        .listRecords;

    return records.where((record) {
      final operator = record.operatorName?.toLowerCase() ?? '';
      final remarks = record.remarks?.toLowerCase() ?? '';

      final registrationNumber = _getRegistrationNumber(
        record.excavatorId,
        listRecords,
      ).toLowerCase();

      final excavatorId = record.excavatorId.toString();

      final matchesSearch =
          _searchQuery.isEmpty ||
          operator.contains(_searchQuery) ||
          remarks.contains(_searchQuery) ||
          registrationNumber.contains(_searchQuery) ||
          excavatorId.contains(_searchQuery);

      final matchesShift =
          _selectedShift == 'All' || record.shift == _selectedShift;

      return matchesSearch && matchesShift;
    }).toList();
  }
  // ============================================================
  // ADD
  // ============================================================

  Future<void> _openAddScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ExcavatorMaintenanceAddEditScreen(),
      ),
    );

    if (!mounted) return;

    await context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
  }

  // ============================================================
  // EXCAVATOR SELECTION
  // ============================================================

  // Future<int?> _showExcavatorSelectionDialog() async {
  //   final controller = TextEditingController();

  //   return showDialog<int>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return AlertDialog(
  //         title: Text(AppLocalization.t('Select Excavator')),
  //         content: SizedBox(
  //           width: 400,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const Text(
  //                 'Enter the excavator ID for this maintenance record.',
  //                 style: TextStyle(color: Color(0xFF68717D)),
  //               ),

  //               const SizedBox(height: 20),

  //               TextField(
  //                 controller: controller,
  //                 keyboardType: TextInputType.number,
  //                 autofocus: true,
  //                 decoration: InputDecoration(
  //                   labelText: AppLocalization.t('Excavator ID'),
  //                   hintText: AppLocalization.t('Example: 1'),
  //                   prefixIcon: const Icon(
  //                     Icons.precision_manufacturing_outlined,
  //                   ),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(dialogContext);
  //             },
  //             child: Text(AppLocalization.t('Cancel')),
  //           ),

  //           FilledButton(
  //             onPressed: () {
  //               final id = int.tryParse(controller.text.trim());

  //               if (id == null || id <= 0) {
  //                 return;
  //               }

  //               Navigator.pop(dialogContext, id);
  //             },
  //             style: FilledButton.styleFrom(
  //               backgroundColor: const Color(0xFF00652C),
  //             ),
  //             child: Text(AppLocalization.t('Continue')),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _viewMaintenance(ExcavatorMaintenanceModel record) async {
    final excavator = await context.read<ExcavatorProvider>().getById(
      record.excavatorId,
    );
    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => _MaintenanceDetailsDialog(
          title: AppLocalization.t('Excavator Maintenance Details'),
          children: [
            _d(AppLocalization.t('Date'), _formatDate(record.createdAt)),
            _d(AppLocalization.t('Excavator'), excavator?.registrationNumber),
            _d(AppLocalization.t('Operator Name'), record.operatorName),
            _d(AppLocalization.t('Shift'), record.shift),
            _d(
              AppLocalization.t('Starting Hour'),
              _formatNumber(record.startingHour),
            ),
            _d(
              AppLocalization.t('Closing Hour'),
              _formatNumber(record.closingHour),
            ),
            _d(
              AppLocalization.t('Total Working Hour'),
              _formatNumber(record.totalWorkingHour),
            ),
            _d(
              AppLocalization.t('Bucket Working Hour'),
              _formatNumber(record.bucketWorkingHour),
            ),
            _d(
              AppLocalization.t('Breaker Working Hour'),
              _formatNumber(record.breakerWorkingHour),
            ),
            _d(
              AppLocalization.t('Total Running Hour'),
              _formatNumber(record.totalRunningHour),
            ),
            _d(
              AppLocalization.t('Number of Loads'),
              record.numberOfLoads.toString(),
            ),
            _d(AppLocalization.t('Units'), _formatNumber(record.units)),
            _d(
              AppLocalization.t('Diesel Filled'),
              '${_formatNumber(record.dieselFilled)} L',
            ),
            _d(
              AppLocalization.t('Diesel Rate'),
              _formatCurrency(record.dieselRate),
            ),
            _d(
              AppLocalization.t('Diesel Expense'),
              _formatCurrency(record.dieselExpense),
            ),
            _d(
              AppLocalization.t('Diesel Consumption (L/H)'),
              _formatNumber(record.dieselExpensePerHour),
            ),
            _d(
              AppLocalization.t('Teeth Set Changed'),
              record.teethSetChanged
                  ? AppLocalization.t('Yes')
                  : AppLocalization.t('No'),
            ),
            _d(AppLocalization.t('Remarks'), record.remarks),
          ],
        ),
      );
    }
  }

  Widget _d(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 175,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF68717D),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value == null || value.trim().isEmpty ? '-' : value),
        ),
      ],
    ),
  );

  Future<void> _openEditScreen(ExcavatorMaintenanceModel record) async {
    if (record.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExcavatorMaintenanceAddEditScreen(maintenance: record),
      ),
    );

    if (!mounted) return;

    await context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(ExcavatorMaintenanceModel record) async {
    if (record.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalization.t('Delete Maintenance Record?')),
          content: Text(
            AppLocalization.t(
              'This maintenance record will be permanently deleted. This action cannot be undone.',
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(AppLocalization.t('Cancel')),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
              ),
              child: Text(AppLocalization.t('Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<ExcavatorMaintenanceProvider>();

    final success = await provider.deleteMaintenance(record.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? AppLocalization.t('Maintenance record deleted.')
              : AppLocalization.t(provider.error ?? 'Unable to delete record.'),
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
              Icons.precision_manufacturing_outlined,
              size: 30,
              color: Color(0xFF00652C),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            AppLocalization.t('No maintenance records found'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 7),

          Text(
            AppLocalization.t(
              AppLocalization.t(
                'Add your first excavator maintenance record to get started.',
              ),
            ),
            style: TextStyle(fontSize: 13, color: Color(0xFF68717D)),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _openAddScreen,
            icon: const Icon(Icons.add),
            label: Text(AppLocalization.t('Add Maintenance')),
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
      child: Center(child: CircularProgressIndicator(color: Color(0xFF00652C))),
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

          Text(
            AppLocalization.t('Unable to load maintenance records'),
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
              context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
            },
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalization.t('Retry')),
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

      final day = date.day.toString().padLeft(2, '0');

      final month = date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }
}

class _MaintenanceDetailsDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _MaintenanceDetailsDialog({
    required this.title,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 580,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalization.t('Close')),
      ),
    ],
  );
}
