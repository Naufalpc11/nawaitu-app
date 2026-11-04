import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_model.dart';
import '../models/schedule_model.dart';

/// DatabaseHelper untuk mengelola SQLite Database Lokal Nawaitu.
/// Struktur tabel disusun 100% mengikuti Relational Diagram (ERD):
/// - jadwal_ibadah
/// - hari_jadwal (relasi 1-ke-N dari jadwal_ibadah)
/// - riwayat_pelaksanaan (relasi 1-ke-N dari jadwal_ibadah)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      version: 1,
      onConfigure: (db) async {
        // Mengaktifkan fitur Foreign Key constraint di SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel jadwal_ibadah (Sesuai ERD)
    await db.execute('''
      CREATE TABLE jadwal_ibadah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jadwal TEXT NOT NULL,
        deskripsi TEXT,
        jam_pengingat TEXT NOT NULL,
        max_popup INTEGER NOT NULL DEFAULT 5,
        jeda_delay INTEGER NOT NULL DEFAULT 15,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Tabel hari_jadwal (Sesuai ERD, relasi ke jadwal_ibadah)
    await db.execute('''
      CREATE TABLE hari_jadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER NOT NULL,
        nama_hari TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES jadwal_ibadah (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel riwayat_pelaksanaan (Sesuai ERD, relasi ke jadwal_ibadah)
    await db.execute('''
      CREATE TABLE riwayat_pelaksanaan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER,
        title TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jam_terjadwal TEXT NOT NULL,
        jam_terlaksana TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES jadwal_ibadah (id) ON DELETE SET NULL
      )
    ''');

    // Seed Data Awal ke SQLite lokal agar saat pertama run aplikasi tidak kosong
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // Seed 1: Sholat Dhuha
    final idDhuha = await db.insert('jadwal_ibadah', {
      'nama_jadwal': 'Sholat Dhuha',
      'deskripsi':
          'Mengerjakan sholat sunnah dhuha minimal 2 rakaat untuk kelancaran berkah dan pembuka rezeki di pagi hari.',
      'jam_pengingat': '08:30',
      'max_popup': 5,
      'jeda_delay': 15,
      'is_active': 1,
    });
    for (var hari in ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']) {
      await db.insert('hari_jadwal', {'jadwal_id': idDhuha, 'nama_hari': hari});
    }

    // Seed 2: Sholat Tahajud
    final idTahajud = await db.insert('jadwal_ibadah', {
      'nama_jadwal': 'Sholat Tahajud',
      'deskripsi':
          'Sholat sunnah di sepertiga malam terakhir untuk memanjatkan doa, taubat, dan mendekatkan diri kepada Allah SWT.',
      'jam_pengingat': '04:10',
      'max_popup': 5,
      'jeda_delay': 10,
      'is_active': 1,
    });
    for (var hari in ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']) {
      await db.insert(
          'hari_jadwal', {'jadwal_id': idTahajud, 'nama_hari': hari});
    }

    // Seed 3: Baca Qur'an
    final idQuran = await db.insert('jadwal_ibadah', {
      'nama_jadwal': "Baca Qur’an",
      'deskripsi':
          'Membaca Al-Qur\'an minimal 1 maqra\' atau 1 juz setelah sholat Dzuhur sebagai penenang jiwa.',
      'jam_pengingat': '12:00',
      'max_popup': 3,
      'jeda_delay': 15,
      'is_active': 1,
    });
    for (var hari in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum']) {
      await db.insert('hari_jadwal', {'jadwal_id': idQuran, 'nama_hari': hari});
    }

    // Seed 4: Dzikir Pagi
    final idDzikir = await db.insert('jadwal_ibadah', {
      'nama_jadwal': 'Dzikir Pagi',
      'deskripsi':
          'Membaca rangkaian dzikir pagi Al-Ma\'tsurat sebagai benteng perlindungan hari dari godaan dan marabahaya.',
      'jam_pengingat': '06:00',
      'max_popup': 3,
      'jeda_delay': 5,
      'is_active': 0,
    });
    for (var hari in ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']) {
      await db.insert(
          'hari_jadwal', {'jadwal_id': idDzikir, 'nama_hari': hari});
    }

    // Seed Riwayat Pelaksanaan Awal
    await db.insert('riwayat_pelaksanaan', {
      'jadwal_id': idDhuha,
      'title': 'Sholat Dhuha',
      'tanggal': 'Jumat, 4 September 2026',
      'jam_terjadwal': '08:30',
      'jam_terlaksana': '08:40',
      'status': 'terlaksana',
    });

    await db.insert('riwayat_pelaksanaan', {
      'jadwal_id': idQuran,
      'title': "Baca Qur’an",
      'tanggal': 'Jumat, 4 September 2026',
      'jam_terjadwal': '12:00',
      'jam_terlaksana': '12:15',
      'status': 'terlaksana',
    });

    await db.insert('riwayat_pelaksanaan', {
      'jadwal_id': idTahajud,
      'title': 'Sholat Tahajud',
      'tanggal': 'Jumat, 5 September 2026',
      'jam_terjadwal': '04:12',
      'jam_terlaksana': '-',
      'status': 'terlewat',
    });

    await db.insert('riwayat_pelaksanaan', {
      'jadwal_id': idQuran,
      'title': "Baca Qur’an",
      'tanggal': 'Jumat, 6 September 2026',
      'jam_terjadwal': '05:30',
      'jam_terlaksana': '05:35',
      'status': 'terlaksana',
    });
  }

  // ==========================================
  // OPERASI CRUD: JADWAL IBADAH & HARI
  // ==========================================

  /// Mengambil semua jadwal ibadah beserta list harinya
  Future<List<ScheduleModel>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> schedulesMap =
        await db.query('jadwal_ibadah', orderBy: 'id ASC');

    List<ScheduleModel> result = [];

    for (var row in schedulesMap) {
      final int scheduleId = row['id'] as int;

      // Ambil hari-hari untuk jadwal ini dari tabel hari_jadwal
      final List<Map<String, dynamic>> daysMap = await db.query(
        'hari_jadwal',
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
        maxNotification: '${row['max_popup']} Kali',
        snooze: '${row['jeda_delay']} Menit',
        isActive: (row['is_active'] as int) == 1,
      ));
    }

    return result;
  }

  /// Menambah jadwal ibadah baru (dan relasi hari)
  Future<ScheduleModel> insertSchedule(ScheduleModel schedule) async {
    final db = await database;

    final int maxPopup =
        int.tryParse(schedule.maxNotification.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    final int jedaDelay =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

    // 1. Simpan ke tabel jadwal_ibadah
    final int newId = await db.insert('jadwal_ibadah', {
      'nama_jadwal': schedule.title,
      'deskripsi': schedule.description,
      'jam_pengingat': schedule.time,
      'max_popup': maxPopup,
      'jeda_delay': jedaDelay,
      'is_active': schedule.isActive ? 1 : 0,
    });

    // 2. Simpan hari-hari terpilih ke tabel hari_jadwal
    for (var hari in schedule.days) {
      await db.insert('hari_jadwal', {
        'jadwal_id': newId,
        'nama_hari': hari,
      });
    }

    return schedule.copyWith(id: newId.toString());
  }

  /// Mengupdate jadwal ibadah yang ada
  Future<int> updateSchedule(ScheduleModel schedule) async {
    final db = await database;
    final int? scheduleId = int.tryParse(schedule.id);
    if (scheduleId == null) return 0;

    final int maxPopup =
        int.tryParse(schedule.maxNotification.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;
    final int jedaDelay =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

    // 1. Update data utama jadwal
    final count = await db.update(
      'jadwal_ibadah',
      {
        'nama_jadwal': schedule.title,
        'deskripsi': schedule.description,
        'jam_pengingat': schedule.time,
        'max_popup': maxPopup,
        'jeda_delay': jedaDelay,
        'is_active': schedule.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [scheduleId],
    );

    // 2. Hapus hari lama dan masukkan hari baru
    await db.delete('hari_jadwal', where: 'jadwal_id = ?', whereArgs: [scheduleId]);
    for (var hari in schedule.days) {
      await db.insert('hari_jadwal', {
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
      'jadwal_ibadah',
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
      'jadwal_ibadah',
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
        await db.query('riwayat_pelaksanaan', orderBy: 'id DESC');

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
    return await db.insert('riwayat_pelaksanaan', {
      'jadwal_id': jadwalId,
      'title': history.title,
      'tanggal': history.date,
      'jam_terjadwal': history.scheduledTime,
      'jam_terlaksana': history.actualTime,
      'status': history.isCompleted ? 'terlaksana' : 'terlewat',
    });
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

    return await db.update(
      'riwayat_pelaksanaan',
      {
        'status': isCompleted ? 'terlaksana' : 'terlewat',
        'jam_terlaksana': actualTime,
      },
      where: 'id = ?',
      whereArgs: [historyId],
    );
  }

  /// Menutup koneksi database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

