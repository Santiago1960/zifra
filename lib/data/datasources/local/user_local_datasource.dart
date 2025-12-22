import 'package:shared_preferences/shared_preferences.dart';
import 'package:zifra/domain/entities/user.dart';

abstract class UserLocalDataSource {
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> deleteUser();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final SharedPreferences sharedPreferences;

  UserLocalDataSourceImpl({required this.sharedPreferences});

  static const String _keyName = 'user_name';
  static const String _keyRuc  = 'user_ruc';

  @override
  Future<void> saveUser(User user) async {
    await sharedPreferences.setString(_keyName, user.name);
    await sharedPreferences.setString(_keyRuc, user.ruc);
  }

  @override
  Future<User?> getUser() async {
    final name = sharedPreferences.getString(_keyName);
    final ruc = sharedPreferences.getString(_keyRuc);

    if (name != null && ruc != null) {
      return User(name: name, ruc: ruc);
    }
    return null;
  }

  @override
  Future<void> deleteUser() async {
    await sharedPreferences.remove(_keyName);
    await sharedPreferences.remove(_keyRuc);
  }
}
