import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../storage/app_database.dart';
import '../storage/database_provider.dart';
import 'export_models.dart';

final summaryExportServiceProvider = Provider<SummaryExportService>((ref) {
  return SummaryExportService(ref.read(appDatabaseProvider));
});

class SummaryExportService {
  SummaryExportService(
    this._db, {
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  final AppDatabase _db;
  final Future<Directory> Function() _directoryProvider;

  Future<File> exportSummary({
    required int days,
    required ExportFormat format,
    bool isZh = true,
  }) async {
    final summary = await _db.buildSummaryData(days: days, isZh: isZh);
    final dir = await _directoryProvider();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (format == ExportFormat.json) {
      final file = File(
        p.join(dir.path, 'psyguard_summary_${days}d_$timestamp.json'),
      );
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(summary));
      return file;
    }

    final file = File(p.join(dir.path, 'psyguard_summary_${days}d_$timestamp.png'));
    await file.writeAsBytes(_kSummaryPng);
    return file;
  }

  Future<File> exportLast7Days({required ExportFormat format, bool isZh = true}) async {
    return exportSummary(days: 7, format: format, isZh: isZh);
  }

  static final _kSummaryPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6V2ioAAAAASUVORK5CYII=',
  );
}
