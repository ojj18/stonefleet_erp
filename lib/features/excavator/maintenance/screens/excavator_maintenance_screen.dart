import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/excavator_maintenance_model.dart';
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
  final TextEditingController _searchController = TextEditingController();

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
                'Excavator Maintenance',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Track daily excavator operation, fuel usage and maintenance activities.',
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
                title: 'Total Records',
                value: records.length.toString(),
                icon: Icons.receipt_long_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Working Hours',
                value: _formatNumber(totalHours),
                icon: Icons.timer_outlined,
                suffix: ' hrs',
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Diesel Used',
                value: _formatNumber(totalDiesel),
                icon: Icons.local_gas_station_outlined,
                suffix: ' L',
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
                hintText: 'Search operator, excavator ID or remarks...',
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
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedShift,
              decoration: InputDecoration(
                labelText: 'Shift',
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Shifts')),
                DropdownMenuItem(value: 'Day', child: Text('Day')),
                DropdownMenuItem(value: 'Night', child: Text('Night')),
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
            tooltip: 'Refresh',
            onPressed: () {
              context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
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

  Widget _buildTableHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: const Color(0xFFF8F9FB),
      child: Row(
        children: [
          _headerCell('DATE', width: 105),

          _headerCell('EXCAVATOR', width: 120),

          _headerCell('OPERATOR', width: 150),

          _headerCell('SHIFT', width: 85),

          _headerCell('HOURS', width: 90),

          _headerCell('LOADS', width: 80),

          _headerCell('DIESEL', width: 100),

          _headerCell('EXPENSE', width: 110),

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

  Widget _buildTableRow(ExcavatorMaintenanceModel record) {
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

            SizedBox(width: 120, child: _machineBadge(record.excavatorId)),

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
              width: 100,
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
  // MACHINE BADGE
  // ============================================================

  Widget _machineBadge(int excavatorId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'EXC-$excavatorId',
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
    return records.where((record) {
      final operator = record.operatorName?.toLowerCase() ?? '';

      final remarks = record.remarks?.toLowerCase() ?? '';

      final excavator = 'exc-${record.excavatorId}';

      final matchesSearch =
          _searchQuery.isEmpty ||
          operator.contains(_searchQuery) ||
          remarks.contains(_searchQuery) ||
          excavator.contains(_searchQuery) ||
          record.excavatorId.toString().contains(_searchQuery);

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
  //         title: const Text('Select Excavator'),
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
  //                   labelText: 'Excavator ID',
  //                   hintText: 'Example: 1',
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
  //             child: const Text('Cancel'),
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
  //             child: const Text('Continue'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // ============================================================
  // EDIT
  // ============================================================

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

    final provider = context.read<ExcavatorMaintenanceProvider>();

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
              Icons.precision_manufacturing_outlined,
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
            'Add your first excavator maintenance record to get started.',
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
              context.read<ExcavatorMaintenanceProvider>().loadMaintenance();
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

      final day = date.day.toString().padLeft(2, '0');

      final month = date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    } catch (_) {
      return value;
    }
  }
}
