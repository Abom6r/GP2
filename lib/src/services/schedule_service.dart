import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_session.dart';

class ScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _uidOrThrow() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  Future<List<StudySession>> getSessions() async {
    final uid = _uidOrThrow();

    final res = await _supabase
        .from('study_sessions')
        .select()
        .eq('user_id', uid)
        .order('session_date', ascending: true)
        .order('start_time', ascending: true);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(StudySession.fromMap).toList();
  }

  Future<void> addSession({
    required String title,
    String? description,
    required String sessionType,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    String? subjectId,
  }) async {
    final uid = _uidOrThrow();

    final data = <String, dynamic>{
      'user_id': uid,
      'title': title.trim(),
      'notes': description?.trim().isEmpty == true ? null : description?.trim(),
      'description':
          description?.trim().isEmpty == true ? null : description?.trim(),
      'session_type': sessionType,
      'session_date':
          '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
    };

    if (subjectId != null && subjectId.trim().isNotEmpty) {
      data['subject_id'] = subjectId;
    }

    await _supabase.from('study_sessions').insert(data);
  }

  Future<void> updateSession({
    required String sessionId,
    required String title,
    String? description,
    required String sessionType,
    required DateTime sessionDate,
    required String startTime,
    required String endTime,
    String? subjectId,
  }) async {
    final uid = _uidOrThrow();

    final data = <String, dynamic>{
      'title': title.trim(),
      'notes': description?.trim().isEmpty == true ? null : description?.trim(),
      'description':
          description?.trim().isEmpty == true ? null : description?.trim(),
      'session_type': sessionType,
      'session_date':
          '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'start_time': startTime,
      'end_time': endTime,
      'subject_id': (subjectId != null && subjectId.trim().isNotEmpty)
          ? subjectId
          : null,
    };

    await _supabase
        .from('study_sessions')
        .update(data)
        .eq('id', sessionId)
        .eq('user_id', uid);
  }

  Future<void> deleteSession(String sessionId) async {
    final uid = _uidOrThrow();

    await _supabase
        .from('study_sessions')
        .delete()
        .eq('id', sessionId)
        .eq('user_id', uid);
  }
}