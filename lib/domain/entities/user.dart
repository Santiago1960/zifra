import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String name;
  final String ruc;

  const User({
    required this.name,
    required this.ruc,
  });

  @override
  List<Object?> get props => [name, ruc];
}
