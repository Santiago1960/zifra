import 'package:equatable/equatable.dart';

class Invoice extends Equatable {
  // ID de la factura en la base de datos
  final int? id;

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
  final String categoria;
  final bool estaSeleccionada;

  // Campos adicionales que estaban en la entidad anterior y podrian ser utiles
  final String? xmlContent; // Para mantener compatibilidad si se usaba
  final Map<String, String> infoAdicional; // Para infoAdicional
  final List<Pago> pagos; // Lista de pagos

  const Invoice({
    this.id,
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
    this.categoria = 'Sin categoría',
    this.estaSeleccionada = false,
    this.xmlContent,
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
        ruc,
        claveAcceso,
        secuencial,
        estaSeleccionada,
      ];

  Invoice copyWith({
    int? id,
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
    String? categoria,
    bool? estaSeleccionada,
    String? xmlContent,
    Map<String, String>? infoAdicional,
    List<Pago>? pagos,
  }) {
    return Invoice(
      id: id ?? this.id,
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
      categoria: categoria ?? this.categoria,
      estaSeleccionada: estaSeleccionada ?? this.estaSeleccionada,
      xmlContent: xmlContent ?? this.xmlContent,
      infoAdicional: infoAdicional ?? this.infoAdicional,
      pagos: pagos ?? this.pagos,
    );
  }
}

// MODELO PARA EL DETALLE DE LA FACTURA
class InvoiceDetail extends Equatable {
  final String codigoPrincipal;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double descuento;
  final double precioTotalSinImpuesto;
  // (Se pueden añadir impuestos del detalle si se necesita)

  const InvoiceDetail({
    required this.codigoPrincipal,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.descuento,
    required this.precioTotalSinImpuesto,
  });

  @override
  List<Object?> get props => [
        codigoPrincipal,
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

  @override
  List<Object?> get props => [formaPago, total, plazo, unidadTiempo];
}
