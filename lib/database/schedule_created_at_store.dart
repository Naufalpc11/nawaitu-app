import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Menyimpan waktu pembuatan tiap jadwal secara lokal (di luar skema tabel ERD).
class ScheduleCreatedAtStore {
  Map<int, DateTime>? _cache;

  Future<File> _file() async {
    final dbPath = await getDatabasesPath();
    return File(join(dbPath, 'schedule_created_at.json'));
  }

  Future<Map<int, DateTime>> loadAll() async {
    if (_cache != null) return _cache!;
    final file = await _file();
    if (!await file.exists()) {
      _cache = {};
      return _cache!;
    }
    try {
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _cache = {
        for (final e in raw.entries)
          if (int.tryParse(e.key) != null &&
              DateTime.tryParse(e.value.toString()) != null)
            int.parse(e.key): DateTime.parse(e.value.toString()),
      };
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _write(Map<int, DateTime> map) async {
    _cache = map;
    final file = await _file();
    await file.parent.create(recursive: true);
    final encoded = jsonEncode({
      for (final e in map.entries) e.key.toString(): e.value.toIso8601String(),
    });
    await file.writeAsString(encoded);
  }

  Future<void> save(int id, DateTime createdAt) async {
    final map = Map<int, DateTime>.from(await loadAll());
    map[id] = createdAt;
    await _write(map);
  }

  Future<void> remove(int id) async {
    final map = Map<int, DateTime>.from(await loadAll());
    if (map.remove(id) != null) {
      await _write(map);
    }
  }

  Future<void> clear() async {
    _cache = {};
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
