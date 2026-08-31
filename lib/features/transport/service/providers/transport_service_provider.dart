import 'package:flutter/foundation.dart';

import '../../../../data/models/transport_service_model.dart';
import '../../../../data/models/transport_service_item_model.dart';
import '../../../../data/repositories/transport_service_repository.dart';

class TransportServiceProvider extends ChangeNotifier {
  final TransportServiceRepository _repository;

  TransportServiceProvider({TransportServiceRepository? repository})
    : _repository = repository ?? TransportServiceRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<TransportServiceModel> _services = [];

  bool _isLoading = false;

  String? _error;

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  final Map<int, List<TransportServiceItemModel>> _itemsCache = {};

  // ============================================================
  // GETTERS
  // ============================================================

  List<TransportServiceModel> get services => List.unmodifiable(_services);

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<TransportServiceItemModel> getItemsForService(int serviceId) {
    return List.unmodifiable(_itemsCache[serviceId] ?? []);
  }

  // ============================================================
  // LOAD ALL SERVICES
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

  // ============================================================
  // GET SERVICE BY ID
  // ============================================================

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
  // GET SERVICE ITEMS
  // ============================================================

  Future<List<TransportServiceItemModel>> getItems(int serviceId) async {
    try {
      final items = await _repository.getItems(serviceId);

      _itemsCache[serviceId] = items;

      notifyListeners();

      return items;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  // ============================================================
  // LOAD SERVICE WITH ITEMS
  // ============================================================

  Future<
    ({TransportServiceModel service, List<TransportServiceItemModel> items})?
  >
  getByIdWithItems(int id) async {
    try {
      final result = await _repository.getByIdWithItems(id);

      if (result != null) {
        _itemsCache[id] = result.items;
      }

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<bool> addService({
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final serviceId = await _repository.insertWithItems(
        service: service,
        items: items,
      );

      final createdService = await _repository.getById(serviceId);

      if (createdService != null) {
        _services.insert(0, createdService);
      }

      final savedItems = await _repository.getItems(serviceId);

      _itemsCache[serviceId] = savedItems;

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE SERVICE
  // ============================================================

  Future<bool> updateService({
    required TransportServiceModel service,
    required List<TransportServiceItemModel> items,
  }) async {
    if (service.id == null) {
      _error = 'Service ID is required for update.';
      notifyListeners();

      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      await _repository.updateWithItems(service: service, items: items);

      final updatedService = await _repository.getById(service.id!);

      if (updatedService != null) {
        final index = _services.indexWhere((item) => item.id == service.id);

        if (index != -1) {
          _services[index] = updatedService;
        }
      }

      final updatedItems = await _repository.getItems(service.id!);

      _itemsCache[service.id!] = updatedItems;

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

  Future<bool> deleteService(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.delete(id);

      _services.removeWhere((service) => service.id == id);

      _itemsCache.remove(id);

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // DELETE SERVICE ITEM
  // ============================================================

  Future<bool> deleteServiceItem(int itemId, int serviceId) async {
    try {
      await _repository.deleteItem(itemId);

      final items = _itemsCache[serviceId];

      if (items != null) {
        items.removeWhere((item) => item.id == itemId);
      }

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // VEHICLE SERVICE HISTORY
  // ============================================================

  Future<List<TransportServiceModel>> getByVehicleId(
    int transportVehicleId,
  ) async {
    try {
      return await _repository.getByVehicleId(transportVehicleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadServices();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
