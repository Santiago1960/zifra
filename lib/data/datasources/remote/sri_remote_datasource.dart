import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zifra/core/config.dart';
import 'package:zifra/presentation/widgets/sri_password_dialog.dart';

/// Resultado de la descarga: resumen por período.
class SriDownloadResult {
  final List<SriPeriodResult> periods;
  final int totalDescargadas;
  final int totalDuplicadas;
  final int totalErrores;

  const SriDownloadResult({
    required this.periods,
    required this.totalDescargadas,
    required this.totalDuplicadas,
    required this.totalErrores,
  });

  factory SriDownloadResult.fromJson(Map<String, dynamic> json) => SriDownloadResult(
        periods: ((json['periods'] ?? json['data']?['periods']) as List? ?? [])
            .map((p) => SriPeriodResult.fromJson(p as Map<String, dynamic>))
            .toList(),
        totalDescargadas: (json['totalDescargadas'] ?? json['data']?['totalDescargadas'] ?? 0) as int,
        totalDuplicadas:  (json['totalDuplicadas']  ?? json['data']?['totalDuplicadas']  ?? 0) as int,
        totalErrores:     (json['totalErrores']     ?? json['data']?['totalErrores']     ?? 0) as int,
      );
}

class SriPeriodResult {
  final int year;
  final int month;
  final int descargadas;
  final int duplicadas;
  final int errores;

  const SriPeriodResult({
    required this.year,
    required this.month,
    required this.descargadas,
    required this.duplicadas,
    required this.errores,
  });

  factory SriPeriodResult.fromJson(Map<String, dynamic> json) => SriPeriodResult(
        year:        json['year']        as int,
        month:       json['month']       as int,
        descargadas: json['descargadas'] as int,
        duplicadas:  json['duplicadas']  as int,
        errores:     json['errores']     as int,
      );
}

abstract class SriRemoteDataSource {
  Future<SriDownloadResult> downloadAndSave({
    required String ruc,
    required String password,
    required int projectId,
    required List<SriPeriod> periods,
  });
}

class SriRemoteDataSourceImpl implements SriRemoteDataSource {
  @override
  Future<SriDownloadResult> downloadAndSave({
    required String ruc,
    required String password,
    required int projectId,
    required List<SriPeriod> periods,
  }) async {
    final url = Uri.parse('${Config.serverUrl}/sri/downloadAndSave');
    debugPrint('SRI: POST $url');
    try {
      final body = jsonEncode({
        'ruc': ruc,
        'password': password,
        'projectId': projectId,
        'periods': periods.map((p) => {'year': p.year, 'month': p.month}).toList(),
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint('SRI: ${response.statusCode} — ${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Serverpod envuelve la respuesta en { data: ... }
        final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        return SriDownloadResult.fromJson(data as Map<String, dynamic>);
      }

      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('SRI Exception: $e');
      rethrow;
    }
  }
}
