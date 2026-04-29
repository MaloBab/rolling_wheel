// lib/data/services/import_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';


sealed class ImportResult {
  const ImportResult();
}

final class ImportSuccess extends ImportResult {
  final WheelGroup group;
  const ImportSuccess(this.group);
}

final class ImportFailure extends ImportResult {
  final String message;
  const ImportFailure(this.message);
}


abstract final class ImportExportService {
  static String groupToJson(WheelGroup group) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'spingroups_version': kExportVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'group': group.toJson(),
    });
  }

  static Future<void> shareGroup(WheelGroup group) async {
    if (kIsWeb) {
      throw UnsupportedError('Export web : utiliser groupToJson() à la place.');
    }
    final json = groupToJson(group);
    final safeName = group.name.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName.spingroup.json');
    await file.writeAsString(json, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'SpinGroups — ${group.name}',
      ),
    );
  }

  static Future<ImportResult> importFromFile() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kImportExtensions,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        return const ImportFailure('Aucun fichier sélectionné.');
      }
      final bytes = picked.files.first.bytes;
      if (bytes == null) {
        return const ImportFailure('Impossible de lire le fichier.');
      }
      return importFromString(utf8.decode(bytes));
    } catch (e) {
      return ImportFailure('Erreur : $e');
    }
  }

  static ImportResult importFromString(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final groupMap =
          map.containsKey('group') ? map['group'] as Map<String, dynamic> : map;
      return ImportSuccess(WheelGroup.fromJson(groupMap));
    } on FormatException catch (e) {
      return ImportFailure('JSON invalide : ${e.message}');
    } catch (e) {
      return ImportFailure('Format non reconnu : $e');
    }
  }
}