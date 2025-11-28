import 'package:zifra/core/client.dart';
import 'package:zifra/domain/entities/invoice.dart';

abstract class ProjectRemoteDataSource {
  Future<List<Invoice>> getOpenProjectInvoices(String ruc);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Client client;

  ProjectRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Invoice>> getOpenProjectInvoices(String ruc) async {
    return await client.invoices.getOpenProjectInvoices(ruc);
  }
}
