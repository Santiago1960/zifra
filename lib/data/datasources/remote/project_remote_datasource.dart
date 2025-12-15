import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zifra/core/client.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/domain/entities/project.dart';

abstract class ProjectRemoteDataSource {
  Future<List<Invoice>> getOpenProjectInvoices(String ruc);
  Future<List<Project>> getProjects(String ruc);
  Future<int> createProject(String clientName, String projectName, String rucBeneficiario);
  Future<List<Invoice>> getProjectInvoices(int projectId);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final Client client;

  ProjectRemoteDataSourceImpl({required this.client});

  @override
  Future<List<Invoice>> getOpenProjectInvoices(String ruc) async {
    return await client.invoices.getOpenProjectInvoices(ruc);
  }

  @override
  Future<List<Invoice>> getProjectInvoices(int projectId) async {
    final url = Uri.parse('http://127.0.0.1:8080/invoices/getProjectInvoices');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectId': projectId,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        return decoded.map((json) => Invoice.fromJson(json)).toList();
      } else {
        debugPrint('Error getting project invoices: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception getting project invoices: $e');
      return [];
    }
  }

  @override
  Future<List<Project>> getProjects(String ruc) async {
    final url = Uri.parse('http://127.0.0.1:8080/projects/getOpenProjects');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rucBeneficiario': ruc,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        return decoded.map((json) => Project.fromJson(json)).toList();
      } else {
        debugPrint('Error getting projects: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception getting projects: $e');
      return [];
    }
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
        debugPrint('Error creating project: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
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
