import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zifra/data/datasources/remote/category_remote_datasource.dart';
import 'package:zifra/domain/entities/category.dart';

class CategoryNotifier extends Notifier<List<Category>> {
  late final CategoryRemoteDataSource dataSource;

  @override
  List<Category> build() {
    dataSource = CategoryRemoteDataSourceImpl();
    fetchCategories();
    return [];
  }

  Future<void> fetchCategories() async {
    try {
      // TODO: Get actual user ID from auth or user provider
      final categories = await dataSource.getCategories(1);
      state = categories;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  bool _areSimilar(String name1, String name2) {
    final n1 = name1.toLowerCase().trim();
    final n2 = name2.toLowerCase().trim();
    
    // Exactamente iguales
    if (n1 == n2) return true;
    
    // Una contiene a la otra (detecta singular/plural simple)
    if (n1.contains(n2) || n2.contains(n1)) {
      // Solo si la diferencia es pequeña (máx 2 caracteres)
      if ((n1.length - n2.length).abs() <= 2) {
        return true;
      }
    }
    
    return false;
  }

  /// Retorna null si no hay error, o un objeto con información del error
  /// {type: 'exact'|'similar', existingName: 'nombre'}
  Future<Map<String, String>?> addCategory(Category category) async {
    // Buscar duplicados exactos
    final exactDuplicate = state.firstWhere(
      (c) => c.name.toLowerCase().trim() == category.name.toLowerCase().trim() && c.userId == category.userId,
      orElse: () => Category(name: '', userId: 0, color: ''),
    );
    
    if (exactDuplicate.name.isNotEmpty) {
      return {'type': 'exact', 'existingName': exactDuplicate.name};
    }
    
    // Buscar categorías similares
    final similarCategory = state.firstWhere(
      (c) => _areSimilar(c.name, category.name) && c.userId == category.userId,
      orElse: () => Category(name: '', userId: 0, color: ''),
    );
    
    if (similarCategory.name.isNotEmpty) {
      return {'type': 'similar', 'existingName': similarCategory.name};
    }
    
    try {
      await dataSource.addCategory(category);
      await fetchCategories();
      return null; // Éxito, sin error
    } catch (e) {
      debugPrint('Error adding category: $e');
      return {'type': 'error', 'message': 'Error al agregar la categoría'};
    }
  }

  Future<Map<String, String>?> updateCategory(Category category) async {
    // Buscar duplicados exactos (excluyendo la categoría actual)
    final exactDuplicate = state.firstWhere(
      (c) => 
        c.name.toLowerCase().trim() == category.name.toLowerCase().trim() && 
        c.userId == category.userId &&
        c.id != category.id,
      orElse: () => Category(name: '', userId: 0, color: ''),
    );
    
    if (exactDuplicate.name.isNotEmpty) {
      return {'type': 'exact', 'existingName': exactDuplicate.name};
    }
    
    // Buscar categorías similares (excluyendo la categoría actual)
    final similarCategory = state.firstWhere(
      (c) => 
        _areSimilar(c.name, category.name) && 
        c.userId == category.userId &&
        c.id != category.id,
      orElse: () => Category(name: '', userId: 0, color: ''),
    );
    
    if (similarCategory.name.isNotEmpty) {
      return {'type': 'similar', 'existingName': similarCategory.name};
    }
    
    try {
      await dataSource.updateCategory(category);
      await fetchCategories();
      return null; // Éxito, sin error
    } catch (e) {
      debugPrint('Error updating category: $e');
      return {'type': 'error', 'message': 'Error al actualizar la categoría'};
    }
  }

  Future<bool> deleteCategory(int id, {required Future<bool> Function() confirmDelete}) async {
    try {
      // Solicitar confirmación al usuario
      final confirmed = await confirmDelete();
      
      if (!confirmed) {
        return false; // Usuario canceló
      }
      
      // Proceder con la eliminación
      await dataSource.deleteCategory(id);
      await fetchCategories();
      return true; // Eliminación exitosa
    } catch (e) {
      debugPrint('Error deleting category: $e');
      rethrow;
    }
  }
}

final categoryProvider = NotifierProvider<CategoryNotifier, List<Category>>(CategoryNotifier.new);
