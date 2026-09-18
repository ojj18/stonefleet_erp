import '../../core/database/database_helper.dart';
import '../models/app_user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<AppUser?> login(String username, String password) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username.trim(), password],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppUser.fromMap(result.first);
  }
}
