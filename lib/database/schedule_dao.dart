import 'package:sqflite/sqflite.dart';

import '../models/schedule_model.dart';
import 'database_tables.dart';
import 'schedule_created_at_store.dart';

/// DAO operasi CRUD untuk tabel `jadwal_ibadah` dan `hari_jadwal`.
class ScheduleDao {
  static const Map<String, String> shortToDbDay = {
    'Sen': 'senin',
    'Sel': 'selasa',
    'Rab': 'rabu',
    'Kam': 'kamis',
    'Jum': 'jumat',
    'Sab': 'sabtu',
    'Ahd': 'ahad',
  };

  static const Map<String, String> _dbToShortDay = {
    'senin': 'Sen',
    'selasa': 'Sel',
    'rabu': 'Rab',
    'kamis': 'Kam',
    'jumat': 'Jum',
    'sabtu': 'Sab',
    'ahad': 'Ahd',
  };

  /// Mengonversi label hari UI ('Sen') ke enum ERD di DB ('senin').
  static String toDbDayName(String day) {
    final trimmed = day.trim();
    return shortToDbDay[trimmed] ?? trimmed.toLowerCase();
  }

  /// Mengonversi enum ERD di DB ('senin') ke label singkat UI ('Sen').
  static String toDisplayDayName(String dbDay) {
    final normalized = dbDay.trim().toLowerCase();
    return _dbToShortDay[normalized] ?? dbDay;
  }

  final Future<Database> Function() _getDb;
  final ScheduleCreatedAtStore _createdAtStore;
  final void Function() _onChanged;

  ScheduleDao(this._getDb, this._createdAtStore, this._onChanged);

  int _parseDelay(String snooze) =>
      int.tryParse(snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

  /// Mengambil semua jadwal beserta harinya (2 query).
  Future<List<ScheduleModel>> getAll() async {
    final db = await _getDb();
    final schedulesMap =
        await db.query(DatabaseTables.tableJadwal, orderBy: 'id ASC');
    if (schedulesMap.isEmpty) return [];

    final allDaysMap = await db.query(DatabaseTables.tableHari);
    final Map<int, List<String>> daysByScheduleId = {};
    for (final row in allDaysMap) {
      final int jadwalId = row['jadwal_id'] as int;
      daysByScheduleId
          .putIfAbsent(jadwalId, () => <String>[])
          .add(toDisplayDayName(row['nama_hari'] as String));
    }

    return schedulesMap.map((row) {
      final int scheduleId = row['id'] as int;
      return ScheduleModel(
        id: scheduleId.toString(),
        title: row['nama_jadwal'] as String,
        time: row['jam_pengingat'] as String,
        days: daysByScheduleId[scheduleId] ?? <String>[],
        description: (row['deskripsi'] as String?) ?? '',
        snooze: '${row['jeda_delay']} Menit',
        isActive: (row['is_active'] as int) == 1,
      );
    }).toList();
  }

  /// Menambah jadwal baru beserta harinya.
  Future<ScheduleModel> insert(
    ScheduleModel schedule, {
    DateTime? nowOverride,
  }) async {
    final db = await _getDb();
    final int newId = await db.insert(DatabaseTables.tableJadwal, {
      'nama_jadwal': schedule.title,
      'deskripsi': schedule.description,
      'jam_pengingat': schedule.time,
      'jeda_delay': _parseDelay(schedule.snooze),
      'is_active': schedule.isActive ? 1 : 0,
    });

    for (final hari in schedule.days) {
      await db.insert(DatabaseTables.tableHari, {
        'jadwal_id': newId,
        'nama_hari': toDbDayName(hari),
      });
    }

    await _createdAtStore.save(newId, nowOverride ?? DateTime.now());
    _onChanged();
    return schedule.copyWith(id: newId.toString());
  }

  /// Memperbarui jadwal dan daftar harinya.
  Future<int> update(ScheduleModel schedule) async {
    final db = await _getDb();
    final int? scheduleId = int.tryParse(schedule.id);
    if (scheduleId == null) return 0;

    final count = await db.update(
      DatabaseTables.tableJadwal,
      {
        'nama_jadwal': schedule.title,
        'deskripsi': schedule.description,
        'jam_pengingat': schedule.time,
        'jeda_delay': _parseDelay(schedule.snooze),
        'is_active': schedule.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );

    await db.delete(
      DatabaseTables.tableHari,
      where: 'jadwal_id = ?',
      whereArgs: [scheduleId],
    );
    for (final hari in schedule.days) {
      await db.insert(DatabaseTables.tableHari, {
        'jadwal_id': scheduleId,
        'nama_hari': toDbDayName(hari),
      });
    }

    _onChanged();
    return count;
  }

  /// Mengubah status aktif/nonaktif jadwal.
  Future<int> toggleActive(String id, bool isActive) async {
    final db = await _getDb();
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    final count = await db.update(
      DatabaseTables.tableJadwal,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
    _onChanged();
    return count;
  }

  /// Menghapus jadwal (hari_jadwal terhapus otomatis via CASCADE).
  Future<int> delete(String id) async {
    final db = await _getDb();
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    final count = await db.delete(
      DatabaseTables.tableJadwal,
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
    await _createdAtStore.remove(scheduleId);
    _onChanged();
    return count;
  }
}
