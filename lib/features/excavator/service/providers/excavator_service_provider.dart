import 'package:flutter/foundation.dart';

import '../../../../data/models/excavator_service_item_model.dart';
import '../../../../data/models/excavator_service_model.dart';
import '../../../../data/models/excavator_service_schedule_model.dart';
import '../../../../data/repositories/excavator_service_repository.dart';

class ExcavatorServiceProvider extends ChangeNotifier {
  final ExcavatorServiceRepository _repository;

  ExcavatorServiceProvider({ExcavatorServiceRepository? repository})
    : _repository = repository ?? ExcavatorServiceRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<ExcavatorServiceModel> _services = [];

  List<ExcavatorServiceItemModel> _items = [];

  List<ExcavatorServiceScheduleModel> _schedules = [];

  bool _isLoading = false;

  String? _error;

  List<ExcavatorServiceModel> get services => List.unmodifiable(_services);

  List<ExcavatorServiceItemModel> get items => List.unmodifiable(_items);

  List<ExcavatorServiceScheduleModel> get schedules =>
      List.unmodifiable(_schedules);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // SERVICES
  // ============================================================

  Future<void> loadServices() async {
    _setLoading(true);
    _error = null;

    try {
      _services = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadByExcavator(int excavatorId) async {
    _setLoading(true);
    _error = null;

    try {
      _services = await _repository.getByExcavator(excavatorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<ExcavatorServiceModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // CREATE SERVICE + ITEMS
  // ============================================================

  Future<int?> createService({
    required ExcavatorServiceModel service,
    required List<ExcavatorServiceItemModel> items,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final serviceId = await _repository.createServiceWithItems(
        service: service,
        items: items,
      );

      await loadServices();

      return serviceId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE SERVICE
  // ============================================================

  Future<bool> updateService(ExcavatorServiceModel service) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.updateService(service);
      await loadServices();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<bool> deleteService(int serviceId) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.deleteService(serviceId);
      await loadServices();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  Future<void> loadItems(int serviceId) async {
    _setLoading(true);
    _error = null;

    try {
      _items = await _repository.getItems(serviceId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addItem(ExcavatorServiceItemModel item) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.addItem(item);

      _items = await _repository.getItems(item.serviceId);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteItem(int itemId, int serviceId) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.deleteItem(itemId);

      _items = await _repository.getItems(serviceId);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SERVICE SCHEDULES
  // ============================================================

  Future<void> loadSchedules(int excavatorModelId) async {
    _setLoading(true);
    _error = null;

    try {
      _schedules = await _repository.getSchedulesByModel(excavatorModelId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSchedule(ExcavatorServiceScheduleModel schedule) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insertSchedule(schedule);

      _schedules = await _repository.getSchedulesByModel(
        schedule.excavatorModelId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSchedule(ExcavatorServiceScheduleModel schedule) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.updateSchedule(schedule);

      _schedules = await _repository.getSchedulesByModel(
        schedule.excavatorModelId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSchedule(int id, int excavatorModelId) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.deleteSchedule(id);

      _schedules = await _repository.getSchedulesByModel(excavatorModelId);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearItems() {
    _items = [];
    notifyListeners();
  }

  void clearSchedules() {
    _schedules = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
