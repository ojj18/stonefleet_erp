import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../app/app_config.dart';
import '../../../data/services/report_excel_service.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ReportProvider>().generateReport();
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
            selectedIndex: 8,
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

                            _buildReportTable(),
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

          IconButton(
            tooltip: 'Service Notifications',
            onPressed: () {
              handleMenuTap(7, context: context);
            },
            icon: const Icon(Icons.notifications_outlined, size: 23),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              SizedBox(height: 6),

              Text(
                'View maintenance and service reports for excavators and transport vehicles.',
                style: TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        OutlinedButton.icon(
          onPressed: _exportExcel,
          icon: const Icon(Icons.file_download_outlined, size: 20),
          label: const Text('Export Excel'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(150, 52)),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        final data = provider.reportData;

        final total = data.length;

        final maintenance = provider.reportType == ReportType.maintenance
            ? total
            : 0;

        final service = provider.reportType == ReportType.service ? total : 0;

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Records',
                value: total.toString(),
                icon: Icons.description_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Maintenance',
                value: maintenance.toString(),
                icon: Icons.build_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: _summaryCard(
                title: 'Service',
                value: service.toString(),
                icon: Icons.engineering_outlined,
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
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1E5E9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown<ReportType>(
                      label: 'Report Type',
                      value: provider.reportType,
                      items: const [
                        DropdownMenuItem(
                          value: ReportType.maintenance,
                          child: Text('Maintenance'),
                        ),
                        DropdownMenuItem(
                          value: ReportType.service,
                          child: Text('Service'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.setReportType(value);
                          provider.generateReport();
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildDropdown<EquipmentType>(
                      label: 'Equipment',
                      value: provider.equipmentType,
                      items: const [
                        DropdownMenuItem(
                          value: EquipmentType.all,
                          child: Text('All Equipment'),
                        ),
                        DropdownMenuItem(
                          value: EquipmentType.excavator,
                          child: Text('Excavator'),
                        ),
                        DropdownMenuItem(
                          value: EquipmentType.transport,
                          child: Text('Transport'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.setEquipmentType(value);
                          provider.generateReport();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'From Date',
                      date: provider.fromDate,
                      onTap: () => _selectFromDate(provider),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildDateField(
                      label: 'To Date',
                      date: provider.toDate,
                      onTap: () => _selectToDate(provider),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search registration number, date, remarks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearFilters();
                                  provider.generateReport();
                                },
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  OutlinedButton(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                      provider.generateReport();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 52),
                    ),
                    child: const Text('Clear'),
                  ),

                  const SizedBox(width: 12),

                  FilledButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () {
                            provider.setSearch(_searchController.text);
                            provider.generateReport();
                          },
                    icon: const Icon(Icons.search),
                    label: const Text('Generate'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00652C),
                      minimumSize: const Size(130, 52),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
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
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
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
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 19),
        ),
        child: Text(
          date == null ? 'Select date' : _formatDateTime(date),
          style: TextStyle(
            fontSize: 14,
            color: date == null
                ? const Color(0xFF68717D)
                : const Color(0xFF191C1E),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildReportTable() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.reportData.isEmpty) {
          return _buildLoading();
        }

        if (provider.error != null && provider.reportData.isEmpty) {
          return _buildError(provider.error!);
        }

        if (provider.reportData.isEmpty) {
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
              _buildTableHeader(provider.reportType),

              const Divider(height: 1),

              ...provider.reportData.map(
                (record) => _buildReportRow(record, provider.reportType),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(ReportType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text('EQUIPMENT', style: _headerStyle),
          ),

          const Expanded(
            flex: 2,
            child: Text('REGISTRATION', style: _headerStyle),
          ),

          const Expanded(flex: 2, child: Text('DATE', style: _headerStyle)),

          Expanded(
            flex: 2,
            child: Text(
              type == ReportType.service ? 'METER' : 'DETAILS',
              style: _headerStyle,
            ),
          ),

          const Expanded(
            flex: 2,
            child: Text(
              'COST',
              style: _headerStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(Map<String, dynamic> record, ReportType type) {
    final equipmentType = record['equipment_type']?.toString() ?? '';

    final registration = record['registration_number']?.toString() ?? 'Unknown';

    final date = type == ReportType.service
        ? record['service_date']?.toString() ?? ''
        : record['created_at']?.toString() ?? '';

    final meter = type == ReportType.service
        ? _formatNumber(
            _toDouble(record['current_hour_meter'] ?? record['current_km']),
          )
        : _maintenanceDetails(record);

    final cost = type == ReportType.service
        ? _toDouble(record['item_cost'])
        : _toDouble(record['diesel_expense']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    equipmentType.toLowerCase() == 'excavator'
                        ? Icons.construction_outlined
                        : Icons.local_shipping_outlined,
                    color: const Color(0xFF00652C),
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _capitalize(equipmentType),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(registration, overflow: TextOverflow.ellipsis),
          ),

          Expanded(flex: 2, child: Text(_formatDate(date))),

          Expanded(
            flex: 2,
            child: Text(meter, overflow: TextOverflow.ellipsis),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatCurrency(cost),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PICKERS
  // ============================================================

  Future<void> _selectFromDate(ReportProvider provider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: provider.fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      provider.setFromDate(date);
    }
  }

  Future<void> _selectToDate(ReportProvider provider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: provider.toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      provider.setToDate(date);
    }
  }

  // ============================================================
  // EXPORT
  // ============================================================

  Future<void> _exportExcel() async {
    final provider = context.read<ReportProvider>();

    if (provider.reportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data available to export.')),
      );
      return;
    }

    try {
      final path = await ReportExcelService().exportReport(
        records: provider.reportData,
        reportType: provider.reportType == ReportType.service
            ? 'service'
            : 'maintenance',
        equipmentType: provider.equipmentType == EquipmentType.excavator
            ? 'excavator'
            : provider.equipmentType == EquipmentType.transport
            ? 'transport'
            : 'all',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel exported successfully.\n$path'),
          backgroundColor: const Color(0xFF00652C),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel export failed: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
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
              Icons.description_outlined,
              size: 32,
              color: Color(0xFF00652C),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No report records found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 7),

          const Text(
            'Try changing the report type, equipment or date filters.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF68717D)),
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
            'Unable to load report',
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
              context.read<ReportProvider>().generateReport();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _maintenanceDetails(Map<String, dynamic> record) {
    final remarks = record['remarks']?.toString();

    if (remarks != null && remarks.trim().isNotEmpty) {
      return remarks;
    }

    final loads = record['number_of_loads'];

    if (loads != null) {
      return 'Loads: $loads';
    }

    return '-';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

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

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);
  }
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
