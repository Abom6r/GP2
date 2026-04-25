class StudyGroup {
  final String id;
  final String name;
  final String subject;
  final String? description;
  final String groupCode;
  final String createdBy;
  final DateTime createdAt;
  final int membersCount;
  final bool isMember;

  StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.groupCode,
    required this.createdBy,
    required this.createdAt,
    this.description,
    this.membersCount = 0,
    this.isMember = false,
  });

  factory StudyGroup.fromMap(
    Map<String, dynamic> map, {
    int membersCount = 0,
    bool isMember = false,
  }) {
    return StudyGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String?,
      groupCode: map['group_code'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      membersCount: membersCount,
      isMember: isMember,
    );
  }
}