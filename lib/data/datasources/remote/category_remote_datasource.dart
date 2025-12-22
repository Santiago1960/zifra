import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:zifra/core/config.dart';
import 'package:zifra/domain/entities/category.dart';

abstract class CategoryRemoteDataSource {
  Future<List<Category>> getCategories(int userId);
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  CategoryRemoteDataSourceImpl();

  @override
  Future<List<Category>> getCategories(int userId) async {
    final url = Uri.parse('${Config.serverUrl}/category/getCategories');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        return decoded.map((json) => Category.fromJson(json)).toList();
      } else {
        debugPrint('Error getting categories: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception getting categories: $e');
      return [];
    }
  }

  @override
  Future<void> addCategory(Category category) async {
    final url = Uri.parse('${Config.serverUrl}/category/addCategory');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category.toJson()}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error adding category: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        // Intentar parsear el mensaje de error del servidor
        String errorMessage = 'Failed to add category';
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            // El servidor puede devolver el mensaje directamente o en JSON
            if (errorBody.startsWith('{')) {
              final errorJson = jsonDecode(errorBody);
              errorMessage = errorJson['message'] ?? errorJson['error'] ?? errorBody;
            } else {
              errorMessage = errorBody;
            }
          }
        } catch (e) {
          debugPrint('Could not parse error message: $e');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception adding category: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(Category category) async {
    final url = Uri.parse('${Config.serverUrl}/category/updateCategory');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category.toJson()}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error updating category: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        // Intentar parsear el mensaje de error del servidor
        String errorMessage = 'Failed to update category';
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            // El servidor puede devolver el mensaje directamente o en JSON
            if (errorBody.startsWith('{')) {
              final errorJson = jsonDecode(errorBody);
              errorMessage = errorJson['message'] ?? errorJson['error'] ?? errorBody;
            } else {
              errorMessage = errorBody;
            }
          }
        } catch (e) {
          debugPrint('Could not parse error message: $e');
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception updating category: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    final url = Uri.parse('${Config.serverUrl}/category/deleteCategory');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error deleting category: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      debugPrint('Exception deleting category: $e');
      rethrow;
    }
  }
}
