import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:zifra/core/config.dart';
import 'package:zifra/domain/entities/invoice.dart';
import 'package:zifra/core/exceptions/duplicate_invoices_exception.dart';

abstract class InvoiceRemoteDataSource {
  Future<bool> saveInvoices(List<Invoice> invoices, int projectId);
  Future<bool> updateInvoiceCategory(String claveAcceso, int? categoryId);
  Future<bool> updateInvoicesCategory(List<String> clavesAcceso, int? categoryId);
}


class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  @override
  Future<bool> saveInvoices(List<Invoice> invoices, int projectId) async {
    final url = Uri.parse('${Config.serverUrl}/invoices/saveInvoices');
    try {
      final invoicesJson = invoices.map((invoice) {
        final json = invoice.toJson();
        json['projectId'] = projectId;
        return json;
      }).toList();

      final body = jsonEncode({
          'invoices': invoicesJson,
        });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        
        if (decoded == true || decoded == 'OK') {
          return true;
        }
        
        if (decoded is String && decoded.contains('DUPLICATES_FOUND:')) {
           final parts = decoded.split('DUPLICATES_FOUND:');
           if (parts.length > 1) {
             final duplicatesStr = parts[1];
             // Use /// as separator to avoid issues with | in company names
             final messages = duplicatesStr.split('///');
             throw DuplicateInvoicesException(messages);
           }
        }
        
        throw Exception('Unexpected response: $decoded');
      } else {
        throw Exception('Failed to save invoices: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }


  @override
  Future<bool> updateInvoiceCategory(String claveAcceso, int? categoryId) async {
    // debugPrint('DEBUG: Updating invoice $claveAcceso with categoryId: $categoryId');
    final url = Uri.parse('${Config.serverUrl}/invoices/updateInvoiceCategory');
    try {
      final body = jsonEncode({
        'claveAcceso': claveAcceso,
        'categoryId': categoryId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // debugPrint('DEBUG: Update response status: ${response.statusCode}');
      // debugPrint('DEBUG: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded != null;
      } else {
        throw Exception('Failed to update invoice category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> updateInvoicesCategory(List<String> clavesAcceso, int? categoryId) async {
    final url = Uri.parse('${Config.serverUrl}/invoices/updateInvoicesCategory');
    try {
      final body = jsonEncode({
        'clavesAcceso': clavesAcceso,
        'categoryId': categoryId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded == true;
      } else {
        throw Exception('Failed to update invoices category: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
