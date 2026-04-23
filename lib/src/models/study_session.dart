class StudySession {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? subjectId;
  final String sessionType; // study | exam | class
  final DateTime sessionDate;
  final String startTime;
  final String endTime;
  final DateTime createdAt;

  StudySession({
    required this.id,
    required this.userId,
    required this.title,
    required this.sessionType,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.description,
    this.subjectId,
  });

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? map['notes'] as String?,
      subjectId: map['subject_id'] as String?,
      sessionType: (map['session_type'] as String?) ?? 'study',
      sessionDate: map['session_date'] == null
          ? DateTime.now()
          : DateTime.parse(map['session_date'] as String),
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}