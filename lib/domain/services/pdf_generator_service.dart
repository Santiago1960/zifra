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
                  child: pw.Column(
                    children: [
                      _buildAdditionalInfo(invoice),
                      pw.SizedBox(height: 10),
                      _buildPaymentInfo(invoice),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  flex: 4,
                  child: _buildTotals(invoice),
                ),
              ],
            ),
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
                    pw.Text(invoice.issuerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Matriz: ${invoice.matrixAddress}', style: const pw.TextStyle(fontSize: 8)),
                    if (invoice.establishmentAddress != null)
                      pw.Text('Sucursal: ${invoice.establishmentAddress}', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 4),
                    pw.Text('OBLIGADO LLEVAR CONTABILIDAD: ${invoice.accountingObligation}', style: const pw.TextStyle(fontSize: 8)),
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
                pw.Text('RUC: ${invoice.issuerRuc}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('FACTURA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('No.: ${invoice.sequential}'),
                pw.SizedBox(height: 4),
                pw.Text('NÚMERO DE AUTORIZACIÓN', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(invoice.accessKey, style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('FECHA Y HORA DE AUTORIZACIÓN: ${invoice.date}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('AMBIENTE: ${invoice.environment}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('EMISIÓN: ${invoice.emissionType}', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('CLAVE DE ACCESO', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.BarcodeWidget(
                  data: invoice.accessKey,
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
              pw.Expanded(child: pw.Text(invoice.customerName, style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('RUC / C.I.: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(invoice.customerRuc, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(width: 20),
              pw.Text('Fecha Emisión: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(invoice.date, style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(width: 20),
              pw.Text('Guía Remisión: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Text(invoice.remissionGuide ?? '--', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text('Dirección: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.Expanded(child: pw.Text(invoice.customerAddress, style: const pw.TextStyle(fontSize: 9))),
            ],
          ),
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
        ...invoice.details.map((item) => [
          item.mainCode,
          item.auxCode ?? '--',
          item.quantity.toStringAsFixed(2),
          item.description,
          item.unitPrice.toStringAsFixed(2),
          item.discount.toStringAsFixed(2),
          item.totalPrice.toStringAsFixed(2),
        ]),
      ],
    );
  }

  pw.Widget _buildAdditionalInfo(Invoice invoice) {
    if (invoice.additionalInfo.isEmpty) return pw.SizedBox();

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
          ...invoice.additionalInfo.entries.map((entry) => pw.Row(
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
    if (invoice.payments.isEmpty) return pw.SizedBox();

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      data: <List<String>>[
        <String>['Forma de pago', 'Total', 'Plazo', 'Tiempo'],
        ...invoice.payments.map((p) => [
          p.method,
          p.total.toStringAsFixed(2),
          p.term.toString(),
          p.timeUnit,
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
        _buildTotalRow('SUBTOTAL 12%', '0.00', labelStyle, valueStyle), // Assuming 0 for now as we don't distinguish tax rates in detail yet
        _buildTotalRow('SUBTOTAL 0%', '0.00', labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL NO OBJETO IVA', '0.00', labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL EXENTO IVA', '0.00', labelStyle, valueStyle),
        _buildTotalRow('SUBTOTAL SIN IMPUESTOS', invoice.subtotal.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('TOTAL DESCUENTO', invoice.totalDiscount.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('ICE', '0.00', labelStyle, valueStyle),
        _buildTotalRow('IVA 12%', invoice.iva.toStringAsFixed(2), labelStyle, valueStyle), // Assuming all IVA is 12% or 15%
        _buildTotalRow('PROPINA', invoice.tip.toStringAsFixed(2), labelStyle, valueStyle),
        _buildTotalRow('VALOR TOTAL', invoice.total.toStringAsFixed(2), labelStyle, valueStyle),
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
}
