class Project {
  final int? id;
  final String cliente;
  final String nombre;
  final String? rucBeneficiario;
  final DateTime fechaCreacion;
  final bool isClosed;

  Project({
    this.id,
    required this.cliente,
    required this.nombre,
    this.rucBeneficiario,
    required this.fechaCreacion,
    required this.isClosed,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      cliente: json['cliente'],
      nombre: json['nombre'],
      rucBeneficiario: json['rucBeneficiario'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      isClosed: json['isClosed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'nombre': nombre,
      'rucBeneficiario': rucBeneficiario,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'isClosed': isClosed,
    };
  }
}
