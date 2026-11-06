class HadisModel {
  final int id;
  final String arab;
  final String terjemahan;
  final String takhrij;
  final String grade;

  const HadisModel({
    required this.id,
    required this.arab,
    required this.terjemahan,
    required this.takhrij,
    required this.grade,
  });

  factory HadisModel.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as Map<String, dynamic>? ?? {};
    return HadisModel(
      id: json['id'] as int? ?? 0,
      arab: (text['ar'] as String?)?.trim() ?? '',
      terjemahan: (text['id'] as String?)?.trim() ?? '',
      takhrij: (json['takhrij'] as String?)?.trim() ?? 'Hadis Riwayat',
      grade: (json['grade'] as String?)?.trim() ?? 'Sahih',
    );
  }
}
