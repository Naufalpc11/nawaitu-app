import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/database_helper.dart';
import '../models/schedule_model.dart';

/// Handler background isolate saat tombol aksi notifikasi (tanpa membuka UI) ditekan
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.handleNotificationResponse(
    notificationResponse,
    showFeedback: false,
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Navigator & ScaffoldMessenger key global untuk menampilkan konfirmasi saat notifikasi diketuk
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const String _channelId = 'nawaitu_ibadah_channel';
  static const String _channelName = 'Pengingat Jadwal Ibadah';
  static const String _channelDesc =
      'Notifikasi pengingat waktu pelaksanaan jadwal ibadah Nawaitu';

  static const Map<String, int> _dayToWeekday = {
    'Sen': DateTime.monday,
    'Sel': DateTime.tuesday,
    'Rab': DateTime.wednesday,
    'Kam': DateTime.thursday,
    'Jum': DateTime.friday,
    'Sab': DateTime.saturday,
    'Ahd': DateTime.sunday,
  };

  bool _isInitialized = false;
  NotificationResponse? _pendingLaunchResponse;

  /// Inisialisasi dasar plugin & zona waktu (aman dipanggil dari main maupun background isolate)
  Future<void> _ensurePluginInitialized({bool createChannel = true}) async {
    if (_isInitialized) return;

    _configureLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        handleNotificationResponse(response, showFeedback: true);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (createChannel) {
      // Daftarkan Notification Channel di Android 8.0+
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _isInitialized = true;
  }

  /// Inisialisasi plugin notifikasi lokal & zona waktu lokal perangkat
  Future<void> init() async {
    final wasInitialized = _isInitialized;
    await _ensurePluginInitialized();
    if (wasInitialized) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Minta izin notifikasi runtime (wajib untuk Android 13+)
    await androidPlugin?.requestNotificationsPermission();

    // Cek apakah aplikasi dibuka dari kondisi tertutup dengan mengetuk notifikasi
    final NotificationAppLaunchDetails? launchDetails =
        await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      _pendingLaunchResponse = launchDetails.notificationResponse;
    }
  }

  /// Memproses notifikasi peluncuran setelah UI MaterialApp siap dirender
  Future<void> processPendingLaunchNotification() async {
    final pending = _pendingLaunchResponse;
    if (pending == null) return;
    _pendingLaunchResponse = null;
    await handleNotificationResponse(pending, showFeedback: true);
  }

  void _configureLocalTimeZone() {
    tz_data.initializeTimeZones();
    final int offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;

    const Map<int, String> indonesiaZones = {
      7 * 3600 * 1000: 'Asia/Jakarta', // WIB (UTC+7)
      8 * 3600 * 1000: 'Asia/Makassar', // WITA (UTC+8)
      9 * 3600 * 1000: 'Asia/Jayapura', // WIT (UTC+9)
    };

    final String? preferredName = indonesiaZones[offsetMs];
    if (preferredName != null) {
      tz.setLocalLocation(tz.getLocation(preferredName));
      return;
    }

    final int nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.timeZone(nowEpochMs).offset.inMilliseconds == offsetMs) {
        tz.setLocalLocation(location);
        return;
      }
    }

    tz.setLocalLocation(tz.UTC);
  }

  /// Mengecek apakah izin notifikasi dan alarm presisi sudah aktif
  Future<bool> hasAllRequiredPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool notifEnabled =
        await androidPlugin?.areNotificationsEnabled() ?? true;
    final bool canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? true;
    return notifEnabled && canExact;
  }

  /// Meminta izin notifikasi & alarm presisi bila belum diberikan
  Future<void> ensurePermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final bool notifEnabled =
        await androidPlugin?.areNotificationsEnabled() ?? true;
    if (!notifEnabled) {
      await androidPlugin?.requestNotificationsPermission();
    }

    final bool canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? true;
    if (!canExact) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        final bool? openSettings = await showDialog<bool>(
          context: ctx,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Izin Alarm Presisi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: const Text(
              'Agar pengingat ibadah dan fitur Ingatkan Nanti (snooze) muncul tepat waktu tanpa tertunda sistem baterai, aktifkan izin "Alarm & pengingat" untuk Nawaitu.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Nanti',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C3A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await androidPlugin?.requestExactAlarmsPermission();
        }
      } else {
        await androidPlugin?.requestExactAlarmsPermission();
      }
    }
  }

  /// Menangani klik notifikasi ("Tandai Terlaksana" atau "Ingatkan Nanti")
  static Future<void> handleNotificationResponse(
    NotificationResponse response, {
    bool showFeedback = true,
  }) async {
    final rawPayload = response.payload;
    if (rawPayload == null || rawPayload.isEmpty) return;

    try {
      final Map<String, dynamic> data =
          jsonDecode(rawPayload) as Map<String, dynamic>;
      final int? jadwalId = data['jadwal_id'] is int
          ? data['jadwal_id'] as int
          : int.tryParse(data['jadwal_id']?.toString() ?? '');
      final String title = data['title']?.toString() ?? 'Ibadah';
      final String scheduledTime =
          data['scheduled_time']?.toString() ?? '--:--';
      final int snoozeMinutes = data['snooze_minutes'] is int
          ? data['snooze_minutes'] as int
          : int.tryParse(data['snooze_minutes']?.toString() ?? '') ?? 15;

      if (response.actionId == 'snooze') {
        await instance.scheduleSnooze(
          jadwalId: jadwalId,
          title: title,
          scheduledTime: scheduledTime,
          snoozeMinutes: snoozeMinutes,
          createChannel: showFeedback,
        );
        if (showFeedback) {
          final messenger = instance.scaffoldMessengerKey.currentState;
          messenger?.hideCurrentSnackBar();
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                'Pengingat "$title" ditunda $snoozeMinutes menit lagi.',
              ),
              backgroundColor: const Color(0xFFF59E0B),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (jadwalId != null) {
        await instance._ensurePluginInitialized(createChannel: showFeedback);
        await instance._plugin.cancel(id: instance._snoozeNotificationId(jadwalId));
      }

      final saved =
          await DatabaseHelper.instance.markCompletedFromNotification(
        jadwalId: jadwalId,
        title: title,
        scheduledTime: scheduledTime,
      );

      if (showFeedback) {
        final messenger = instance.scaffoldMessengerKey.currentState;
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              'Alhamdulillah, "${saved.title}" ditandai Terlaksana pukul ${saved.actualTime}',
            ),
            backgroundColor: const Color(0xFF0D5C3A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Gagal memproses payload notifikasi: $e');
    }
  }

  int _snoozeNotificationId(int jadwalId) => (jadwalId * 10) + 8;

  /// Menjadwalkan 1x pengingat ulang setelah [snoozeMinutes] menit
  Future<void> scheduleSnooze({
    int? jadwalId,
    required String title,
    required String scheduledTime,
    required int snoozeMinutes,
    bool createChannel = true,
  }) async {
    await _ensurePluginInitialized(createChannel: createChannel);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    final AndroidScheduleMode scheduleMode = canExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final int notifId =
        jadwalId != null ? _snoozeNotificationId(jadwalId) : 999008;
    final tz.TZDateTime snoozeDate =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: snoozeMinutes));

    final String payload = jsonEncode({
      'jadwal_id': jadwalId,
      'title': title,
      'scheduled_time': scheduledTime,
      'snooze_minutes': snoozeMinutes,
    });

    final String bodyText =
        'Pengingat ulang jadwal pukul $scheduledTime • Ketuk notifikasi untuk menandai sudah terlaksana.';

    await _plugin.zonedSchedule(
      id: notifId,
      title: 'Pengingat Ulang: $title',
      body: bodyText,
      scheduledDate: snoozeDate,
      notificationDetails: _buildNotificationDetails(
        subtitle: bodyText,
      ),
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }

  NotificationDetails _buildNotificationDetails({
    String? subtitle,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        visibility: NotificationVisibility.public,
        styleInformation: subtitle != null && subtitle.isNotEmpty
            ? BigTextStyleInformation(subtitle)
            : null,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'mark_done',
            'Tandai Terlaksana',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'snooze',
            'Ingatkan Nanti',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    );
  }

  int _notificationId(int jadwalId, int weekday) => (jadwalId * 10) + weekday;

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(
    int weekday,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduledDate.weekday != weekday || !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Menjadwalkan notifikasi mingguan berulang untuk tiap hari aktif pada sebuah ScheduleModel
  Future<void> scheduleForSchedule(ScheduleModel schedule) async {
    if (!_isInitialized) await init();

    // Bersihkan jadwal lama terlebih dahulu agar tidak ada notifikasi ganda/sisa
    await cancelForSchedule(schedule.id);

    if (!schedule.isActive || schedule.days.isEmpty) return;

    final int? jadwalId = int.tryParse(schedule.id);
    if (jadwalId == null) return;

    final parts = schedule.time.split(':');
    if (parts.length < 2) return;
    final int hour = int.tryParse(parts[0]) ?? 0;
    final int minute = int.tryParse(parts[1]) ?? 0;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final bool canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;
    final AndroidScheduleMode scheduleMode = canExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final int snoozeMinutes =
        int.tryParse(schedule.snooze.replaceAll(RegExp(r'[^0-9]'), '')) ?? 15;

    final String payload = jsonEncode({
      'jadwal_id': jadwalId,
      'title': schedule.title,
      'scheduled_time': schedule.time,
      'snooze_minutes': snoozeMinutes,
    });

    final String descPart = schedule.description.trim().isNotEmpty
        ? '${schedule.description.trim()}\n'
        : '';
    final String bodyText =
        '${descPart}Pukul ${schedule.time} • Ketuk notifikasi untuk menandai sudah terlaksana.';

    for (final day in schedule.days) {
      final int? weekday = _dayToWeekday[day];
      if (weekday == null) continue;

      final int notifId = _notificationId(jadwalId, weekday);
      final tz.TZDateTime scheduledDate =
          _nextInstanceOfWeekdayAndTime(weekday, hour, minute);

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Waktunya ${schedule.title}',
        body: bodyText,
        scheduledDate: scheduledDate,
        notificationDetails: _buildNotificationDetails(
          subtitle: bodyText,
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    }
  }

  /// Membatalkan seluruh notifikasi hari (Sen-Ahd) & snooze milik suatu jadwal
  Future<void> cancelForSchedule(String scheduleId) async {
    if (!_isInitialized) return;
    final int? jadwalId = int.tryParse(scheduleId);
    if (jadwalId == null) return;

    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _notificationId(jadwalId, weekday));
    }
    await _plugin.cancel(id: _snoozeNotificationId(jadwalId));
  }

  /// Sinkronisasi ulang semua jadwal aktif dari database SQLite saat startup
  Future<void> syncAllActiveSchedules() async {
    if (!_isInitialized) await init();
    final schedules = await DatabaseHelper.instance.getAllSchedules();
    for (final schedule in schedules) {
      if (schedule.isActive) {
        await scheduleForSchedule(schedule);
      } else {
        await cancelForSchedule(schedule.id);
      }
    }
  }

  /// Mengirim notifikasi uji coba instan untuk simulasi/demo ketuk-selesai
  Future<void> showTestNotification({ScheduleModel? sampleSchedule}) async {
    if (!_isInitialized) await init();
    await ensurePermissions();

    final String title = sampleSchedule?.title ?? 'Sholat Dhuha';
    final String scheduledTime = sampleSchedule?.time ??
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    final int? jadwalId = sampleSchedule != null
        ? int.tryParse(sampleSchedule.id)
        : null;

    final String payload = jsonEncode({
      'jadwal_id': jadwalId,
      'title': title,
      'scheduled_time': scheduledTime,
    });

    final String bodyText =
        'Pukul $scheduledTime • Ketuk notifikasi ini untuk menandai sudah terlaksana.';

    await _plugin.show(
      id: 999001,
      title: 'Waktunya $title',
      body: bodyText,
      notificationDetails: _buildNotificationDetails(subtitle: bodyText),
      payload: payload,
    );
  }
}
