import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawaitu/database/database_helper.dart';
import 'package:nawaitu/database/database_tables.dart';
import 'package:nawaitu/main.dart';
import 'package:nawaitu/models/history_model.dart';
import 'package:nawaitu/models/schedule_model.dart';
import 'package:nawaitu/widgets/history_card.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text("Assalamu'alaikum"), findsOneWidget);
  });

  test('Notification tap marks schedule completed without duplicates', () async {
    await DatabaseHelper.instance.clearAllData();

    final inserted = await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Sholat Dhuha',
        time: '08:30',
        days: ['Sen', 'Kam'],
        description: '4 rakaat',
        snooze: '15 Menit',
      ),
    );
    final jadwalId = int.parse(inserted.id);

    await DatabaseHelper.instance.markCompletedFromNotification(
      jadwalId: jadwalId,
      title: 'Sholat Dhuha',
      scheduledTime: '08:30',
    );
    await DatabaseHelper.instance.markCompletedFromNotification(
      jadwalId: jadwalId,
      title: 'Sholat Dhuha',
      scheduledTime: '08:30',
    );

    final histories = await DatabaseHelper.instance.getAllHistories();
    expect(histories.length, 1);
    expect(histories.first.title, 'Sholat Dhuha');
    expect(histories.first.isCompleted, isTrue);

    await DatabaseHelper.instance.clearAllData();
  });

  test('updateSchedule persists updated fields and days in SQLite', () async {
    await DatabaseHelper.instance.clearAllData();

    final inserted = await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Sholat Dhuha',
        time: '08:30',
        days: ['Sen', 'Kam'],
        description: '4 rakaat',
        snooze: '15 Menit',
        isActive: true,
      ),
    );

    final updated = inserted.copyWith(
      title: 'Sholat Dhuha Pagi',
      time: '09:15',
      days: ['Sen', 'Rab', 'Jum'],
      description: '6 rakaat di musholla',
    );
    await DatabaseHelper.instance.updateSchedule(updated);

    final allSchedules = await DatabaseHelper.instance.getAllSchedules();
    expect(allSchedules.length, 1);
    expect(allSchedules.first.id, inserted.id);
    expect(allSchedules.first.title, 'Sholat Dhuha Pagi');
    expect(allSchedules.first.time, '09:15');
    expect(allSchedules.first.description, '6 rakaat di musholla');
    expect(allSchedules.first.days, ['Sen', 'Rab', 'Jum']);
    expect(allSchedules.first.isActive, isTrue);

    final db = await DatabaseHelper.instance.database;
    final rawDays = await db.query(DatabaseTables.tableHari);
    expect(
      rawDays.map((r) => r['nama_hari']).toList(),
      ['senin', 'rabu', 'jumat'],
    );

    await DatabaseHelper.instance.clearAllData();
  });

  testWidgets('HistoryCard displays actualTime when completed', (
    WidgetTester tester,
  ) async {
    const history = HistoryModel(
      id: '1',
      title: 'Sholat Dhuha',
      date: 'Sabtu, 14 November 2026',
      scheduledTime: '08:00',
      actualTime: '08:29',
      isCompleted: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HistoryCard(history: history),
        ),
      ),
    );

    expect(find.text('08:00 • Terlaksana 08:29'), findsOneWidget);
  });

  test('markMissedSchedulesForToday records terlewat once after delay', () async {
    await DatabaseHelper.instance.clearAllData();

    await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Sholat Dhuha',
        time: '08:00',
        days: ['Sab'],
        description: '4 rakaat',
        snooze: '15 Menit',
        isActive: true,
      ),
    );

    // Sabtu, 14 November 2026 pukul 08:10 (masih dalam toleransi 15 menit)
    final withinDelay = DateTime(2026, 11, 14, 8, 10);
    final beforeDeadlineCount =
        await DatabaseHelper.instance.markMissedSchedulesForToday(
      nowOverride: withinDelay,
    );
    expect(beforeDeadlineCount, 0);

    // Sabtu, 14 November 2026 pukul 08:20 (sudah lewat 08:00 + 15 menit)
    final pastDelay = DateTime(2026, 11, 14, 8, 20);
    final firstMissed =
        await DatabaseHelper.instance.markMissedSchedulesForToday(
      nowOverride: pastDelay,
    );
    expect(firstMissed, 1);

    // Pemanggilan kedua pada hari yang sama tidak boleh menduplikasi
    final secondMissed =
        await DatabaseHelper.instance.markMissedSchedulesForToday(
      nowOverride: pastDelay,
    );
    expect(secondMissed, 0);

    final histories = await DatabaseHelper.instance.getAllHistories();
    expect(histories.length, 1);
    expect(histories.first.title, 'Sholat Dhuha');
    expect(histories.first.isCompleted, isFalse);
    expect(histories.first.actualTime, '-');

    await DatabaseHelper.instance.clearAllData();
  });

  test('getTodayDashboardSchedules merges active schedules with 3 statuses', () async {
    await DatabaseHelper.instance.clearAllData();

    // Sabtu, 14 November 2026 ('Sab')
    final sabtuPagi = DateTime(2026, 11, 14, 10, 0);

    final s1 = await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Subuh',
        time: '04:30',
        days: ['Sab'],
        description: '',
        snooze: '15 Menit',
        isActive: true,
      ),
    );
    final s2 = await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Dhuha',
        time: '08:00',
        days: ['Sab'],
        description: '',
        snooze: '15 Menit',
        isActive: true,
      ),
    );
    await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Dzuhur',
        time: '12:00',
        days: ['Sab'],
        description: '',
        snooze: '15 Menit',
        isActive: true,
      ),
    );
    // Jadwal hari lain (tidak boleh muncul)
    await DatabaseHelper.instance.insertSchedule(
      const ScheduleModel(
        id: '',
        title: 'Jumat',
        time: '12:00',
        days: ['Jum'],
        description: '',
        snooze: '15 Menit',
        isActive: true,
      ),
    );

    await DatabaseHelper.instance.insertHistory(
      const HistoryModel(
        id: '',
        title: 'Subuh',
        date: 'Sabtu, 14 November 2026',
        scheduledTime: '04:30',
        actualTime: '04:35',
        isCompleted: true,
      ),
      jadwalId: int.parse(s1.id),
    );
    await DatabaseHelper.instance.insertHistory(
      const HistoryModel(
        id: '',
        title: 'Dhuha',
        date: 'Sabtu, 14 November 2026',
        scheduledTime: '08:00',
        actualTime: '-',
        isCompleted: false,
      ),
      jadwalId: int.parse(s2.id),
    );

    final items = await DatabaseHelper.instance.getTodayDashboardSchedules(
      nowOverride: sabtuPagi,
    );

    expect(items.length, 3);
    expect(items[0].title, 'Subuh');
    expect(items[0].status, TodayScheduleStatus.terlaksana);
    expect(items[1].title, 'Dhuha');
    expect(items[1].status, TodayScheduleStatus.terlewat);
    expect(items[2].title, 'Dzuhur');
    expect(items[2].status, TodayScheduleStatus.belumWaktunya);

    await DatabaseHelper.instance.clearAllData();
  });
}
