import 'package:sqflite/sqflite.dart';

class DatabaseTables {
  // Nama Tabel
  static const String tableJadwal = 'jadwal_ibadah';
  static const String tableHari = 'hari_jadwal';
  static const String tableRiwayat = 'riwayat_pelaksanaan';

  /// Membuat ketiga tabel relasional saat database pertama kali diinisialisasi
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableJadwal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_jadwal TEXT NOT NULL,
        deskripsi TEXT,
        jam_pengingat TEXT NOT NULL,
        jeda_delay INTEGER NOT NULL DEFAULT 15,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableHari (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER NOT NULL,
        nama_hari TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES $tableJadwal (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableRiwayat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jadwal_id INTEGER,
        nama TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        jam_terjadwal TEXT NOT NULL,
        jam_terlaksana TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (jadwal_id) REFERENCES $tableJadwal (id) ON DELETE SET NULL
      )
    ''');
  }
}
