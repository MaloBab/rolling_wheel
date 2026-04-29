// lib/utils/import_export.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';

// ──────────────────────────────────────────────
// Export
// ──────────────────────────────────────────────

/// Sérialise un [WheelGroup] en JSON formaté.
String groupToJson(WheelGroup group) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert({
    'spingroups_version': 1,
    'exported_at': DateTime.now().toIso8601String(),
    'group': group.toJson(),
  });
}

Future<void> shareGroup(WheelGroup group) async {
  if (kIsWeb) {
    throw UnsupportedError('Export web: utiliser exportGroupAsString().');
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

String exportGroupAsString(WheelGroup group) => groupToJson(group);

// ──────────────────────────────────────────────
// Import
// ──────────────────────────────────────────────

class ImportResult {
  final WheelGroup? group;
  final String? error;

  const ImportResult({this.group, this.error});
  bool get success => group != null;
}

/// Ouvre le sélecteur de fichier et tente d'importer un groupe.
Future<ImportResult> importGroupFromFile() async {
  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'spingroup'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const ImportResult(error: 'Aucun fichier sélectionné.');
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      return const ImportResult(error: 'Impossible de lire le fichier.');
    }

    final raw = utf8.decode(bytes);
    return importGroupFromString(raw);
  } catch (e) {
    return ImportResult(error: 'Erreur : $e');
  }
}

/// Parse un JSON brut et retourne un [WheelGroup].
ImportResult importGroupFromString(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;

    // Support format direct (juste le groupe) ou enveloppé
    final groupMap = map.containsKey('group')
        ? map['group'] as Map<String, dynamic>
        : map;

    final group = WheelGroup.fromJson(groupMap);
    return ImportResult(group: group);
  } on FormatException catch (e) {
    return ImportResult(error: 'JSON invalide : ${e.message}');
  } catch (e) {
    return ImportResult(error: 'Format non reconnu : $e');
  }
}