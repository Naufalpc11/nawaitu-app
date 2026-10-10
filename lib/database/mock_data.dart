import '../models/history_model.dart';
import '../models/schedule_model.dart';

List<ScheduleModel> dummySchedules = [
  const ScheduleModel(
    id: 'sch_1',
    title: 'Sholat Dhuha',
    time: '08:30',
    days: ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'],
    description:
        'Mengerjakan sholat sunnah dhuha minimal 2 rakaat untuk kelancaran berkah dan pembuka rezeki di pagi hari.',
    maxNotification: '5 Kali',
    snooze: '15 Menit',
    isActive: true,
  ),
  const ScheduleModel(
    id: 'sch_2',
    title: 'Sholat Tahajud',
    time: '04:10',
    days: ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'],
    description:
        'Sholat sunnah di sepertiga malam terakhir untuk memanjatkan doa, taubat, dan mendekatkan diri kepada Allah SWT.',
    maxNotification: '5 Kali',
    snooze: '10 Menit',
    isActive: true,
  ),
  const ScheduleModel(
    id: 'sch_3',
    title: "Baca Qur’an",
    time: '12:00',
    days: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'],
    description:
        'Membaca Al-Qur\'an minimal 1 maqra\' atau 1 juz setelah sholat Dzuhur sebagai penenang jiwa.',
    maxNotification: '3 Kali',
    snooze: '15 Menit',
    isActive: true,
  ),
  const ScheduleModel(
    id: 'sch_4',
    title: 'Dzikir Pagi',
    time: '06:00',
    days: ['Ahd', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'],
    description:
        'Membaca rangkaian dzikir pagi Al-Ma\'tsurat sebagai benteng perlindungan hari dari godaan dan marabahaya.',
    maxNotification: '3 Kali',
    snooze: '5 Menit',
    isActive: false,
  ),
];

List<HistoryModel> dummyHistories = [
  const HistoryModel(
    id: 'hist_1',
    title: 'Sholat Dhuha',
    date: 'Jumat, 4 September 2026',
    scheduledTime: '08:30',
    actualTime: '08:40',
    isCompleted: true,
  ),
  const HistoryModel(
    id: 'hist_2',
    title: "Baca Qur’an",
    date: 'Jumat, 4 September 2026',
    scheduledTime: '12:00',
    actualTime: '12:15',
    isCompleted: true,
  ),
  const HistoryModel(
    id: 'hist_3',
    title: 'Sholat Tahajud',
    date: 'Jumat, 5 September 2026',
    scheduledTime: '04:12',
    actualTime: '-',
    isCompleted: false,
  ),
  const HistoryModel(
    id: 'hist_4',
    title: "Baca Qur’an",
    date: 'Jumat, 6 September 2026',
    scheduledTime: '05:30',
    actualTime: '05:35',
    isCompleted: true,
  ),
];
