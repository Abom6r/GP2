import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final _supabase = Supabase.instance.client;

  String get uid => _supabase.auth.currentUser!.id;

  Stream<List<Map<String, dynamic>>> watchPosts() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
      final posts = rows.cast<Map<String, dynamic>>();

      if (posts.isEmpty) return [];

      final userIds =
          posts.map((p) => p['user_id'] as String).toSet().toList();

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      final profiles = (profilesRes as List).cast<Map<String, dynamic>>();

      final profileMap = {
        for (final p in profiles) p['id']: p,
      };

      return posts.map((p) {
        return {
          ...p,
          'profile': profileMap[p['user_id']],
        };
      }).toList();
    });
  }

  Future<void> createPost({
    required String content,
    String? fileUrl,
    String? groupId,
  }) async {
    await _supabase.from('posts').insert({
      'user_id': uid,
      'content': content,
      'file_url': fileUrl,
      'group_id': groupId,
    });
  }
}