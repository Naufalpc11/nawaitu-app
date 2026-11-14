import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_routes.dart';
import 'database/database_helper.dart';
import 'screens/create_schedule_screen.dart';
import 'screens/detail_history_screen.dart';
import 'screens/detail_schedule_screen.dart';
import 'screens/edit_schedule_screen.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationService.instance.init();
  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.instance.syncAllActiveSchedules();
    await DatabaseHelper.instance.markMissedSchedulesForToday();
    await NotificationService.instance.processPendingLaunchNotification();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.instance.navigatorKey,
      scaffoldMessengerKey: NotificationService.instance.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Nawaitu',
      // Mengaktifkan font Manrope secara global ke seluruh aplikasi
      theme: ThemeData(
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          labelSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
      ),
      initialRoute: AppRoutes.main,
      routes: <String, WidgetBuilder>{
        AppRoutes.main: (context) => const MainNavigation(),
        AppRoutes.createSchedule: (context) => const CreateScheduleScreen(),
        AppRoutes.detailSchedule: (context) => const DetailScheduleScreen(),
        AppRoutes.editSchedule: (context) => const EditScheduleScreen(),
        AppRoutes.detailHistory: (context) => const DetailHistoryScreen(),
      },
    );
  }
}
