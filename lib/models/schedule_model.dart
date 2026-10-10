class ScheduleModel {
  final String id;
  final String title;
  final String time;
  final List<String> days;
  final String description;
  final String maxNotification;
  final String snooze;
  final bool isActive;

  const ScheduleModel({
    required this.id,
    required this.title,
    required this.time,
    required this.days,
    required this.description,
    required this.maxNotification,
    required this.snooze,
    this.isActive = true,
  });

  ScheduleModel copyWith({
    String? id,
    String? title,
    String? time,
    List<String>? days,
    String? description,
    String? maxNotification,
    String? snooze,
    bool? isActive,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      days: days ?? this.days,
      description: description ?? this.description,
      maxNotification: maxNotification ?? this.maxNotification,
      snooze: snooze ?? this.snooze,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'days': days,
      'description': description,
      'maxNotification': maxNotification,
      'snooze': snooze,
      'isActive': isActive,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      time: map['time'] as String? ?? '',
      days: (map['days'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          <String>[],
      description: map['description'] as String? ?? '',
      maxNotification: map['maxNotification'] as String? ?? '5 Kali',
      snooze: map['snooze'] as String? ?? '15 Menit',
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

