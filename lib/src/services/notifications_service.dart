import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get uid => _supabase.auth.currentUser!.id;

  Stream<List<Map<String, dynamic>>> watchNotifications() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.cast<Map<String, dynamic>>());
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? relatedId,
  }) async {
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
    });
  }

  Future<void> markAsRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid);
  }
}