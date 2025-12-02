import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zifra/core/client.dart';
import 'package:zifra/domain/entities/invoice.dart';

abstract class ProjectRemoteDataSource {
  Future<List<Invoice>> getOpenProjectInvoices(String ruc);
  Future<int> createProject(String clientName, String projectName, String rucBeneficiario);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Client client;

  ProjectRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Invoice>> getOpenProjectInvoices(String ruc) async {
    return await client.invoices.getOpenProjectInvoices(ruc);
  }

  @override
  Future<int> createProject(String clientName, String projectName, String rucBeneficiario) async {
    final url = Uri.parse('http://127.0.0.1:8080/projects/createProject');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'project': {
            'cliente': clientName,
            'nombre': projectName,
            'rucBeneficiario': rucBeneficiario,
            'fechaCreacion': DateTime.now().toIso8601String(),
            'isClosed': false,
          }
        }),
      );

      if (response.statusCode == 200) {
        return int.parse(response.body);
      } else {
        print('Error creating project: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 409 || response.body.toLowerCase().contains('existe')) {
          String message = 'El proyecto ya existe';
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map) {
              if (decoded.containsKey('message')) {
                message = decoded['message'];
              } else if (decoded.containsKey('error')) {
                message = decoded['error'];
              }
            }
          } catch (e) {
            // If not JSON, use the body if it's short enough to be a message
            if (response.body.length < 200) {
               message = response.body;
            }
          }
          throw ProjectExistsException(message);
        }
        throw Exception('Failed to create project: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class ProjectExistsException implements Exception {
  final String message;
  ProjectExistsException([this.message = 'El proyecto ya existe']);
  @override
  String toString() => message;
}
