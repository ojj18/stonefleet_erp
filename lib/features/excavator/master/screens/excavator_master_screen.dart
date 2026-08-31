import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../providers/excavator_provider.dart';
import 'excavator_master_add_edit_screen.dart';

class ExcavatorMasterScreen extends StatefulWidget {
  const ExcavatorMasterScreen({super.key});

  @override
  State<ExcavatorMasterScreen> createState() => _ExcavatorMasterScreenState();
}

class _ExcavatorMasterScreenState extends State<ExcavatorMasterScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExcavatorProvider>().loadExcavators();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 1,
            onMenuTap: (index) {
              handleMenuTap(index, context: context);
            },
          ),
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
                'Excavator Master',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage registered excavators across the fleet.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),
        // OutlinedButton.icon(
        //   onPressed: () {},
        //   icon: const Icon(Icons.download_outlined),
        //   label: const Text('Export'),
        // ),
        // const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _addExcavator,
          icon: const Icon(Icons.add),
          label: const Text('Add Excavator'),
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
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search Machine',
                hintText: 'Registration number...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
    return Consumer<ExcavatorProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00652C)),
          );
        }

        if (provider.error != null) {
          return _buildError(provider.error!);
        }

        final excavators = _filteredExcavators(provider.excavators);

        if (excavators.isEmpty) {
          return _buildEmpty();
        }

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
                          rows: excavators.map((excavator) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    excavator.registrationNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                DataCell(
                                  Text(excavator.manufacturerName ?? '-'),
                                ),

                                DataCell(Text(excavator.modelName ?? '-')),

                                DataCell(
                                  Text('${excavator.manufacturingYear ?? '-'}'),
                                ),

                                DataCell(_statusChip(excavator.status)),

                                DataCell(_complianceStatus(excavator)),

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
                                          _editExcavator(excavator.id!);
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
                                          _deleteExcavator(excavator.id!);
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

              _buildFooter(excavators.length),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  List _filteredExcavators(List excavators) {
    final query = _searchController.text.trim().toLowerCase();

    return excavators.where((excavator) {
      final matchesSearch =
          query.isEmpty ||
          excavator.registrationNumber.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Active' && excavator.status) ||
          (_statusFilter == 'Inactive' && !excavator.status);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ============================================================
  // STATUS
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

  Widget _complianceStatus(dynamic excavator) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _complianceDot(excavator.insuranceExpiry),
        _complianceDot(excavator.fcExpiry),
        _complianceDot(excavator.permitExpiry),
        _complianceDot(excavator.taxExpiry),
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
              Icons.precision_manufacturing_outlined,
              size: 52,
              color: Color(0xFF6F7A6E),
            ),
            SizedBox(height: 12),
            Text(
              'No excavators found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Add an excavator to your fleet.',
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
            'Unable to load excavators',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              context.read<ExcavatorProvider>().loadExcavators();
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

  Future<void> _addExcavator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExcavatorMasterAddEditScreen()),
    );

    if (result == true && mounted) {
      await context.read<ExcavatorProvider>().loadExcavators();
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editExcavator(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExcavatorMasterAddEditScreen(excavatorId: id),
      ),
    );

    if (result == true && mounted) {
      await context.read<ExcavatorProvider>().loadExcavators();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteExcavator(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Excavator?'),
          content: const Text(
            'Are you sure you want to delete this excavator?',
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

    if (confirmed != true || !mounted) return;

    final success = await context.read<ExcavatorProvider>().deleteExcavator(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Excavator deleted successfully'
              : 'Failed to delete excavator',
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
