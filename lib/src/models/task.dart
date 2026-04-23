class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String priority; // high | medium | low
  final String status; // pending | in_progress | completed
  final DateTime? dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.description,
    this.dueDate,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: map['priority'] as String,
      status: map['status'] as String,
      dueDate: map['due_date'] == null
          ? null
          : DateTime.parse(map['due_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}