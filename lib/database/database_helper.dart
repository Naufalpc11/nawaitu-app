import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_model.dart';
import '../models/schedule_model.dart';
import 'database_tables.dart';
import 'history_dao.dart';
import 'schedule_created_at_store.dart';
import 'schedule_dao.dart';

/// Pengelola SQLite lokal untuk jadwal dan riwayat Nawaitu.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// Notifier perubahan riwayat (Dashboard & History).
  final ValueNotifier<int> historyChangeNotifier = ValueNotifier<int>(0);

  /// Notifier perubahan jadwal (Dashboard).
  final ValueNotifier<int> scheduleChangeNotifier = ValueNotifier<int>(0);

  late final ScheduleCreatedAtStore _createdAtStore = ScheduleCreatedAtStore();
  late final ScheduleDao _scheduleDao = ScheduleDao(
    () => database,
    _createdAtStore,
    () => scheduleChangeNotifier.value++,
  );
  late final HistoryDao _historyDao = HistoryDao(
    () => database,
    _scheduleDao.getAll,
    _createdAtStore,
    () => historyChangeNotifier.value++,
  );

  DatabaseHelper._init();

  /// Instance database SQLite (lazy).
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
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await DatabaseTables.createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableHari}');
          await db.execute(
            'DROP TABLE IF EXISTS ${DatabaseTables.tableRiwayat}',
          );
          await db.execute(
            'DROP TABLE IF EXISTS ${DatabaseTables.tableJadwal}',
          );
          await DatabaseTables.createTables(db);
          return;
        }
        if (oldVersion < 4) {
          for (final entry in ScheduleDao.shortToDbDay.entries) {
            await db.update(
              DatabaseTables.tableHari,
              {'nama_hari': entry.value},
              where: 'nama_hari = ?',
              whereArgs: [entry.key],
            );
          }
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE ${DatabaseTables.tableRiwayat} RENAME COLUMN title TO nama',
          );
        }
      },
    );
  }

  /// Menghapus seluruh data database.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(DatabaseTables.tableHari);
    await db.delete(DatabaseTables.tableRiwayat);
    await db.delete(DatabaseTables.tableJadwal);
    await _createdAtStore.clear();
  }

  Future<List<ScheduleModel>> getAllSchedules() => _scheduleDao.getAll();

  Future<ScheduleModel> insertSchedule(
    ScheduleModel schedule, {
    DateTime? nowOverride,
  }) => _scheduleDao.insert(schedule, nowOverride: nowOverride);

  Future<int> updateSchedule(ScheduleModel schedule) =>
      _scheduleDao.update(schedule);

  Future<int> toggleScheduleActive(String id, bool isActive) =>
      _scheduleDao.toggleActive(id, isActive);

  Future<int> deleteSchedule(String id) => _scheduleDao.delete(id);

  Future<List<HistoryModel>> getAllHistories() => _historyDao.getAll();

  Future<int> insertHistory(HistoryModel history, {int? jadwalId}) =>
      _historyDao.insert(history, jadwalId: jadwalId);

  Future<int> updateHistoryStatus({
    required String id,
    required bool isCompleted,
    required String actualTime,
  }) => _historyDao.updateStatus(
    id: id,
    isCompleted: isCompleted,
    actualTime: actualTime,
  );

  Future<HistoryModel> markCompletedFromNotification({
    int? jadwalId,
    required String title,
    required String scheduledTime,
  }) => _historyDao.markCompletedFromNotification(
    jadwalId: jadwalId,
    title: title,
    scheduledTime: scheduledTime,
  );

  Future<int> markMissedSchedulesForToday({DateTime? nowOverride}) =>
      _historyDao.markMissedForToday(nowOverride: nowOverride);

  Future<List<TodayScheduleItem>> getTodayDashboardSchedules({
    DateTime? nowOverride,
  }) => _historyDao.getTodayDashboardSchedules(nowOverride: nowOverride);

  /// Menutup koneksi database.
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
