import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:zifra/domain/entities/invoice.dart';

class PdfGeneratorService {
  Future<Uint8List> generatePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final logoImage = await rootBundle.load('assets/images/icon.png');
      logo = pw.MemoryImage(logoImage.buffer.asUint8List());
    } catch (e) {
      // debugPrint('Error loading logo: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            _buildHeader(invoice, logo),
            pw.SizedBox(height: 10),
            _buildCustomerInfo(invoice),
            pw.SizedBox(height: 10),
            _buildDetailsTable(invoice),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 6,
                  child: _buildPaymentInfo(invoice),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  flex: 4,
                  child: _buildTotals(invoice),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            _buildAdditionalInfo(invoice),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Invoice invoice, pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            children: [
              if (logo != null) 
                pw.Container(
                  height: 100,
                  width: 200,
                  alignment: pw.Alignment.center,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Image(logo, fit: pw.BoxFit.contain, height: 80, width: 80),
                      pw.SizedBox(width: 10),
                      pw.Text('Zifra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 40)),
                    ],
                  ),
                )
              else
                pw.Container(
                  height: 100,
                  width: 200,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Text('Logo Unavailable', style: const pw.TextStyle(color: PdfColors.grey)),
                ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(invoice.razonSocial, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Matriz: ${invoice.dirMatriz}', style: const pw.TextStyle(fontSize: 8)),
                    if (invoice.dirEstablecimiento.isNotEmpty)
                      pw.Text('Sucursal: ${invoice.dirEstablecimiento}', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                    pw.Text('OBLIGADO LLEVAR CONTABILIDAD: ${invoice.obligadoContabilidad}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RUC: ${invoice.ruc}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('FACTURA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('No.: ${invoice.secuencial}'), // Using raw secuencial as helper might be gone or different
                pw.SizedBox(height: 4),
                pw.Text('NÚMERO DE AUTORIZACIÓN', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(invoice.numeroAutorizacion, style: const pw.TextStyle(fontSize: 8)), // Was accessKey, but usually numeroAutorizacion is same or similar. SRIinvoice has numeroAutorizacion.
                pw.SizedBox(height: 4),
                pw.Text('FECHA Y HORA DE AUTORIZACIÓN: ${invoice.fechaAutorizacion}', style: const pw.TextStyle(fontSize: 8)), // Was date, but SRIinvoice has fechaAutorizacion
                pw.SizedBox(height: 4),
                // Environment and Emission Type are not in SRIinvoice directly.
                // pw.Text('AMBIENTE: ${invoice.environment}', style: const pw.TextStyle(fontSize: 8)),
                // pw.Text('EMISIÓN: ${invoice.emissionType}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('CLAVE DE ACCESO', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  data: invoice.claveAcceso,
                  barcode: pw.Barcode.code128(),
                  height: 40,
                  drawText: true,
                  textStyle: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('Razón Social / Nombres y Apellidos: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Expanded(child: pw.Text(invoice.razonSocialComprador, style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('RUC / C.I.: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(invoice.identificacionComprador, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(width: 20),
              pw.Text('Fecha Emisión: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(invoice.fechaEmision, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(width: 20),
              // Remission Guide not in SRIinvoice
              // pw.Text('Guía Remisión: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              // pw.Text(invoice.remissionGuide ?? '--', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 4),
          // Customer Address not in SRIinvoice
          // pw.Row(
          //   children: [
          //     pw.Text('Dirección: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          //     pw.Expanded(child: pw.Text(invoice.customerAddress, style: const pw.TextStyle(fontSize: 9))),
          //   ],
          // ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailsTable(Invoice invoice) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      data: <List<String>>[
        <String>['Cod. Principal', 'Cod. Auxiliar', 'Cant.', 'Descripción', 'Precio Unitario', 'Desc.', 'Precio Total'],
        ...invoice.detalle.map((item) => [
          item.codigoPrincipal,
          '--', // auxCode not in SRIinvoiceDetail
          item.cantidad.toStringAsFixed(2),
          item.descripcion,
          item.precioUnitario.toStringAsFixed(2),
          item.descuento.toStringAsFixed(2),
          item.precioTotalSinImpuesto.toStringAsFixed(2),
        ]),
      ],
    );
  }

  pw.Widget _buildAdditionalInfo(Invoice invoice) {
    if (invoice.infoAdicional.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Información Adicional', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.SizedBox(height: 4),
          ...invoice.infoAdicional.entries.map((entry) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 100, child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 8))),
              pw.Expanded(child: pw.Text(entry.value, style: const pw.TextStyle(fontSize: 8))),
            ],
          )),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentInfo(Invoice invoice) {
    if (invoice.pagos.isEmpty) return pw.SizedBox();

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      data: <List<String>>[
        <String>['Forma de pago', 'Total', 'Plazo', 'Unidad de tiempo'],
        ...invoice.pagos.map((p) => [
          _getPaymentMethodDescription(p.formaPago),
          p.total.toStringAsFixed(2),
          p.plazo.toString(),
          p.unidadTiempo,
        ]),
      ],
    );
  }

  pw.Widget _buildTotals(Invoice invoice) {
    const labelStyle = pw.TextStyle(fontSize: 9);
    const valueStyle = pw.TextStyle(fontSize: 9);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: [
        _buildTotalRow('SUBTOTAL 12%', invoice.baseImponibleIva.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL 0%', invoice.baseImponibleIvaCero.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL NO OBJETO IVA', '0.00', labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL EXENTO IVA', '0.00', labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL SIN IMPUESTOS', invoice.totalSinImpuestos.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('TOTAL DESCUENTO', invoice.totalDescuento.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('ICE', '0.00', labelStyle, valueStyle),
        _buildTotalRow('IVA', invoice.valorIVA.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('PROPINA', invoice.propina.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('VALOR TOTAL', invoice.importeTotal.toStringAsFixed(2), labelStyle, valueStyle),
      ],
    );
  }

  pw.TableRow _buildTotalRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label, style: labelStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value, style: valueStyle, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }
  String _getPaymentMethodDescription(String code) {
    const paymentMethods = {
      '01': 'SIN UTILIZACION DEL SISTEMA FINANCIERO',
      '15': 'COMPENSACIÓN DE DEUDAS',
      '16': 'TARJETA DE DÉBITO',
      '17': 'DINERO ELECTRÓNICO',
      '18': 'TARJETA PREPAGO',
      '19': 'TARJETA DE CRÉDITO',
      '20': 'OTROS CON UTILIZACION DEL SISTEMA FINANCIERO',
      '21': 'ENDOSO DE TÍTULOS',
    };
    return paymentMethods[code] ?? code;
  }
}
