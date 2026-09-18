import 'package:flutter/foundation.dart';

import '../../../data/repositories/report_repository.dart';

enum ReportType { maintenance, service }

enum EquipmentType { all, excavator, transport }

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider({ReportRepository? repository})
    : _repository = repository ?? ReportRepository();

  // ============================================================
  // STATE
  // ============================================================

  ReportType _reportType = ReportType.maintenance;
  EquipmentType _equipmentType = EquipmentType.all;

  DateTime? _fromDate;
  DateTime? _toDate;

  String _search = '';

  List<Map<String, dynamic>> _reportData = [];

  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  ReportType get reportType => _reportType;

  EquipmentType get equipmentType => _equipmentType;

  DateTime? get fromDate => _fromDate;

  DateTime? get toDate => _toDate;

  String get search => _search;

  List<Map<String, dynamic>> get reportData => List.unmodifiable(_reportData);

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasData => _reportData.isNotEmpty;

  int get totalRecords => _reportData.length;

  // ============================================================
  // SETTERS
  // ============================================================

  void setReportType(ReportType type) {
    if (_reportType == type) return;

    _reportType = type;
    _reportData = [];
    _clearError();

    notifyListeners();
  }

  void setEquipmentType(EquipmentType type) {
    if (_equipmentType == type) return;

    _equipmentType = type;
    _reportData = [];
    _clearError();

    notifyListeners();
  }

  void setFromDate(DateTime? date) {
    _fromDate = date;
    notifyListeners();
  }

  void setToDate(DateTime? date) {
    _toDate = date;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void clearDates() {
    _fromDate = null;
    _toDate = null;
    notifyListeners();
  }

  void clearFilters() {
    _equipmentType = EquipmentType.all;
    _fromDate = null;
    _toDate = null;
    _search = '';
    _reportData = [];
    _clearError();

    notifyListeners();
  }

  // ============================================================
  // GENERATE REPORT
  // ============================================================

  Future<void> generateReport() async {
    _setLoading(true);
    _clearError();

    try {
      if (_fromDate != null &&
          _toDate != null &&
          _fromDate!.isAfter(_toDate!)) {
        throw Exception('From date cannot be later than To date.');
      }

      final List<Map<String, dynamic>> data = [];

      // --------------------------------------------------------
      // MAINTENANCE REPORT
      // --------------------------------------------------------

      if (_reportType == ReportType.maintenance) {
        if (_equipmentType == EquipmentType.excavator ||
            _equipmentType == EquipmentType.all) {
          final excavatorData = await _repository.getExcavatorMaintenanceReport(
            fromDate: _fromDate,
            toDate: _toDate,
            search: _search,
          );

          data.addAll(
            excavatorData.map((row) => {...row, 'equipment_type': 'Excavator'}),
          );
        }

        if (_equipmentType == EquipmentType.transport ||
            _equipmentType == EquipmentType.all) {
          final transportData = await _repository.getTransportMaintenanceReport(
            fromDate: _fromDate,
            toDate: _toDate,
            search: _search,
          );

          data.addAll(
            transportData.map((row) => {...row, 'equipment_type': 'Transport'}),
          );
        }
      }

      // --------------------------------------------------------
      // SERVICE REPORT
      // --------------------------------------------------------

      if (_reportType == ReportType.service) {
        if (_equipmentType == EquipmentType.excavator ||
            _equipmentType == EquipmentType.all) {
          final excavatorData = await _repository.getExcavatorServiceReport(
            fromDate: _fromDate,
            toDate: _toDate,
            search: _search,
          );

          data.addAll(
            excavatorData.map((row) => {...row, 'equipment_type': 'Excavator'}),
          );
        }

        if (_equipmentType == EquipmentType.transport ||
            _equipmentType == EquipmentType.all) {
          final transportData = await _repository.getTransportServiceReport(
            fromDate: _fromDate,
            toDate: _toDate,
            search: _search,
          );

          data.addAll(
            transportData.map((row) => {...row, 'equipment_type': 'Transport'}),
          );
        }
      }

      // --------------------------------------------------------
      // SORT BY DATE
      // --------------------------------------------------------

      data.sort((a, b) {
        final dateA = _getDateForSort(a);
        final dateB = _getDateForSort(b);

        return dateB.compareTo(dateA);
      });

      _reportData = data;
    } catch (e) {
      _error = e.toString();
      _reportData = [];
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await generateReport();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime _getDateForSort(Map<String, dynamic> row) {
    final value = _reportType == ReportType.service
        ? row['service_date']
        : row['created_at'];

    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void clearReport() {
    _reportData = [];
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
