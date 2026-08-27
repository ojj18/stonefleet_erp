import 'package:flutter/foundation.dart';

import '../../../../data/models/transport_service_item_model.dart';
import '../../../../data/models/transport_service_model.dart';
import '../../../../data/models/transport_service_schedule_model.dart';
import '../../../../data/repositories/transport_service_repository.dart';

class TransportServiceProvider extends ChangeNotifier {
  final TransportServiceRepository _repository;

  TransportServiceProvider({TransportServiceRepository? repository})
    : _repository = repository ?? TransportServiceRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<TransportServiceModel> _services = [];

  List<TransportServiceItemModel> _items = [];

  List<TransportServiceScheduleModel> _schedules = [];

  bool _isLoading = false;

  String? _error;

  List<TransportServiceModel> get services => List.unmodifiable(_services);

  List<TransportServiceItemModel> get items => List.unmodifiable(_items);

  List<TransportServiceScheduleModel> get schedules =>
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

  Future<void> loadByVehicle(int vehicleId) async {
    _setLoading(true);
    _error = null;

    try {
      _services = await _repository.getByVehicle(vehicleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<TransportServiceModel?> getById(int id) async {
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
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
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

  Future<bool> updateService(TransportServiceModel service) async {
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

  Future<bool> addItem(TransportServiceItemModel item) async {
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

  Future<void> loadSchedules(int transportModelId) async {
    _setLoading(true);
    _error = null;

    try {
      _schedules = await _repository.getSchedulesByModel(transportModelId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSchedule(TransportServiceScheduleModel schedule) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insertSchedule(schedule);

      _schedules = await _repository.getSchedulesByModel(
        schedule.transportModelId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSchedule(TransportServiceScheduleModel schedule) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.updateSchedule(schedule);

      _schedules = await _repository.getSchedulesByModel(
        schedule.transportModelId,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSchedule(int id, int transportModelId) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.deleteSchedule(id);

      _schedules = await _repository.getSchedulesByModel(transportModelId);

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
