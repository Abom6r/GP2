import 'package:supabase_flutter/supabase_flutter.dart';

class PostsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get uid => _supabase.auth.currentUser!.id;

  Stream<List<Map<String, dynamic>>> watchPosts() {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
      final posts = rows.cast<Map<String, dynamic>>();

      if (posts.isEmpty) return [];

      final userIds = posts.map((p) => p['user_id'] as String).toSet().toList();
      final postIds = posts.map((p) => p['id'] as String).toList();

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      final likesRes = await _supabase
          .from('post_likes')
          .select()
          .inFilter('post_id', postIds);

      final commentsRes = await _supabase
          .from('post_comments')
          .select()
          .inFilter('post_id', postIds);

      final profiles = (profilesRes as List).cast<Map<String, dynamic>>();
      final likes = (likesRes as List).cast<Map<String, dynamic>>();
      final comments = (commentsRes as List).cast<Map<String, dynamic>>();

      final profileMap = {
        for (final p in profiles) p['id']: p,
      };

      return posts.map((post) {
        final postId = post['id'];

        final postLikes =
            likes.where((l) => l['post_id'] == postId).toList();

        final postComments =
            comments.where((c) => c['post_id'] == postId).toList();

        final likedByMe = postLikes.any((l) => l['user_id'] == uid);

        return {
          ...post,
          'profile': profileMap[post['user_id']],
          'likes_count': postLikes.length,
          'comments_count': postComments.length,
          'liked_by_me': likedByMe,
        };
      }).toList();
    });
  }

  Future<void> createPost({
    required String content,
    String? fileUrl,
    String? groupId,
  }) async {
    if (content.trim().isEmpty) return;

    await _supabase.from('posts').insert({
      'user_id': uid,
      'content': content.trim(),
      'file_url': fileUrl,
      'group_id': groupId,
    });
  }

  Future<void> toggleLike(String postId) async {
    final existing = await _supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': uid,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final commentsRes = await _supabase
        .from('post_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final comments = (commentsRes as List).cast<Map<String, dynamic>>();

    if (comments.isEmpty) return [];

    final userIds =
        comments.map((c) => c['user_id'] as String).toSet().toList();

    final profilesRes = await _supabase
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', userIds);

    final profiles = (profilesRes as List).cast<Map<String, dynamic>>();

    final profileMap = {
      for (final p in profiles) p['id']: p,
    };

    return comments.map((comment) {
      return {
        ...comment,
        'profile': profileMap[comment['user_id']],
      };
    }).toList();
  }

  Future<void> addComment({
    required String postId,
    required String comment,
  }) async {
    if (comment.trim().isEmpty) return;

    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'user_id': uid,
      'comment': comment.trim(),
    });
  }
}