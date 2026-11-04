import 'package:sqflite/sqflite.dart';

/// Definisi skema tabel SQLite Nawaitu sesuai dengan Relational Diagram (ERD).
class DatabaseTables {
  // Nama Tabel
  static const String tableJadwal = 'jadwal_ibadah';
  static const String tableHari = 'hari_jadwal';
  static const String tableRiwayat = 'riwayat_pelaksanaan';

  /// Membuat ketiga tabel relasional saat database pertama kali diinisialisasi
  static Future<void> createTables(Database db) async {
    // 1. Tabel jadwal_ibadah (Sesuai ERD)
    await db.execute('''
      CREATE TABLE $tableJadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jadwal TEXT NOT NULL,
        deskripsi TEXT,
        jam_pengingat TEXT NOT NULL,
        max_popup INTEGER NOT NULL DEFAULT 5,
        jeda_delay INTEGER NOT NULL DEFAULT 15,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Tabel hari_jadwal (Sesuai ERD, relasi 1-ke-N ke jadwal_ibadah)
    await db.execute('''
      CREATE TABLE $tableHari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER NOT NULL,
        nama_hari TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES $tableJadwal (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel riwayat_pelaksanaan (Sesuai ERD, relasi 1-ke-N ke jadwal_ibadah)
    await db.execute('''
      CREATE TABLE $tableRiwayat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER,
        title TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jam_terjadwal TEXT NOT NULL,
        jam_terlaksana TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES $tableJadwal (id) ON DELETE SET NULL
      )
    ''');
  }
}

