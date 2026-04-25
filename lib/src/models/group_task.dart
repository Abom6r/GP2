class GroupTask {
  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final String? description;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final DateTime createdAt;

  GroupTask({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.description,
    this.dueDate,
  });

  factory GroupTask.fromMap(Map<String, dynamic> map) {
    return GroupTask(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      createdBy: map['created_by'] as String,
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