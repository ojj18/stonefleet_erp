import 'package:flutter/foundation.dart';

import '../../../../data/models/excavator_model.dart';
import '../../../../data/repositories/excavator_repository.dart';

class ExcavatorProvider extends ChangeNotifier {
  final ExcavatorRepository _repository;

  ExcavatorProvider({ExcavatorRepository? repository})
    : _repository = repository ?? ExcavatorRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<ExcavatorModel> _excavators = [];

  bool _isLoading = false;

  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<ExcavatorModel> get excavators => List.unmodifiable(_excavators);

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get count => _excavators.length;

  // ============================================================
  // LOAD ALL EXCAVATORS
  // ============================================================

  Future<void> loadExcavators() async {
    _setLoading(true);
    _clearError();

    try {
      _excavators = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD ACTIVE EXCAVATORS
  // ============================================================

  Future<void> loadActiveExcavators() async {
    _setLoading(true);
    _clearError();

    try {
      _excavators = await _repository.getActive();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GET EXCAVATOR BY ID
  // ============================================================

  Future<ExcavatorModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // ADD EXCAVATOR
  // ============================================================

  Future<bool> addExcavator(ExcavatorModel model) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.insert(model);

      // Refresh the list after insertion.
      _excavators = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE EXCAVATOR
  // ============================================================

  Future<bool> updateExcavator(ExcavatorModel model) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.update(model);

      // Refresh the list after update.
      _excavators = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // DELETE EXCAVATOR
  // ============================================================

  Future<bool> deleteExcavator(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.delete(id);

      // Refresh the list after deletion.
      _excavators = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadExcavators();
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clear() {
    _excavators = [];
    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<bool> registrationExists(
    String registrationNumber, {
    int? excludeId,
  }) async {
    try {
      return await _repository.registrationExists(
        registrationNumber,
        excludeId: excludeId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
