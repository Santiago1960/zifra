import 'package:xml/xml.dart';
import 'package:zifra/domain/entities/invoice.dart';

class InvoiceValidator {
  static const List<String> _validRootTags = [
    'factura',
    'notaCredito',
    'notaDebito',
    'comprobanteRetencion',
    'guiaRemision',
    'liquidacionCompra',
  ];

  /// Validates if the given [content] is a valid SRI XML invoice.
  /// Returns null if valid, or an error message if invalid.
  static String? validate(String content) {
    try {
      final document = XmlDocument.parse(content);
      var root = document.rootElement;

      // Handle 'autorizacion' wrapper
      if (root.name.local == 'autorizacion') {
        final comprobante = root.findElements('comprobante').firstOrNull;
        if (comprobante == null) {
          return 'El archivo de autorización no contiene el tag <comprobante>';
        }
        
        // The content inside <comprobante> is usually CDATA containing the actual XML
        final innerXml = comprobante.innerText;
        if (innerXml.trim().isEmpty) {
           return 'El comprobante está vacío';
        }
        
        try {
          final innerDoc = XmlDocument.parse(innerXml);
          root = innerDoc.rootElement;
        } catch (e) {
          return 'El contenido del comprobante no es un XML válido';
        }
      }

      if (!_validRootTags.contains(root.name.local)) {
        return 'El archivo no es un comprobante electrónico válido del SRI (Tag: ${root.name.local})';
      }

      // Check for infoTributaria
      final infoTributaria = root.findElements('infoTributaria').firstOrNull;
      if (infoTributaria == null) {
        return 'El archivo no contiene información tributaria';
      }

      // Check for RUC in infoTributaria
      final ruc = infoTributaria.findElements('ruc').firstOrNull?.innerText;
      if (ruc == null || ruc.isEmpty) {
        return 'El archivo no contiene RUC en la información tributaria';
      }

      return null; // Valid
    } catch (e) {
      return 'El archivo no es un XML válido: ${e.toString()}';
    }
  }

  static Invoice? parse(String content) {
    try {
      final document = XmlDocument.parse(content);
      var root = document.rootElement;

      // Handle 'autorizacion' wrapper
      if (root.name.local == 'autorizacion') {
        final comprobante = root.findElements('comprobante').firstOrNull;
        if (comprobante != null) {
          final innerXml = comprobante.innerText;
          if (innerXml.trim().isNotEmpty) {
            try {
              final innerDoc = XmlDocument.parse(innerXml);
              root = innerDoc.rootElement;
            } catch (_) {}
          }
        }
      }

      final infoTributaria = root.findElements('infoTributaria').first;
      final infoFactura = root.findElements('infoFactura').first;

      final accessKey = infoTributaria.findElements('claveAcceso').first.innerText;
      final date = infoFactura.findElements('fechaEmision').first.innerText;
      final estab = infoTributaria.findElements('estab').first.innerText;
      final ptoEmi = infoTributaria.findElements('ptoEmi').first.innerText;
      final sec = infoTributaria.findElements('secuencial').first.innerText;
      
      final issuerName = infoTributaria.findElements('nombreComercial').firstOrNull?.innerText ?? 
                         infoTributaria.findElements('razonSocial').first.innerText;
      final issuerRuc = infoTributaria.findElements('ruc').first.innerText;
      final total = double.parse(infoFactura.findElements('importeTotal').first.innerText);

      // New fields extraction
      final accountingObligation = infoFactura.findElements('obligadoContabilidad').firstOrNull?.innerText ?? '';
      final matrixAddress = infoTributaria.findElements('dirMatriz').firstOrNull?.innerText ?? '';
      final establishmentAddress = infoFactura.findElements('dirEstablecimiento').firstOrNull?.innerText;
      final customerName = infoFactura.findElements('razonSocialComprador').firstOrNull?.innerText ?? '';
      final customerRuc = infoFactura.findElements('identificacionComprador').firstOrNull?.innerText ?? '';
      
      final subtotal = double.tryParse(infoFactura.findElements('totalSinImpuestos').firstOrNull?.innerText ?? '0') ?? 0.0;
      final totalDiscount = double.tryParse(infoFactura.findElements('totalDescuento').firstOrNull?.innerText ?? '0') ?? 0.0;
      final tip = double.tryParse(infoFactura.findElements('propina').firstOrNull?.innerText ?? '0') ?? 0.0;

      // Calculate IVA
      double iva = 0.0;
      final totalConImpuestos = infoFactura.findElements('totalConImpuestos').firstOrNull;
      if (totalConImpuestos != null) {
        for (final impuesto in totalConImpuestos.findElements('totalImpuesto')) {
          final codigo = impuesto.findElements('codigo').firstOrNull?.innerText;
          if (codigo == '2') { // IVA
            iva += double.tryParse(impuesto.findElements('valor').firstOrNull?.innerText ?? '0') ?? 0.0;
          }
        }
      }

      final details = <InvoiceDetail>[];
      final detallesNode = root.findElements('detalles').firstOrNull;
      if (detallesNode != null) {
        for (final detalle in detallesNode.findElements('detalle')) {
          final mainCode = detalle.findElements('codigoPrincipal').firstOrNull?.innerText ?? '';
          final auxCode = detalle.findElements('codigoAuxiliar').firstOrNull?.innerText ?? '';
          final description = detalle.findElements('descripcion').first.innerText;
          final quantity = double.parse(detalle.findElements('cantidad').first.innerText);
          final unitPrice = double.parse(detalle.findElements('precioUnitario').first.innerText);
          final discount = double.parse(detalle.findElements('descuento').first.innerText);
          final totalPrice = double.parse(detalle.findElements('precioTotalSinImpuesto').first.innerText);

          details.add(InvoiceDetail(
            codigoPrincipal: mainCode,
            codigoAuxiliar: auxCode,
            descripcion: description,
            cantidad: quantity,
            precioUnitario: unitPrice,
            descuento: discount,
            precioTotalSinImpuesto: totalPrice,
          ));
        }
      }

      // Additional Info
      final additionalInfo = <String, String>{};
      final infoAdicionalNode = root.findElements('infoAdicional').firstOrNull;
      if (infoAdicionalNode != null) {
        for (final campo in infoAdicionalNode.findElements('campoAdicional')) {
          final name = campo.getAttribute('nombre') ?? '';
          final value = campo.innerText;
          if (name.isNotEmpty) {
            additionalInfo[name] = value;
          }
        }
      }

      // Payments
      final payments = <Pago>[];
      final pagosNode = infoFactura.findElements('pagos').firstOrNull;
      if (pagosNode != null) {
        for (final pago in pagosNode.findElements('pago')) {
          final method = pago.findElements('formaPago').firstOrNull?.innerText ?? '';
          final total = double.tryParse(pago.findElements('total').firstOrNull?.innerText ?? '0') ?? 0.0;
          final timeUnit = pago.findElements('unidadTiempo').firstOrNull?.innerText ?? '';
          final term = double.tryParse(pago.findElements('plazo').firstOrNull?.innerText ?? '0') ?? 0.0;
          
          payments.add(Pago(
            formaPago: method,
            total: total,
            unidadTiempo: timeUnit,
            plazo: term,
          ));
        }
      }

      return Invoice(
        razonSocial: issuerName,
        nombreComercial: infoTributaria.findElements('nombreComercial').firstOrNull?.innerText ?? '',
        ruc: issuerRuc,
        claveAcceso: accessKey,
        codDoc: infoTributaria.findElements('codDoc').first.innerText,
        estab: estab,
        ptoEmi: ptoEmi,
        secuencial: sec,
        dirMatriz: matrixAddress,
        fechaEmision: date,
        dirEstablecimiento: establishmentAddress ?? '',
        contribuyenteEspecial: infoFactura.findElements('contribuyenteEspecial').firstOrNull?.innerText ?? '',
        obligadoContabilidad: accountingObligation,
        tipoIdentificacionComprador: infoFactura.findElements('tipoIdentificacionComprador').first.innerText,
        razonSocialComprador: customerName,
        identificacionComprador: customerRuc,
        totalSinImpuestos: subtotal,
        totalDescuento: totalDiscount,
        baseImponibleIvaCero: 0.0, // Need to extract if possible, or default
        baseImponibleIva: 0.0, // Need to extract if possible, or default
        valorIVA: iva,
        valorDevolucionIva: 0.0, // Default
        propina: tip,
        importeTotal: total,
        detalle: details,
        numeroAutorizacion: accessKey, // Usually same as access key or extracted
        fechaAutorizacion: date, // Using emission date as fallback or extract from somewhere else if needed
        infoAdicional: additionalInfo,
        pagos: payments,
      );
    } catch (e) {
      return null;
    }
  }
}
