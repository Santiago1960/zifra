import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  // ID de la factura en la base de datos
  final int? id;
  final int? projectId;

  // Info tributaria
  final String razonSocial;
  final String nombreComercial;
  final String ruc;
  final String claveAcceso;
  final String codDoc;
  final String estab;
  final String ptoEmi;
  final String secuencial;
  final String dirMatriz;

  // Info factura
  final String fechaEmision;
  final String dirEstablecimiento;
  final String contribuyenteEspecial;
  final String obligadoContabilidad;
  final String tipoIdentificacionComprador;
  final String razonSocialComprador;
  final String identificacionComprador;
  final double totalSinImpuestos;
  final double totalDescuento;
  final double baseImponibleIvaCero;
  final double baseImponibleIva;
  final double valorIVA;
  final double valorDevolucionIva;
  final double propina;
  final double importeTotal;

  // Lista con el detalle de la factura
  final List<InvoiceDetail> detalle;

  // Otros
  final String numeroAutorizacion;
  final String fechaAutorizacion;
  final int? categoryId;
  final bool estaSeleccionada;

  // Campos adicionales que estaban en la entidad anterior y podrian ser utiles
  final Map<String, String> infoAdicional; // Para infoAdicional
  final List<Pago> pagos; // Lista de pagos

  const Invoice({
    this.id,
    this.projectId,
    required this.razonSocial,
    required this.nombreComercial,
    required this.ruc,
    required this.claveAcceso,
    required this.codDoc,
    required this.estab,
    required this.ptoEmi,
    required this.secuencial,
    required this.dirMatriz,
    required this.fechaEmision,
    required this.dirEstablecimiento,
    required this.contribuyenteEspecial,
    required this.obligadoContabilidad,
    required this.tipoIdentificacionComprador,
    required this.razonSocialComprador,
    required this.identificacionComprador,
    required this.totalSinImpuestos,
    required this.totalDescuento,
    required this.baseImponibleIvaCero,
    required this.baseImponibleIva,
    required this.valorIVA,
    required this.valorDevolucionIva,
    required this.propina,
    required this.importeTotal,
    required this.detalle,
    required this.numeroAutorizacion,
    required this.fechaAutorizacion,
    this.categoryId,
    this.estaSeleccionada = false,
    this.infoAdicional = const {},
    this.pagos = const [],
  });

  /// Helper getter para mostrar el número de factura completo
  String get numeroFacturaCompleto {
    return '$estab-$ptoEmi-$secuencial';
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        ruc,
        claveAcceso,
        secuencial,
        estaSeleccionada,
        categoryId,
      ];

  Invoice copyWith({
    int? id,
    int? projectId,
    String? razonSocial,
    String? nombreComercial,
    String? ruc,
    String? claveAcceso,
    String? codDoc,
    String? estab,
    String? ptoEmi,
    String? secuencial,
    String? dirMatriz,
    String? fechaEmision,
    String? dirEstablecimiento,
    String? contribuyenteEspecial,
    String? obligadoContabilidad,
    String? tipoIdentificacionComprador,
    String? razonSocialComprador,
    String? identificacionComprador,
    double? totalSinImpuestos,
    double? totalDescuento,
    double? baseImponibleIvaCero,
    double? baseImponibleIva,
    double? valorIVA,
    double? valorDevolucionIva,
    double? propina,
    double? importeTotal,
    List<InvoiceDetail>? detalle,
    String? numeroAutorizacion,
    String? fechaAutorizacion,
    int? categoryId,
    bool? estaSeleccionada,
    Map<String, String>? infoAdicional,
    List<Pago>? pagos,
  }) {
    return Invoice(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      razonSocial: razonSocial ?? this.razonSocial,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      ruc: ruc ?? this.ruc,
      claveAcceso: claveAcceso ?? this.claveAcceso,
      codDoc: codDoc ?? this.codDoc,
      estab: estab ?? this.estab,
      ptoEmi: ptoEmi ?? this.ptoEmi,
      secuencial: secuencial ?? this.secuencial,
      dirMatriz: dirMatriz ?? this.dirMatriz,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      dirEstablecimiento: dirEstablecimiento ?? this.dirEstablecimiento,
      contribuyenteEspecial: contribuyenteEspecial ?? this.contribuyenteEspecial,
      obligadoContabilidad: obligadoContabilidad ?? this.obligadoContabilidad,
      tipoIdentificacionComprador:
          tipoIdentificacionComprador ?? this.tipoIdentificacionComprador,
      razonSocialComprador: razonSocialComprador ?? this.razonSocialComprador,
      identificacionComprador:
          identificacionComprador ?? this.identificacionComprador,
      totalSinImpuestos: totalSinImpuestos ?? this.totalSinImpuestos,
      totalDescuento: totalDescuento ?? this.totalDescuento,
      baseImponibleIvaCero: baseImponibleIvaCero ?? this.baseImponibleIvaCero,
      baseImponibleIva: baseImponibleIva ?? this.baseImponibleIva,
      valorIVA: valorIVA ?? this.valorIVA,
      valorDevolucionIva: valorDevolucionIva ?? this.valorDevolucionIva,
      propina: propina ?? this.propina,
      importeTotal: importeTotal ?? this.importeTotal,
      detalle: detalle ?? this.detalle,
      numeroAutorizacion: numeroAutorizacion ?? this.numeroAutorizacion,
      fechaAutorizacion: fechaAutorizacion ?? this.fechaAutorizacion,
      categoryId: categoryId ?? this.categoryId,
      estaSeleccionada: estaSeleccionada ?? this.estaSeleccionada,
      infoAdicional: infoAdicional ?? this.infoAdicional,
      pagos: pagos ?? this.pagos,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      projectId: json['projectId'],
      razonSocial: json['razonSocial'] ?? '',
      nombreComercial: json['nombreComercial'] ?? '',
      ruc: json['ruc'] ?? '',
      claveAcceso: json['claveAcceso'] ?? '',
      codDoc: json['codDoc'] ?? '',
      estab: json['estab'] ?? '',
      ptoEmi: json['ptoEmi'] ?? '',
      secuencial: json['secuencial'] ?? '',
      dirMatriz: json['dirMatriz'] ?? '',
      fechaEmision: json['fechaEmision'] ?? '',
      dirEstablecimiento: json['dirEstablecimiento'] ?? '',
      contribuyenteEspecial: json['contribuyenteEspecial'] ?? '',
      obligadoContabilidad: json['obligadoContabilidad'] ?? '',
      tipoIdentificacionComprador: json['tipoIdentificacionComprador'] ?? '',
      razonSocialComprador: json['razonSocialComprador'] ?? '',
      identificacionComprador: json['identificacionComprador'] ?? '',
      totalSinImpuestos: (json['totalSinImpuestos'] ?? 0).toDouble(),
      totalDescuento: (json['totalDescuento'] ?? 0).toDouble(),
      baseImponibleIvaCero: (json['baseImponibleIvaCero'] ?? 0).toDouble(),
      baseImponibleIva: (json['baseImponibleIva'] ?? 0).toDouble(),
      valorIVA: (json['valorIVA'] ?? 0).toDouble(),
      valorDevolucionIva: (json['valorDevolucionIva'] ?? 0).toDouble(),
      propina: (json['propina'] ?? 0).toDouble(),
      importeTotal: (json['importeTotal'] ?? 0).toDouble(),
      detalle: (json['detalles'] as List<dynamic>?)
              ?.map((e) => InvoiceDetail.fromJson(e))
              .toList() ??
          [],
      numeroAutorizacion: json['numeroAutorizacion'] ?? '',
      fechaAutorizacion: json['fechaAutorizacion'] ?? '',
      categoryId: json['categoryId'],
      estaSeleccionada: json['estaSeleccionada'] ?? false,
      infoAdicional: (json['infoAdicional'] as List<dynamic>?)
              ?.fold<Map<String, String>>({}, (map, item) {
            map[item['clave']] = item['valor'];
            return map;
          }) ??
          {},
      pagos: (json['pagos'] as List<dynamic>?)
              ?.map((e) => Pago.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    String? formatDate(String date) {
      try {
        // Try parsing dd/MM/yyyy
        final parts = date.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day).toIso8601String();
        }
        // If not dd/MM/yyyy, try parsing as DateTime directly (if already ISO or similar)
        return DateTime.parse(date).toIso8601String();
      } catch (e) {
        // Fallback: return original string if parsing fails, let server handle or fail
        return date;
      }
    }

    return {
      'id': id,
      'projectId': projectId,
      'razonSocial': razonSocial,
      'nombreComercial': nombreComercial,
      'ruc': ruc,
      'claveAcceso': claveAcceso,
      'codDoc': codDoc,
      'estab': estab,
      'ptoEmi': ptoEmi,
      'secuencial': secuencial,
      'dirMatriz': dirMatriz,
      'fechaEmision': formatDate(fechaEmision),
      'dirEstablecimiento': dirEstablecimiento,
      'contribuyenteEspecial': contribuyenteEspecial,
      'obligadoContabilidad': obligadoContabilidad,
      'tipoIdentificacionComprador': tipoIdentificacionComprador,
      'razonSocialComprador': razonSocialComprador,
      'identificacionComprador': identificacionComprador,
      'totalSinImpuestos': totalSinImpuestos,
      'totalDescuento': totalDescuento,
      'baseImponibleIvaCero': baseImponibleIvaCero,
      'baseImponibleIva': baseImponibleIva,
      'valorIVA': valorIVA,
      'valorDevolucionIva': valorDevolucionIva,
      'propina': propina,
      'importeTotal': importeTotal,
      'detalles': detalle.map((e) => e.toJson()).toList(),
      'numeroAutorizacion': numeroAutorizacion,
      'fechaAutorizacion': formatDate(fechaAutorizacion),
      'categoryId': categoryId,
      'estaSeleccionada': estaSeleccionada,
      'certificada': false,
      'infoAdicional': infoAdicional.entries.map((e) => {
        'clave': e.key, 
        'valor': e.value, 
        'invoiceId': 0
      }).toList(),
      'pagos': pagos.map((e) => e.toJson()).toList(),
    };
  }
}

// MODELO PARA EL DETALLE DE LA FACTURA
class InvoiceDetail extends Equatable {
  final String codigoPrincipal;
  final String? codigoAuxiliar;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double precioTotalSinImpuesto;
  // (Se pueden añadir impuestos del detalle si se necesita)

  const InvoiceDetail({
    required this.codigoPrincipal,
    this.codigoAuxiliar,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.precioTotalSinImpuesto,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      codigoPrincipal: json['codigoPrincipal'] ?? '',
      codigoAuxiliar: json['codigoAuxiliar'],
      descripcion: json['descripcion'] ?? '',
      cantidad: (json['cantidad'] ?? 0).toDouble(),
      precioUnitario: (json['precioUnitario'] ?? 0).toDouble(),
      descuento: (json['descuento'] ?? 0).toDouble(),
      precioTotalSinImpuesto: (json['precioTotalSinImpuesto'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigoPrincipal': codigoPrincipal,
      'codigoAuxiliar': codigoAuxiliar,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'descuento': descuento,
      'precioTotalSinImpuesto': precioTotalSinImpuesto,
      'invoiceId': 0,
    };
  }

  @override
  List<Object?> get props => [
        codigoPrincipal,
        codigoAuxiliar,
        descripcion,
        cantidad,
        precioUnitario,
      ];
}

// MODELO PARA LOS PAGOS
class Pago extends Equatable {
  final String formaPago;
  final double total;
  final double plazo;
  final String unidadTiempo;

  const Pago({
    required this.formaPago,
    required this.total,
    required this.plazo,
    required this.unidadTiempo,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      formaPago: json['formaPago'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      plazo: (json['plazo'] ?? 0).toDouble(),
      unidadTiempo: json['unidadTiempo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formaPago': formaPago,
      'total': total,
      'plazo': plazo,
      'unidadTiempo': unidadTiempo,
      'invoiceId': 0,
    };
  }

  @override
  List<Object?> get props => [formaPago, total, plazo, unidadTiempo];
}
