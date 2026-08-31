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
  // LOAD ALL
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
  // LOAD ACTIVE
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
  // GET BY ID
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
  // CHECK REGISTRATION EXISTS
  // ============================================================

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

  // ============================================================
  // ADD EXCAVATOR
  // ============================================================

  Future<bool> addExcavator(ExcavatorModel model) async {
    _setLoading(true);
    _clearError();

    try {
      // Final duplicate protection.
      final exists = await _repository.registrationExists(
        model.registrationNumber,
      );

      if (exists) {
        _error = 'Registration number already exists.';
        return false;
      }

      await _repository.insert(model);

      // Refresh list.
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
      // During edit, exclude the current vehicle ID.
      final exists = await _repository.registrationExists(
        model.registrationNumber,
        excludeId: model.id,
      );

      if (exists) {
        _error = 'Registration number already exists.';
        return false;
      }

      await _repository.update(model);

      // Refresh list.
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

      // Refresh list.
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
  // CLEAR
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
}
