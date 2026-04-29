// lib/data/repositories/group_repository.dart
//
// Couche de persistence isolée. Le provider ne manipule jamais
// SharedPreferences directement : il passe par ce repository.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

abstract interface class GroupRepository {
  Future<List<WheelGroup>> loadAll();
  Future<void> saveAll(List<WheelGroup> groups);
}

final class SharedPrefsGroupRepository implements GroupRepository {
  @override
  Future<List<WheelGroup>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPrefsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WheelGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveAll(List<WheelGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(groups.map((g) => g.toJson()).toList());
    await prefs.setString(kPrefsKey, raw);
  }
}