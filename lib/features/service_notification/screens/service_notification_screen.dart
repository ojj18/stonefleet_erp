import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_sidebar.dart';
import '../providers/service_notification_provider.dart';
import '../../../../data/models/service_notification_model.dart';

class ServiceNotificationScreen extends StatefulWidget {
  const ServiceNotificationScreen({super.key});

  @override
  State<ServiceNotificationScreen> createState() =>
      _ServiceNotificationScreenState();
}

class _ServiceNotificationScreenState extends State<ServiceNotificationScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _equipmentFilter = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ServiceNotificationProvider>();

      if (provider.notifications.isEmpty && !provider.isLoading) {
        provider.loadNotifications();
      }
    });

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTERED NOTIFICATIONS
  // ============================================================

  List<ServiceNotificationModel> _filteredNotifications(
    ServiceNotificationProvider provider,
  ) {
    final search = _searchController.text.trim().toLowerCase();

    return provider.notifications.where((item) {
      // Equipment filter
      final equipmentMatches =
          _equipmentFilter == 'All' ||
          (_equipmentFilter == 'Excavator' && item.isExcavator) ||
          (_equipmentFilter == 'Transport' && !item.isExcavator);

      if (!equipmentMatches) {
        return false;
      }

      // Status filter
      final statusMatches =
          _statusFilter == 'All' || item.statusText == _statusFilter;

      if (!statusMatches) {
        return false;
      }

      // Search
      if (search.isEmpty) {
        return true;
      }

      final registration = item.registrationNumber.toLowerCase();

      final spare = item.spareName.toLowerCase();

      final model = item.modelName?.toLowerCase() ?? '';

      return registration.contains(search) ||
          spare.contains(search) ||
          model.contains(search);
    }).toList();
  }

  // ============================================================
  // SORT
  // ============================================================

  List<ServiceNotificationModel> _sortNotifications(
    List<ServiceNotificationModel> items,
  ) {
    final result = List<ServiceNotificationModel>.from(items);

    int severity(ServiceNotificationStatus status) {
      switch (status) {
        case ServiceNotificationStatus.overdue:
          return 0;
        case ServiceNotificationStatus.due:
          return 1;
        case ServiceNotificationStatus.upcoming:
          return 2;
        case ServiceNotificationStatus.serviceNotRecorded:
          return 3;
        case ServiceNotificationStatus.normal:
          return 4;
      }
    }

    result.sort((a, b) => severity(a.status).compareTo(severity(b.status)));

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<ServiceNotificationProvider>(
        builder: (context, provider, _) {
          final filtered = _sortNotifications(_filteredNotifications(provider));

          return SafeArea(
            child: Row(
              children: [
                AppSidebar(
                  selectedIndex: 7,
                  onMenuTap: (index) {
                    handleMenuTap(index, context: context);
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: provider.isLoading
                            ? _buildLoadingState()
                            : provider.error != null
                            ? _buildErrorState(provider)
                            : _buildContent(provider, filtered),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
                    tooltip: 'Service Notifications',
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
  // HEADER
  // ============================================================

  Widget _buildHeader(ServiceNotificationProvider provider) {
    return Row(
      children: [
        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17191C),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Monitor upcoming and overdue service requirements',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Notification count
        _buildHeaderCount(provider),

        const SizedBox(width: 12),

        // Refresh
        OutlinedButton.icon(
          onPressed: provider.isLoading ? null : provider.refresh,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B1D20),
            side: const BorderSide(color: Color(0xFFD9DDE2)),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCount(ServiceNotificationProvider provider) {
    final count = provider.alertCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFFFFF1F1) : const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0 ? const Color(0xFFF4D4D4) : const Color(0xFFD7EBDD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count > 0
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            size: 17,
            color: count > 0
                ? const Color(0xFFD93025)
                : const Color(0xFF18864B),
          ),
          const SizedBox(width: 7),
          Text(
            '$count Requiring Attention',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: count > 0
                  ? const Color(0xFFD93025)
                  : const Color(0xFF18864B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    ServiceNotificationProvider provider,
    List<ServiceNotificationModel> notifications,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(provider),
          const SizedBox(height: 20),
          _buildSummaryCards(provider),

          const SizedBox(height: 20),

          _buildFilterBar(provider),

          const SizedBox(height: 16),

          if (notifications.isEmpty)
            _buildEmptyState()
          else
            ...notifications.map(_buildNotificationCard),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(ServiceNotificationProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'OVERDUE',
            count: provider.overdueCount,
            subtitle: 'Immediate attention required',
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFD93025),
            backgroundColor: const Color(0xFFFFF4F3),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSummaryCard(
            title: 'DUE NOW',
            count: provider.dueCount,
            subtitle: 'Service is due',
            icon: Icons.access_alarm_rounded,
            iconColor: const Color(0xFFE67E22),
            backgroundColor: const Color(0xFFFFF7ED),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSummaryCard(
            title: 'UPCOMING',
            count: provider.upcomingCount,
            subtitle: 'Within warning threshold',
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF3159C9),
            backgroundColor: const Color(0xFFF1F4FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildSummaryCard(
            title: 'NOT RECORDED',
            count: provider.serviceNotRecordedCount,
            subtitle: 'No service history',
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF60656B),
            backgroundColor: const Color(0xFFF1F2F3),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16181B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar(ServiceNotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EA)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _equipmentFilter,
              items: const ['All', 'Excavator', 'Transport'],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _equipmentFilter = value;
                });
              },
              width: 145,
              prefix: 'Equipment',
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _statusFilter,
              items: const [
                'All',
                'Overdue',
                'Due',
                'Upcoming',
                'Service Not Recorded',
                'Normal',
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _statusFilter = value;
                });
              },
              width: 180,
              prefix: 'Status',
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 5,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search registration, model or spare...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          icon: const Icon(Icons.clear_rounded, size: 17),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF6F7F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '${_filteredNotifications(provider).length} notifications',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required double width,
    required String prefix,
  }) {
    return SizedBox(
      // /width: width,
      height: 40,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: prefix,
          labelStyle: const TextStyle(fontSize: 10),
          filled: true,
          fillColor: const Color(0xFFF6F7F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(ServiceNotificationModel item) {
    final statusColor = _statusColor(item.status);

    final statusBackground = _statusBackground(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildEquipmentIcon(item),

          const SizedBox(width: 13),

          SizedBox(width: 155, child: _buildEquipmentInfo(item)),

          const SizedBox(width: 14),

          _buildMetric('Spare Part', item.spareName),

          _buildMetric(
            'Last Service',
            item.lastServiceMeter == null
                ? 'Not Recorded'
                : _formatMeter(item.lastServiceMeter!, item.isExcavator),
          ),

          _buildMetric(
            'Current Meter',
            _formatMeter(item.currentMeter, item.isExcavator),
          ),

          _buildMetric(
            'Next Service',
            item.nextServiceMeter == null
                ? '—'
                : _formatMeter(item.nextServiceMeter!, item.isExcavator),
          ),

          Expanded(
            child: _buildStatusColumn(item, statusColor, statusBackground),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EQUIPMENT ICON
  // ============================================================

  Widget _buildEquipmentIcon(ServiceNotificationModel item) {
    final color = item.isExcavator
        ? const Color(0xFF198754)
        : const Color(0xFF3159C9);

    final background = item.isExcavator
        ? const Color(0xFFEAF6EE)
        : const Color(0xFFEEF2FF);

    IconData icon;

    if (item.status == ServiceNotificationStatus.serviceNotRecorded) {
      icon = Icons.help_outline_rounded;
    } else if (item.isExcavator) {
      icon = Icons.precision_manufacturing_outlined;
    } else {
      icon = Icons.local_shipping_outlined;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: item.status == ServiceNotificationStatus.serviceNotRecorded
            ? const Color(0xFFF0F1F2)
            : background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 19,
        color: item.status == ServiceNotificationStatus.serviceNotRecorded
            ? const Color(0xFF64686D)
            : color,
      ),
    );
  }

  // ============================================================
  // EQUIPMENT INFO
  // ============================================================

  Widget _buildEquipmentInfo(ServiceNotificationModel item) {
    final type = item.isExcavator ? 'EXCAVATOR' : 'TRANSPORT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            color: item.isExcavator
                ? const Color(0xFF198754)
                : const Color(0xFF3159C9),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.registrationNumber,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1D20),
          ),
        ),
        if (item.modelName != null && item.modelName!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            item.modelName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // METRIC
  // ============================================================

  Widget _buildMetric(String label, String value) {
    return SizedBox(
      width: 100,
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF25282C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusColumn(
    ServiceNotificationModel item,
    Color color,
    Color background,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(item),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          _statusDescription(item),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _statusLabel(ServiceNotificationModel item) {
    switch (item.status) {
      case ServiceNotificationStatus.overdue:
        return 'OVERDUE';

      case ServiceNotificationStatus.due:
        return 'SERVICE DUE';

      case ServiceNotificationStatus.upcoming:
        return 'UPCOMING';

      case ServiceNotificationStatus.serviceNotRecorded:
        return 'SERVICE NOT RECORDED';

      case ServiceNotificationStatus.normal:
        return 'NORMAL';
    }
  }

  String _statusDescription(ServiceNotificationModel item) {
    switch (item.status) {
      case ServiceNotificationStatus.overdue:
        final amount = item.remaining?.abs() ?? 0;

        return '${_formatNumber(amount)} '
            '${item.meterUnit} overdue';

      case ServiceNotificationStatus.due:
        return 'Service is due now';

      case ServiceNotificationStatus.upcoming:
        final amount = item.remaining ?? 0;

        return '${_formatNumber(amount)} '
            '${item.meterUnit} remaining';

      case ServiceNotificationStatus.serviceNotRecorded:
        return item.currentMeter > 0
            ? 'Current: ${_formatNumber(item.currentMeter)} '
                  '${item.meterUnit}'
            : 'No service history';

      case ServiceNotificationStatus.normal:
        final amount = item.remaining ?? 0;

        return '${_formatNumber(amount)} '
            '${item.meterUnit} remaining';
    }
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _statusColor(ServiceNotificationStatus status) {
    switch (status) {
      case ServiceNotificationStatus.overdue:
        return const Color(0xFFD93025);

      case ServiceNotificationStatus.due:
        return const Color(0xFFE67E22);

      case ServiceNotificationStatus.upcoming:
        return const Color(0xFF3159C9);

      case ServiceNotificationStatus.serviceNotRecorded:
        return const Color(0xFF64686D);

      case ServiceNotificationStatus.normal:
        return const Color(0xFF198754);
    }
  }

  Color _statusBackground(ServiceNotificationStatus status) {
    switch (status) {
      case ServiceNotificationStatus.overdue:
        return const Color(0xFFFFEEEE);

      case ServiceNotificationStatus.due:
        return const Color(0xFFFFF3E6);

      case ServiceNotificationStatus.upcoming:
        return const Color(0xFFEEF2FF);

      case ServiceNotificationStatus.serviceNotRecorded:
        return const Color(0xFFF0F1F2);

      case ServiceNotificationStatus.normal:
        return const Color(0xFFEAF6EE);
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EA)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EE),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 30,
              color: Color(0xFF198754),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'No service notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'All scheduled services are currently up to date.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: List.generate(
          8,
          (index) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE6E8EB)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  _SkeletonBox(width: 38, height: 38),
                  SizedBox(width: 14),
                  _SkeletonBox(width: 150, height: 35),
                  Spacer(),
                  _SkeletonBox(width: 100, height: 35),
                  SizedBox(width: 20),
                  _SkeletonBox(width: 100, height: 35),
                  SizedBox(width: 20),
                  _SkeletonBox(width: 110, height: 35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState(ServiceNotificationProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFD93025),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load service notifications',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  String _formatMeter(double value, bool isExcavator) {
    final number = _formatNumber(value);

    return '$number ${isExcavator ? 'Hrs' : 'KM'}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

// ============================================================
// SKELETON BOX
// ============================================================

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0F2),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
