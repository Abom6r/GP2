import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TasksService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _uidOrThrow() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  Future<List<Task>> getTasks() async {
    final uid = _uidOrThrow();

    final res = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(Task.fromMap).toList();
  }

  Future<void> addTask({
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? dueDate,
  }) async {
    final uid = _uidOrThrow();

    await _supabase.from('tasks').insert({
      'user_id': uid,
      'title': title.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'priority': priority,
      'status': status,
      'due_date': dueDate == null
          ? null
          : '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
    });
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    String? description,
    required String priority,
    required String status,
    DateTime? dueDate,
  }) async {
    final uid = _uidOrThrow();

    await _supabase
        .from('tasks')
        .update({
          'title': title.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'priority': priority,
          'status': status,
          'due_date': dueDate == null
              ? null
              : '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        })
        .eq('id', taskId)
        .eq('user_id', uid);
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _uidOrThrow();

    await _supabase
        .from('tasks')
        .delete()
        .eq('id', taskId)
        .eq('user_id', uid);
  }
}