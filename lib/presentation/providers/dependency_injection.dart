import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zifra/core/client.dart';
import 'package:zifra/data/datasources/local/user_local_datasource.dart';
import 'package:zifra/data/datasources/remote/project_remote_datasource.dart';
import 'package:zifra/data/datasources/remote/invoice_remote_datasource.dart';
import 'package:zifra/data/repositories/user_repository_impl.dart';
import 'package:zifra/domain/repositories/user_repository.dart';
import 'package:zifra/domain/services/pdf_generator_service.dart';

// External
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final clientProvider = Provider<Client>((ref) {
  return Client(invoices: InvoicesEndpoint());
});

// Data Sources
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return UserLocalDataSourceImpl(sharedPreferences: sharedPreferences);
});

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  final client = ref.watch(clientProvider);
  return ProjectRemoteDataSourceImpl(client: client);
});

final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSourceImpl();
});

// Repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final localDataSource = ref.watch(userLocalDataSourceProvider);
  final remoteDataSource = ref.watch(projectRemoteDataSourceProvider);
  return UserRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

final pdfGeneratorServiceProvider = Provider<PdfGeneratorService>((ref) {
  return PdfGeneratorService();
});
