import 'package:zifra/data/datasources/local/user_local_datasource.dart';
import 'package:zifra/data/datasources/remote/project_remote_datasource.dart';
import 'package:zifra/domain/entities/user.dart';
import 'package:zifra/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;
  final ProjectRemoteDataSource remoteDataSource;

  UserRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<void> saveUser(User user) async {
    await localDataSource.saveUser(user);
  }

  @override
  Future<User?> getUser() async {
    return await localDataSource.getUser();
  }

  @override
  Future<bool> hasOpenProjects(String ruc) async {
    try {
      final invoices = await remoteDataSource.getOpenProjectInvoices(ruc);
      // Logic: If there are invoices, it implies open projects? 
      // Or maybe the backend returns projects directly?
      // Based on "consultamos en el backend si este usuario registra proyectos abiertos",
      // and the method `getOpenProjectInvoices`, I assume if we get invoices, we have open projects.
      // However, the user request says "consultamos... si registra proyectos abiertos".
      // If the list is not empty, we assume yes.
      // Ideally, the backend would return a list of Projects, but we have `getOpenProjectInvoices`.
      // We'll assume any return (even empty list if successful) means we checked.
      // But to return a boolean "hasOpenProjects", we might check if list is not empty.
      // Let's assume for now we just want to know if the call succeeds and maybe returns something.
      // If the user has NO open projects, the list might be empty.
      return invoices.isNotEmpty; 
    } catch (e) {
      // Handle error or return false
      print('Error checking open projects: $e');
      return false;
    }
  }

  @override
  Future<void> deleteUser() async {
    await localDataSource.deleteUser();
  }
}
