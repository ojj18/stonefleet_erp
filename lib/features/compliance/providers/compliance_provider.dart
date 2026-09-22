import 'package:flutter/foundation.dart';

import '../models/compliance_model.dart';
import '../repositories/compliance_repository.dart';

enum ComplianceEquipmentFilter { all, excavator, transport }

enum ComplianceTypeFilter { all, insurance, fc, permit, tax }

enum ComplianceStatusFilter { all, valid, dueSoon, expired, notConfigured }

class ComplianceProvider extends ChangeNotifier {
  final ComplianceRepository _repository = ComplianceRepository();

  List<ComplianceModel> _allData = [];
  List<ComplianceModel> _filteredData = [];

  bool _isLoading = false;
  String? _error;

  String _search = '';

  ComplianceEquipmentFilter _equipmentFilter = ComplianceEquipmentFilter.all;

  ComplianceTypeFilter _complianceTypeFilter = ComplianceTypeFilter.all;

  ComplianceStatusFilter _statusFilter = ComplianceStatusFilter.all;

  List<ComplianceModel> get data => _filteredData;

  bool get isLoading => _isLoading;

  String? get error => _error;

  ComplianceEquipmentFilter get equipmentFilter => _equipmentFilter;

  ComplianceTypeFilter get complianceTypeFilter => _complianceTypeFilter;

  ComplianceStatusFilter get statusFilter => _statusFilter;

  int get totalAssets => _allData.length;

  int get validCount => _allData
      .where((item) => item.overallStatus == ComplianceStatus.valid)
      .length;

  int get dueSoonCount => _allData
      .where((item) => item.overallStatus == ComplianceStatus.dueSoon)
      .length;

  int get expiredCount => _allData
      .where((item) => item.overallStatus == ComplianceStatus.expired)
      .length;

  int get notConfiguredCount => _allData
      .where((item) => item.overallStatus == ComplianceStatus.notConfigured)
      .length;

  Future<void> loadCompliance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allData = await _repository.getAllCompliance();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      _filteredData = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value.trim().toLowerCase();
  }

  void setEquipmentFilter(ComplianceEquipmentFilter value) {
    _equipmentFilter = value;
  }

  void setComplianceTypeFilter(ComplianceTypeFilter value) {
    _complianceTypeFilter = value;
  }

  void setStatusFilter(ComplianceStatusFilter value) {
    _statusFilter = value;
  }

  void applyFilters() {
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _search = '';

    _equipmentFilter = ComplianceEquipmentFilter.all;

    _complianceTypeFilter = ComplianceTypeFilter.all;

    _statusFilter = ComplianceStatusFilter.all;

    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    Iterable<ComplianceModel> result = _allData;

    // Equipment filter
    if (_equipmentFilter == ComplianceEquipmentFilter.excavator) {
      result = result.where(
        (item) => item.equipmentType == ComplianceEquipmentType.excavator,
      );
    } else if (_equipmentFilter == ComplianceEquipmentFilter.transport) {
      result = result.where(
        (item) => item.equipmentType == ComplianceEquipmentType.transport,
      );
    }

    // Search
    if (_search.isNotEmpty) {
      result = result.where((item) {
        final registration = item.registrationNumber?.toLowerCase() ?? '';

        final manufacturer = item.manufacturerName?.toLowerCase() ?? '';

        final model = item.modelName?.toLowerCase() ?? '';

        return registration.contains(_search) ||
            manufacturer.contains(_search) ||
            model.contains(_search);
      });
    }

    // Status filter
    if (_statusFilter != ComplianceStatusFilter.all) {
      result = result.where((item) => _matchesStatusFilter(item));
    }

    // Compliance type filter
    if (_complianceTypeFilter != ComplianceTypeFilter.all) {
      result = result.where((item) => _matchesComplianceType(item));
    }

    _filteredData = result.toList();
  }

  bool _matchesStatusFilter(ComplianceModel item) {
    final status = item.overallStatus;

    switch (_statusFilter) {
      case ComplianceStatusFilter.valid:
        return status == ComplianceStatus.valid;

      case ComplianceStatusFilter.dueSoon:
        return status == ComplianceStatus.dueSoon;

      case ComplianceStatusFilter.expired:
        return status == ComplianceStatus.expired;

      case ComplianceStatusFilter.notConfigured:
        return status == ComplianceStatus.notConfigured;

      case ComplianceStatusFilter.all:
        return true;
    }
  }

  bool _matchesComplianceType(ComplianceModel item) {
    ComplianceStatus status;

    switch (_complianceTypeFilter) {
      case ComplianceTypeFilter.insurance:
        status = item.getStatus(item.insuranceExpiry);
        break;

      case ComplianceTypeFilter.fc:
        status = item.getStatus(item.fcExpiry);
        break;

      case ComplianceTypeFilter.permit:
        status = item.getStatus(item.permitExpiry);
        break;

      case ComplianceTypeFilter.tax:
        status = item.getStatus(item.taxExpiry);
        break;

      case ComplianceTypeFilter.all:
        return true;
    }

    if (_statusFilter == ComplianceStatusFilter.all) {
      return true;
    }

    return _statusMatchesFilter(status);
  }

  bool _statusMatchesFilter(ComplianceStatus status) {
    switch (_statusFilter) {
      case ComplianceStatusFilter.valid:
        return status == ComplianceStatus.valid;

      case ComplianceStatusFilter.dueSoon:
        return status == ComplianceStatus.dueSoon;

      case ComplianceStatusFilter.expired:
        return status == ComplianceStatus.expired;

      case ComplianceStatusFilter.notConfigured:
        return status == ComplianceStatus.notConfigured;

      case ComplianceStatusFilter.all:
        return true;
    }
  }
}
