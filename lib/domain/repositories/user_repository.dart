import 'package:zifra/domain/entities/user.dart';
import 'package:zifra/domain/entities/project.dart';

abstract class UserRepository {
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<bool> hasOpenProjects(String ruc);
  Future<List<Project>> getProjects(String ruc);
  Future<void> deleteUser();
}
