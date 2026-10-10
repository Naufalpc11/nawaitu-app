class HistoryModel {
  final String id;
  final String title;
  final String date;
  final String scheduledTime;
  final String actualTime;
  final bool isCompleted;

  const HistoryModel({
    required this.id,
    required this.title,
    required this.date,
    required this.scheduledTime,
    required this.actualTime,
    required this.isCompleted,
  });

  HistoryModel copyWith({
    String? id,
    String? title,
    String? date,
    String? scheduledTime,
    String? actualTime,
    bool? isCompleted,
  }) {
    return HistoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'scheduledTime': scheduledTime,
      'actualTime': actualTime,
      'isCompleted': isCompleted,
    };
  }

  factory HistoryModel.fromMap(Map<String, dynamic> map) {
    return HistoryModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      scheduledTime: map['scheduledTime'] as String? ?? '',
      actualTime: map['actualTime'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

