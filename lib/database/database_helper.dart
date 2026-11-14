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
      version: 3,
      onConfigure: (db) async {
        // Mengaktifkan fitur Foreign Key constraint di SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Membuat tabel kosong murni dari awal (tanpa data tiruan)
        await DatabaseTables.createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Menghapus data lama jika versi dinaikkan agar database kembali bersih dari awal
        await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableHari}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableRiwayat}');
        await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableJadwal}');
        await DatabaseTables.createTables(db);
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

  /// Mengambil semua jadwal ibadah beserta list harinya
  Future<List<ScheduleModel>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> schedulesMap =
        await db.query(DatabaseTables.tableJadwal, orderBy: 'id ASC');

    List<ScheduleModel> result = [];

    for (var row in schedulesMap) {
      final int scheduleId = row['id'] as int;

      // Ambil hari-hari untuk jadwal ini dari tabel hari_jadwal
      final List<Map<String, dynamic>> daysMap = await db.query(
        DatabaseTables.tableHari,
        where: 'jadwal_id = ?',
        whereArgs: [scheduleId],
      );

      final List<String> days =
          daysMap.map((d) => d['nama_hari'] as String).toList();

      result.add(ScheduleModel(
        id: scheduleId.toString(),
        title: row['nama_jadwal'] as String,
        time: row['jam_pengingat'] as String,
        days: days,
        description: (row['deskripsi'] as String?) ?? '',
        snooze: '${row['jeda_delay']} Menit',
        isActive: (row['is_active'] as int) == 1,
      ));
    }

    return result;
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

    // 2. Simpan hari-hari terpilih ke tabel hari_jadwal
    for (var hari in schedule.days) {
      await db.insert(DatabaseTables.tableHari, {
        'jadwal_id': newId,
        'nama_hari': hari,
      });
    }

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
        'nama_hari': hari,
      });
    }

    return count;
  }

  /// Toggle status aktif/nonaktif jadwal
  Future<int> toggleScheduleActive(String id, bool isActive) async {
    final db = await database;
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    return await db.update(
      DatabaseTables.tableJadwal,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  /// Menghapus jadwal ibadah (otomatis cascade menghapus hari_jadwal)
  Future<int> deleteSchedule(String id) async {
    final db = await database;
    final int? scheduleId = int.tryParse(id);
    if (scheduleId == null) return 0;

    return await db.delete(
      DatabaseTables.tableJadwal,
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
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
        title: row['title'] as String,
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
      'title': history.title,
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

  /// Mencatat atau memperbarui ibadah sebagai "Terlaksana" saat user menekan notifikasi
  Future<HistoryModel> markCompletedFromNotification({
    int? jadwalId,
    required String title,
    required String scheduledTime,
  }) async {
    final db = await database;
    final now = DateTime.now();

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
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

    final todayDate =
        '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
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
            where: 'title = ? AND jam_terjadwal = ? AND tanggal = ?',
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
      'title': title,
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

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
