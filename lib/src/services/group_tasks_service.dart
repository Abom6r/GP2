import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_task.dart';

class GroupTasksService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _uidOrThrow() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  Future<List<GroupTask>> getGroupTasks(String groupId) async {
    final res = await _supabase
        .from('group_tasks')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(GroupTask.fromMap).toList();
  }

  Future<void> addGroupTask({
    required String groupId,
    required String title,
    String? description,
    required String priority,
    DateTime? dueDate,
  }) async {
    final uid = _uidOrThrow();

    /// ✅ إضافة المهمة
    await _supabase.from('group_tasks').insert({
      'group_id': groupId,
      'created_by': uid,
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'priority': priority,
      'status': 'pending',
      'due_date': dueDate == null
          ? null
          : '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
    });

    /// 🔥 إرسال إشعارات لكل أعضاء القروب
    final members = await _supabase
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    for (final m in members) {
      await _supabase.from('notifications').insert({
        'user_id': m['user_id'],
        'title': 'New Group Task',
        'body': title,
        'type': 'group_task',
        'related_id': groupId,
      });
    }
  }

  Future<void> updateGroupTask({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? dueDate,
  }) async {
    await _supabase.from('group_tasks').update({
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'priority': priority,
      'status': status,
      'due_date': dueDate == null
          ? null
          : '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
    }).eq('id', taskId);
  }

  Future<void> updateGroupTaskStatus({
    required String taskId,
    required String status,
  }) async {
    await _supabase
        .from('group_tasks')
        .update({'status': status})
        .eq('id', taskId);
  }

  Future<void> deleteGroupTask(String taskId) async {
    await _supabase.from('group_tasks').delete().eq('id', taskId);
  }
}