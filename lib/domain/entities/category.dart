import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final int userId;
  final String color; // Hex string format, e.g., "FF0000"
  final bool active;

  const Category({
    this.id,
    required this.name,
    required this.userId,
    required this.color,
    this.active = true,
  });

  Category copyWith({
    int? id,
    String? name,
    int? userId,
    String? color,
    bool? active,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      active: active ?? this.active,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      userId: json['userId'] ?? 0,
      color: json['color'] ?? '000000',
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'color': color,
      'active': active,
    };
  }

  @override
  List<Object?> get props => [id, name, userId, color, active];
}
