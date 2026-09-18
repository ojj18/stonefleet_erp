import 'package:flutter/foundation.dart';

import '../../../data/models/app_user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isLoggedIn => _currentUser != null;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _repository.login(username, password);

      if (user == null) {
        _error = 'Invalid username or password.';
        return false;
      }

      _currentUser = user;
      return true;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
