import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nawaitu/database/database_helper.dart';
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
}
