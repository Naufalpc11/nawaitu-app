import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_model.dart';
import '../models/schedule_model.dart';
import 'database_tables.dart';

/// DatabaseHelper adalah Singleton Controller untuk mengelola SQLite Database Lokal Nawaitu.
/// Menyediakan koneksi database dan antarmuka operasi CRUD lengkap untuk Jadwal dan Riwayat.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Notifier agar DashboardScreen & HistoryScreen otomatis refresh saat riwayat berubah (misal dari tap notifikasi)
  final ValueNotifier<int> historyChangeNotifier = ValueNotifier<int>(0);

  /// Notifier agar DashboardScreen otomatis refresh saat jadwal ditambah, diedit, dihapus, atau di-toggle
  final ValueNotifier<int> scheduleChangeNotifier = ValueNotifier<int>(0);

  DatabaseHelper._init();

  /// Mendapatkan instance database SQLite (lazily opened)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nawaitu.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        // Mengaktifkan fitur Foreign Key constraint di SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Membuat tabel kosong murni dari awal (tanpa data tiruan)
        await DatabaseTables.createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // Skema lama (< v3) tidak kompatibel, buat ulang tabel
          await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableHari}');
          await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableRiwayat}');
          await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableJadwal}');
          await DatabaseTables.createTables(db);
          return;
        }
        if (oldVersion < 4) {
          // Migrasi v3 -> v4: ubah nama_hari singkatan ('Sen'..'Ahd') ke enum ERD ('senin'..'ahad')
          for (final entry in _shortToDbDay.entries) {
            await db.update(
              DatabaseTables.tableHari,
              {'nama_hari': entry.value},
              where: 'nama_hari = ?',
              whereArgs: [entry.key],
            );
          }
        }
        if (oldVersion < 5) {
          // Migrasi v4 -> v5: ubah nama kolom 'title' menjadi 'nama' pada riwayat_pelaksanaan
          await db.execute(
            'ALTER TABLE ${DatabaseTables.tableRiwayat} RENAME COLUMN title TO nama',
          );
        }
      },
    );
  }

  /// Menghapus seluruh data agar kembali bersih dari awal (Reset Database)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseTables.tableHari);
    await db.delete(DatabaseTables.tableRiwayat);
    await db.delete(DatabaseTables.tableJadwal);
  }

  // ==========================================
  // OPERASI CRUD: JADWAL IBADAH & HARI
  // ==========================================

  static const Map<String, String> _shortToDbDay = {
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

  /// Mengonversi label hari UI ('Sen') ke nilai enum ERD di DB ('senin')
  static String toDbDayName(String day) {
    final trimmed = day.trim();
    return _shortToDbDay[trimmed] ?? trimmed.toLowerCase();
  }

  /// Mengonversi nilai enum ERD di DB ('senin') ke label singkat UI ('Sen')
  static String toDisplayDayName(String dbDay) {
    final normalized = dbDay.trim().toLowerCase();
    return _dbToShortDay[normalized] ?? dbDay;
  }

  /// Mengambil semua jadwal ibadah beserta list harinya (2 query, tanpa N+1)
  Future<List<ScheduleModel>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> schedulesMap =
        await db.query(DatabaseTables.tableJadwal, orderBy: 'id ASC');
    if (schedulesMap.isEmpty) return [];

    final List<Map<String, dynamic>> allDaysMap =
        await db.query(DatabaseTables.tableHari);
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

  /// Menambah jadwal ibadah baru beserta relasi harinya
  Future<ScheduleModel> insertSchedule(ScheduleModel schedule) async {
    final db = await database;

    final int jedaDelay =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

    // 1. Simpan ke tabel jadwal_ibadah
    final int newId = await db.insert(DatabaseTables.tableJadwal, {
      'nama_jadwal': schedule.title,
      'deskripsi': schedule.description,
      'jam_pengingat': schedule.time,
      'jeda_delay': jedaDelay,
      'is_active': schedule.isActive ? 1 : 0,
    });

    // 2. Simpan hari-hari terpilih ke tabel hari_jadwal (format enum ERD: 'senin'..'ahad')
    for (var hari in schedule.days) {
      await db.insert(DatabaseTables.tableHari, {
        'jadwal_id': newId,
        'nama_hari': toDbDayName(hari),
      });
    }

    scheduleChangeNotifier.value++;
    return schedule.copyWith(id: newId.toString());
  }

  /// Mengupdate jadwal ibadah yang ada beserta relasi harinya
  Future<int> updateSchedule(ScheduleModel schedule) async {
    final db = await database;
    final int? scheduleId = int.tryParse(schedule.id);
    if (scheduleId == null) return 0;

    final int jedaDelay =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

    // 1. Update data utama jadwal
    final count = await db.update(
      DatabaseTables.tableJadwal,
      {
        'nama_jadwal': schedule.title,
        'deskripsi': schedule.description,
        'jam_pengingat': schedule.time,
        'jeda_delay': jedaDelay,
        'is_active': schedule.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );

    // 2. Hapus hari lama dan masukkan hari baru
    await db.delete(
      DatabaseTables.tableHari,
      where: 'jadwal_id = ?',
      whereArgs: [scheduleId],
    );
    for (var hari in schedule.days) {
      await db.insert(DatabaseTables.tableHari, {
        'jadwal_id': scheduleId,
        'nama_hari': toDbDayName(hari),
      });
    }

    scheduleChangeNotifier.value++;
    return count;
  }

  /// Toggle status aktif/nonaktif jadwal
  Future<int> toggleScheduleActive(String id, bool isActive) async {
    final db = await database;
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    final count = await db.update(
      DatabaseTables.tableJadwal,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
    scheduleChangeNotifier.value++;
    return count;
  }

  /// Menghapus jadwal ibadah (otomatis cascade menghapus hari_jadwal)
  Future<int> deleteSchedule(String id) async {
    final db = await database;
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    final count = await db.delete(
      DatabaseTables.tableJadwal,
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
    scheduleChangeNotifier.value++;
    return count;
  }

  // ==========================================
  // OPERASI CRUD: RIWAYAT PELAKSANAAN
  // ==========================================

  /// Mengambil semua data riwayat pelaksanaan
  Future<List<HistoryModel>> getAllHistories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseTables.tableRiwayat, orderBy: 'id DESC');

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

  /// Menambah riwayat ibadah baru
  Future<int> insertHistory(HistoryModel history, {int? jadwalId}) async {
    final db = await database;
    final id = await db.insert(DatabaseTables.tableRiwayat, {
      'jadwal_id': jadwalId,
      'nama': history.title,
      'tanggal': history.date,
      'jam_terjadwal': history.scheduledTime,
      'jam_terlaksana': history.actualTime,
      'status': history.isCompleted ? 'terlaksana' : 'terlewat',
    });
    historyChangeNotifier.value++;
    return id;
  }

  /// Mengubah status suatu riwayat (Terlaksana <-> Terlewat)
  Future<int> updateHistoryStatus({
    required String id,
    required bool isCompleted,
    required String actualTime,
  }) async {
    final db = await database;
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
    historyChangeNotifier.value++;
    return count;
  }

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

  String _formatIndonesianDate(DateTime date) {
    return '${_fullDays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
  }

  /// Mencatat atau memperbarui ibadah sebagai "Terlaksana" saat user menekan notifikasi
  Future<HistoryModel> markCompletedFromNotification({
    int? jadwalId,
    required String title,
    required String scheduledTime,
  }) async {
    final db = await database;
    final now = DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final actualTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Cek apakah hari ini sudah ada catatan untuk jadwal ini agar tidak duplikat jika notif ditekan ulang
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
        {
          'status': 'terlaksana',
          'jam_terlaksana': actualTime,
        },
        where: 'id = ?',
        whereArgs: [rowId],
      );
      historyChangeNotifier.value++;
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
    historyChangeNotifier.value++;

    return HistoryModel(
      id: newId.toString(),
      title: title,
      date: todayDate,
      scheduledTime: scheduledTime,
      actualTime: actualTime,
      isCompleted: true,
    );
  }

  /// Mencatat otomatis jadwal aktif hari ini sebagai "Terlewat"
  /// jika sudah melewati jam_pengingat + jeda_delay dan belum ada riwayatnya.
  Future<int> markMissedSchedulesForToday({DateTime? nowOverride}) async {
    final db = await database;
    final now = nowOverride ?? DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final todayShortDay = _shortDays[now.weekday - 1];

    final schedules = await getAllSchedules();
    int insertedCount = 0;

    for (final schedule in schedules) {
      if (!schedule.isActive || !schedule.days.contains(todayShortDay)) {
        continue;
      }

      final int? jadwalId = int.tryParse(schedule.id);
      if (jadwalId == null) continue;

      final timeParts = schedule.time.split(':');
      if (timeParts.length < 2) continue;
      final int? hour = int.tryParse(timeParts[0]);
      final int? minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final int delayMinutes =
          int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;
      final scheduledDateTime =
          DateTime(now.year, now.month, now.day, hour, minute);
      final deadline = scheduledDateTime.add(Duration(minutes: delayMinutes));

      if (!now.isAfter(deadline)) continue;

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

    if (insertedCount > 0) {
      historyChangeNotifier.value++;
    }
    return insertedCount;
  }

  /// Mengambil daftar jadwal aktif hari ini beserta status pelaksanaannya
  /// (Terlaksana / Terlewat / Belum Waktunya) untuk Dashboard.
  Future<List<TodayScheduleItem>> getTodayDashboardSchedules({
    DateTime? nowOverride,
  }) async {
    final db = await database;
    final now = nowOverride ?? DateTime.now();
    final todayDate = _formatIndonesianDate(now);
    final todayShortDay = _shortDays[now.weekday - 1];

    final allSchedules = await getAllSchedules();
    final todaySchedules = allSchedules
        .where((s) => s.isActive && s.days.contains(todayShortDay))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final List<Map<String, dynamic>> todayHistories = await db.query(
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
      final key = '${row['nama']}|${row['jam_terjadwal']}';
      statusByTitleTime[key] = status;
    }

    return todaySchedules.map((schedule) {
      final int? jadwalId = int.tryParse(schedule.id);
      final String? recordedStatus = (jadwalId != null
              ? statusByJadwalId[jadwalId]
              : null) ??
          statusByTitleTime['${schedule.title}|${schedule.time}'];

      final TodayScheduleStatus status;
      if (recordedStatus == 'terlaksana') {
        status = TodayScheduleStatus.terlaksana;
      } else if (recordedStatus == 'terlewat') {
        status = TodayScheduleStatus.terlewat;
      } else {
        status = TodayScheduleStatus.belumWaktunya;
      }

      return TodayScheduleItem(
        title: schedule.title,
        time: schedule.time,
        status: status,
      );
    }).toList();
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
