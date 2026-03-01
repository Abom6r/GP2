import 'user_role.dart';
export 'user_role.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String bio;
  final List<String> skills;
  final List<String> subjects;
  final String? linkedinUrl;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.bio = '',
    this.skills = const [],
    this.subjects = const [],
    this.linkedinUrl,
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: userRoleFromString((map['role'] ?? 'student') as String),
      bio: (map['bio'] ?? '') as String,
      skills: List<String>.from(map['skills'] ?? const []),
      subjects: List<String>.from(map['subjects'] ?? const []),
      linkedinUrl: map['linkedin_url'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': userRoleToString(role),
      'bio': bio,
      'skills': skills,
      'subjects': subjects,
      'linkedin_url': linkedinUrl,
      'avatar_url': avatarUrl,
    };
  }
}
