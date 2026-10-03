import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../app/app_config.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../data/services/report_excel_service.dart';
import '../models/compliance_model.dart';
import '../providers/compliance_provider.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplianceProvider>().loadCompliance();
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
            selectedIndex: 9,
            onMenuTap: (index) {
              handleMenuTap(index, context: context);
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
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
            AppConfig.appName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20242A),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
            color: const Color(0xFF68717D),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              size: 19,
              color: Color(0xFF00652C),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.t('Admin'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                AppLocalization.t('Administrator'),
                style: TextStyle(fontSize: 10, color: Color(0xFF68717D)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ComplianceProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(provider),
                  const SizedBox(height: 24),
                  _buildSummaryCards(provider),
                  const SizedBox(height: 24),
                  _buildFilters(provider),
                  const SizedBox(height: 24),
                  _buildTableSection(provider),
                  const SizedBox(height: 24),
                  _buildInfoCards(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(ComplianceProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.t('Compliance'),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20242A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                AppLocalization.t(
                  'Monitor insurance, FC, permit and tax expiry status across your fleet.',
                ),
                style: TextStyle(fontSize: 13, color: Color(0xFF68717D)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => provider.loadCompliance(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(AppLocalization.t('Refresh')),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: provider.isLoading || provider.data.isEmpty
              ? null
              : () => _exportCompliance(),
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: Text(AppLocalization.t('Export Compliance Report')),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ComplianceProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            AppLocalization.t('Total Assets'),
            provider.totalAssets,
            Icons.directions_car_outlined,
            const Color(0xFF20242A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            AppLocalization.t('Valid'),
            provider.validCount,
            Icons.check_circle_outline,
            const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            AppLocalization.t('Due Soon'),
            provider.dueSoonCount,
            Icons.schedule_outlined,
            const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            AppLocalization.t('Expired'),
            provider.expiredCount,
            Icons.error_outline,
            const Color(0xFFD32F2F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            AppLocalization.t('Not Configured'),
            provider.notConfiguredCount,
            Icons.remove_circle_outline,
            const Color(0xFF68717D),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, int value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF68717D)),
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20242A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ComplianceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.t('Filters'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20242A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    provider.setSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalization.t(
                      'Search registration, manufacturer or model',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearch('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _equipmentDropdown(provider)),
              const SizedBox(width: 12),
              Expanded(child: _complianceDropdown(provider)),
              const SizedBox(width: 12),
              Expanded(child: _statusDropdown(provider)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                  setState(() {});
                },
                child: Text(AppLocalization.t('Clear')),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: provider.applyFilters,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00652C),
                ),
                child: Text(AppLocalization.t('Apply Filters')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _equipmentDropdown(ComplianceProvider provider) {
    return DropdownButtonFormField<ComplianceEquipmentFilter>(
      initialValue: provider.equipmentFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppLocalization.t('Equipment Type'),
      ),
      items: [
        DropdownMenuItem(
          value: ComplianceEquipmentFilter.all,
          child: Text(AppLocalization.t('All Equipment')),
        ),
        DropdownMenuItem(
          value: ComplianceEquipmentFilter.excavator,
          child: Text(AppLocalization.t('Excavator')),
        ),
        DropdownMenuItem(
          value: ComplianceEquipmentFilter.transport,
          child: Text(AppLocalization.t('Transport')),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          provider.setEquipmentFilter(value);
        }
      },
    );
  }

  Widget _complianceDropdown(ComplianceProvider provider) {
    return DropdownButtonFormField<ComplianceTypeFilter>(
      initialValue: provider.complianceTypeFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: AppLocalization.t('Compliance Type'),
      ),
      items: [
        DropdownMenuItem(
          value: ComplianceTypeFilter.all,
          child: Text(AppLocalization.t('All Compliance')),
        ),
        DropdownMenuItem(
          value: ComplianceTypeFilter.insurance,
          child: Text(AppLocalization.t('Insurance')),
        ),
        DropdownMenuItem(
          value: ComplianceTypeFilter.fc,
          child: Text(AppLocalization.t('FC')),
        ),
        DropdownMenuItem(
          value: ComplianceTypeFilter.permit,
          child: Text(AppLocalization.t('Permit')),
        ),
        DropdownMenuItem(
          value: ComplianceTypeFilter.tax,
          child: Text(AppLocalization.t('Tax')),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          provider.setComplianceTypeFilter(value);
        }
      },
    );
  }

  Widget _statusDropdown(ComplianceProvider provider) {
    return DropdownButtonFormField<ComplianceStatusFilter>(
      initialValue: provider.statusFilter,
      isExpanded: true,
      decoration: InputDecoration(labelText: AppLocalization.t('Status')),
      items: [
        DropdownMenuItem(
          value: ComplianceStatusFilter.all,
          child: Text(AppLocalization.t('All Status')),
        ),
        DropdownMenuItem(
          value: ComplianceStatusFilter.valid,
          child: Text(AppLocalization.t('Valid')),
        ),
        DropdownMenuItem(
          value: ComplianceStatusFilter.dueSoon,
          child: Text(AppLocalization.t('Due Soon')),
        ),
        DropdownMenuItem(
          value: ComplianceStatusFilter.expired,
          child: Text(AppLocalization.t('Expired')),
        ),
        DropdownMenuItem(
          value: ComplianceStatusFilter.notConfigured,
          child: Text(AppLocalization.t('Not Configured')),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          provider.setStatusFilter(value);
        }
      },
    );
  }

  Widget _buildTableSection(ComplianceProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalization.t('Compliance Overview'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF20242A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        AppLocalization.t(
                          'Track expiry status for all registered assets.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68717D),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${provider.data.length} ${AppLocalization.t('Assets')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF68717D),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE1E5E9)),
          if (provider.isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00652C)),
              ),
            )
          else if (provider.error != null)
            _buildErrorState(provider)
          else if (provider.data.isEmpty)
            _buildEmptyState()
          else
            _buildComplianceTable(provider),
        ],
      ),
    );
  }

  Widget _buildComplianceTable(ComplianceProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        //width: 1500,
        child: Column(
          children: [
            _buildTableHeader(),
            const Divider(height: 1, color: Color(0xFFE1E5E9)),
            ...provider.data.map((item) => _buildTableRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFFAFBFC),
      child: Row(
        children: [
          _headerCell('Equipment', 150),
          _headerCell('Registration', 130),
          _headerCell('Manufacturer / Model', 190),
          _headerCell('Insurance', 125),
          _headerCell('FC', 125),
          _headerCell('Permit', 125),
          _headerCell('Tax', 125),
          _headerCell('Overall Status', 130),
          _headerCell('Actions', 70),
        ],
      ),
    );
  }

  Widget _headerCell(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF68717D),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTableRow(ComplianceModel item) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE1E5E9))),
      ),
      child: Row(
        children: [
          _equipmentCell(item),
          _registrationCell(item),
          _manufacturerCell(item),
          _complianceCell(item.insuranceExpiry),
          _complianceCell(item.fcExpiry),
          _complianceCell(item.permitExpiry),
          _complianceCell(item.taxExpiry),
          _overallStatusCell(item),
          _actionCell(item),
        ],
      ),
    );
  }

  Widget _equipmentCell(ComplianceModel item) {
    final isExcavator = item.equipmentType == ComplianceEquipmentType.excavator;

    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isExcavator
                  ? Icons.agriculture_outlined
                  : Icons.local_shipping_outlined,
              size: 18,
              color: const Color(0xFF00652C),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            item.equipmentLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20242A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registrationCell(ComplianceModel item) {
    final registration = item.registrationNumber?.trim();

    return SizedBox(
      width: 130,
      child: Text(
        registration == null || registration.isEmpty
            ? 'Not Registered'
            : registration,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: registration == null || registration.isEmpty
              ? const Color(0xFF9AA1A9)
              : const Color(0xFF20242A),
        ),
      ),
    );
  }

  Widget _manufacturerCell(ComplianceModel item) {
    final manufacturer = item.manufacturerName?.trim();

    final model = item.modelName?.trim();

    final manufacturerText = manufacturer == null || manufacturer.isEmpty
        ? '—'
        : manufacturer;

    final modelText = model == null || model.isEmpty ? '—' : model;

    return SizedBox(
      width: 190,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            manufacturerText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF20242A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            modelText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF68717D)),
          ),
        ],
      ),
    );
  }

  Widget _complianceCell(DateTime? expiryDate) {
    final status = _statusForDate(expiryDate);

    return SizedBox(width: 125, child: _statusContent(status, expiryDate));
  }

  ComplianceStatus _statusForDate(DateTime? date) {
    if (date == null) {
      return ComplianceStatus.notConfigured;
    }

    final today = DateTime.now();

    final todayOnly = DateTime(today.year, today.month, today.day);

    final expiryOnly = DateTime(date.year, date.month, date.day);

    if (expiryOnly.isBefore(todayOnly)) {
      return ComplianceStatus.expired;
    }

    if (!expiryOnly.isAfter(todayOnly.add(const Duration(days: 30)))) {
      return ComplianceStatus.dueSoon;
    }

    return ComplianceStatus.valid;
  }

  Widget _statusContent(ComplianceStatus status, DateTime? date) {
    String label;
    Color color;
    Color background;

    switch (status) {
      case ComplianceStatus.valid:
        label = AppLocalization.t('Valid');
        color = const Color(0xFF2E7D32);
        background = const Color(0xFFE8F5E9);
        break;

      case ComplianceStatus.dueSoon:
        label = AppLocalization.t('Due Soon');
        color = const Color(0xFFD97706);
        background = const Color(0xFFFFF7E6);
        break;

      case ComplianceStatus.expired:
        label = AppLocalization.t('Expired');
        color = const Color(0xFFD32F2F);
        background = const Color(0xFFFFEBEE);
        break;

      case ComplianceStatus.notConfigured:
        label = AppLocalization.t('Not Configured');
        color = const Color(0xFF68717D);
        background = const Color(0xFFF1F3F5);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (date != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 10, color: Color(0xFF68717D)),
          ),
        ],
      ],
    );
  }

  Widget _overallStatusCell(ComplianceModel item) {
    final status = item.overallStatus;

    String label;
    Color color;
    Color background;

    switch (status) {
      case ComplianceStatus.valid:
        label = AppLocalization.t('Valid');
        color = const Color(0xFF2E7D32);
        background = const Color(0xFFE8F5E9);
        break;

      case ComplianceStatus.dueSoon:
        label = AppLocalization.t('Due Soon');
        color = const Color(0xFFD97706);
        background = const Color(0xFFFFF7E6);
        break;

      case ComplianceStatus.expired:
        label = AppLocalization.t('Expired');
        color = const Color(0xFFD32F2F);
        background = const Color(0xFFFFEBEE);
        break;

      case ComplianceStatus.notConfigured:
        label = AppLocalization.t('Not Configured');
        color = const Color(0xFF68717D);
        background = const Color(0xFFF1F3F5);
        break;
    }

    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCell(ComplianceModel item) {
    return SizedBox(
      width: 70,
      child: IconButton(
        tooltip: AppLocalization.t('View'),
        onPressed: () {
          _showComplianceDetails(item);
        },
        icon: const Icon(Icons.visibility_outlined, size: 18),
        color: const Color(0xFF68717D),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.fact_check_outlined, size: 46, color: Color(0xFF9AA1A9)),
            SizedBox(height: 12),
            Text(
              AppLocalization.t('No compliance records found'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF20242A),
              ),
            ),
            SizedBox(height: 5),
            Text(
              AppLocalization.t(
                'Try changing your filters or add compliance information.',
              ),
              style: TextStyle(fontSize: 12, color: Color(0xFF68717D)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ComplianceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 42, color: Color(0xFFD32F2F)),
            const SizedBox(height: 10),
            Text(
              AppLocalization.t('Unable to load compliance data'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalization.t(provider.error ?? 'Unknown error'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF68717D)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: provider.loadCompliance,
              icon: const Icon(Icons.refresh, size: 17),
              label: Text(AppLocalization.t('Retry')),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplianceDetails(ComplianceModel item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '${AppLocalization.t(item.equipmentLabel)} ${AppLocalization.t('Compliance')}',
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogComplianceRow('Insurance', item.insuranceExpiry),
                _dialogComplianceRow('FC', item.fcExpiry),
                _dialogComplianceRow('Permit', item.permitExpiry),
                _dialogComplianceRow('Tax', item.taxExpiry),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(AppLocalization.t('Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogComplianceRow(String title, DateTime? expiry) {
    final status = _statusForDate(expiry);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF20242A),
              ),
            ),
          ),
          _statusContent(status, expiry),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            icon: Icons.verified_user_outlined,
            title: AppLocalization.t('Mandatory RTO Compliance'),
            description: AppLocalization.t(
              'Keep insurance, FC, permit and tax information updated for every asset.',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            icon: Icons.notifications_active_outlined,
            title: AppLocalization.t('30-Day Automated Warning'),
            description: AppLocalization.t(
              'Assets approaching expiry within 30 days are marked as Due Soon.',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            icon: Icons.folder_outlined,
            title: AppLocalization.t('Document Archival'),
            description: AppLocalization.t(
              'Maintain accurate compliance dates for operational and audit reference.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF00652C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF20242A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF68717D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCompliance() async {
    final provider = context.read<ComplianceProvider>();

    if (provider.data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.t('No compliance data available to export.'),
          ),
        ),
      );
      return;
    }

    try {
      final records = provider.data.map((item) {
        return {
          'equipment_type': item.equipmentLabel,
          'registration_number': item.registrationNumber ?? 'Not Registered',
          'manufacturer_name': item.manufacturerName ?? '',
          'model_name': item.modelName ?? '',
          'insurance_expiry': item.insuranceExpiry?.toIso8601String(),
          'fc_expiry': item.fcExpiry?.toIso8601String(),
          'permit_expiry': item.permitExpiry?.toIso8601String(),
          'tax_expiry': item.taxExpiry?.toIso8601String(),
          'overall_status': _statusLabel(item.overallStatus),
        };
      }).toList();

      final path = await ReportExcelService().exportComplianceReport(
        records: records,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalization.t('Compliance report exported successfully.')}\n$path',
          ),
          backgroundColor: const Color(0xFF00652C),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.t('Compliance export failed: ') + e.toString(),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  String _statusLabel(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.valid:
        return AppLocalization.t('Valid');

      case ComplianceStatus.dueSoon:
        return AppLocalization.t('Due Soon');

      case ComplianceStatus.expired:
        return AppLocalization.t('Expired');

      case ComplianceStatus.notConfigured:
        return AppLocalization.t('Not Configured');
    }
  }
}
