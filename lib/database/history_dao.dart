import 'package:sqflite/sqflite.dart';

import '../models/history_model.dart';
import '../models/schedule_model.dart';
import 'database_tables.dart';
import 'schedule_created_at_store.dart';

/// DAO operasi riwayat pelaksanaan dan status jadwal harian Dashboard.
class HistoryDao {
  static const List<String> _fullDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _shortDays = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Ahd',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final Future<Database> Function() _getDb;
  final Future<List<ScheduleModel>> Function() _getAllSchedules;
  final ScheduleCreatedAtStore _createdAtStore;
  final void Function() _onChanged;

  HistoryDao(
    this._getDb,
    this._getAllSchedules,
    this._createdAtStore,
    this._onChanged,
  );

  String _formatIndonesianDate(DateTime date) =>
      '${_fullDays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Mengambil seluruh riwayat pelaksanaan.
  Future<List<HistoryModel>> getAll() async {
    final db = await _getDb();
    final maps = await db.query(DatabaseTables.tableRiwayat, orderBy: 'id DESC');

    return maps.map((row) {
      return HistoryModel(
        id: (row['id'] as int).toString(),
        title: row['nama'] as String,
        date: row['tanggal'] as String,
        scheduledTime: row['jam_terjadwal'] as String,
        actualTime: row['jam_terlaksana'] as String,
        isCompleted: (row['status'] as String).toLowerCase() == 'terlaksana',
      );
    }).toList();
  }

  /// Menambah riwayat ibadah baru.
  Future<int> insert(HistoryModel history, {int? jadwalId}) async {
    final db = await _getDb();
    final id = await db.insert(DatabaseTables.tableRiwayat, {
      'jadwal_id': jadwalId,
      'nama': history.title,
      'tanggal': history.date,
      'jam_terjadwal': history.scheduledTime,
      'jam_terlaksana': history.actualTime,
      'status': history.isCompleted ? 'terlaksana' : 'terlewat',
    });
    _onChanged();
    return id;
  }

  /// Mengubah status suatu riwayat (Terlaksana <-> Terlewat).
  Future<int> updateStatus({
    required String id,
    required bool isCompleted,
    required String actualTime,
  }) async {
    final db = await _getDb();
    final int? historyId = int.tryParse(id);
    if (historyId == null) return 0;

    final count = await db.update(
      DatabaseTables.tableRiwayat,
      {
        'status': isCompleted ? 'terlaksana' : 'terlewat',
        'jam_terlaksana': actualTime,
      },
      where: 'id = ?',
      whereArgs: [historyId],
    );
    _onChanged();
    return count;
  }

  /// Mencatat atau memperbarui status "Terlaksana" dari notifikasi.
  Future<HistoryModel> markCompletedFromNotification({
    int? jadwalId,
    required String title,
    required String scheduledTime,
  }) async {
    final db = await _getDb();
    final now = DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final actualTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Hindari duplikasi jika notifikasi yang sama diketuk ulang hari ini.
    final List<Map<String, dynamic>> existing = jadwalId != null
        ? await db.query(
            DatabaseTables.tableRiwayat,
            where: 'jadwal_id = ? AND tanggal = ?',
            whereArgs: [jadwalId, todayDate],
            limit: 1,
          )
        : await db.query(
            DatabaseTables.tableRiwayat,
            where: 'nama = ? AND jam_terjadwal = ? AND tanggal = ?',
            whereArgs: [title, scheduledTime, todayDate],
            limit: 1,
          );

    if (existing.isNotEmpty) {
      final int rowId = existing.first['id'] as int;
      await db.update(
        DatabaseTables.tableRiwayat,
        {'status': 'terlaksana', 'jam_terlaksana': actualTime},
        where: 'id = ?',
        whereArgs: [rowId],
      );
      _onChanged();
      return HistoryModel(
        id: rowId.toString(),
        title: title,
        date: todayDate,
        scheduledTime: scheduledTime,
        actualTime: actualTime,
        isCompleted: true,
      );
    }

    final int newId = await db.insert(DatabaseTables.tableRiwayat, {
      'jadwal_id': jadwalId,
      'nama': title,
      'tanggal': todayDate,
      'jam_terjadwal': scheduledTime,
      'jam_terlaksana': actualTime,
      'status': 'terlaksana',
    });
    _onChanged();

    return HistoryModel(
      id: newId.toString(),
      title: title,
      date: todayDate,
      scheduledTime: scheduledTime,
      actualTime: actualTime,
      isCompleted: true,
    );
  }

  DateTime? _deadlineForToday(ScheduleModel schedule, DateTime now) {
    final timeParts = schedule.time.split(':');
    if (timeParts.length < 2) return null;
    final int? hour = int.tryParse(timeParts[0]);
    final int? minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return null;

    final int delayMinutes =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;
    return DateTime(now.year, now.month, now.day, hour, minute)
        .add(Duration(minutes: delayMinutes));
  }

  bool _isCreatedAfterTodayDeadline(
    int? jadwalId,
    DateTime now,
    DateTime deadline,
    Map<int, DateTime> createdAtMap,
  ) {
    if (jadwalId == null) return false;
    final createdAt = createdAtMap[jadwalId];
    return createdAt != null &&
        _isSameDay(createdAt, now) &&
        createdAt.isAfter(deadline);
  }

  /// Menandai jadwal aktif hari ini sebagai "Terlewat" setelah melewati jam + jeda_delay.
  Future<int> markMissedForToday({DateTime? nowOverride}) async {
    final db = await _getDb();
    final now = nowOverride ?? DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final todayShortDay = _shortDays[now.weekday - 1];

    final schedules = await _getAllSchedules();
    final createdAtMap = await _createdAtStore.loadAll();
    int insertedCount = 0;

    for (final schedule in schedules) {
      if (!schedule.isActive || !schedule.days.contains(todayShortDay)) {
        continue;
      }

      final int? jadwalId = int.tryParse(schedule.id);
      if (jadwalId == null) continue;

      final deadline = _deadlineForToday(schedule, now);
      if (deadline == null || !now.isAfter(deadline)) continue;

      if (_isCreatedAfterTodayDeadline(jadwalId, now, deadline, createdAtMap)) {
        continue;
      }

      final existing = await db.query(
        DatabaseTables.tableRiwayat,
        where: 'jadwal_id = ? AND tanggal = ?',
        whereArgs: [jadwalId, todayDate],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert(DatabaseTables.tableRiwayat, {
          'jadwal_id': jadwalId,
          'nama': schedule.title,
          'tanggal': todayDate,
          'jam_terjadwal': schedule.time,
          'jam_terlaksana': '-',
          'status': 'terlewat',
        });
        insertedCount++;
      }
    }

    if (insertedCount > 0) _onChanged();
    return insertedCount;
  }

  /// Mengambil jadwal aktif hari ini beserta statusnya untuk Dashboard.
  Future<List<TodayScheduleItem>> getTodayDashboardSchedules({
    DateTime? nowOverride,
  }) async {
    final db = await _getDb();
    final now = nowOverride ?? DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final todayShortDay = _shortDays[now.weekday - 1];

    final allSchedules = await _getAllSchedules();
    final createdAtMap = await _createdAtStore.loadAll();
    final todaySchedules = allSchedules
        .where((s) => s.isActive && s.days.contains(todayShortDay))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final todayHistories = await db.query(
      DatabaseTables.tableRiwayat,
      where: 'tanggal = ?',
      whereArgs: [todayDate],
    );

    final Map<int, String> statusByJadwalId = {};
    final Map<String, String> statusByTitleTime = {};
    for (final row in todayHistories) {
      final status = (row['status'] as String).toLowerCase();
      final int? jadwalId = row['jadwal_id'] as int?;
      if (jadwalId != null) {
        statusByJadwalId[jadwalId] = status;
      }
      statusByTitleTime['${row['nama']}|${row['jam_terjadwal']}'] = status;
    }

    final List<TodayScheduleItem> items = [];
    for (final schedule in todaySchedules) {
      final int? jadwalId = int.tryParse(schedule.id);
      final String? recordedStatus = (jadwalId != null
              ? statusByJadwalId[jadwalId]
              : null) ??
          statusByTitleTime['${schedule.title}|${schedule.time}'];

      if (recordedStatus == null) {
        final deadline = _deadlineForToday(schedule, now);
        if (deadline != null &&
            _isCreatedAfterTodayDeadline(jadwalId, now, deadline, createdAtMap)) {
          continue;
        }
      }

      final TodayScheduleStatus status;
      if (recordedStatus == 'terlaksana') {
        status = TodayScheduleStatus.terlaksana;
      } else if (recordedStatus == 'terlewat') {
        status = TodayScheduleStatus.terlewat;
      } else {
        status = TodayScheduleStatus.belumWaktunya;
      }

      items.add(TodayScheduleItem(
        title: schedule.title,
        time: schedule.time,
        status: status,
      ));
    }
    return items;
  }
}
