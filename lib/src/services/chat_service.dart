import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../models/chat.message.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get currentUserId => _supabase.auth.currentUser!.id;

  Future<Conversation> startOrGetConversation({
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    final existing = await _supabase
        .from('conversations')
        .select()
        .or(
          'and(user1_id.eq.$currentUserId,user2_id.eq.$otherUserId),'
          'and(user1_id.eq.$otherUserId,user2_id.eq.$currentUserId)',
        )
        .maybeSingle();

    if (existing != null) {
      return Conversation.fromMap(existing);
    }

    final inserted = await _supabase
        .from('conversations')
        .insert({
          'user1_id': currentUserId,
          'user2_id': otherUserId,
          'user1_name': currentUserName,
          'user2_name': otherUserName,
          'member_ids': [currentUserId, otherUserId],
        })
        .select()
        .single();

    return Conversation.fromMap(inserted);
  }

  Stream<List<Conversation>> watchConversations() {
    return _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map(
          (rows) => rows
              .where(
                (row) =>
                    row['user1_id'] == currentUserId ||
                    row['user2_id'] == currentUserId,
              )
              .map((row) => Conversation.fromMap(row))
              .toList(),
        );
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows.map((row) => ChatMessage.fromMap(row)).toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'text': text,
    });

    await _supabase.from('conversations').update({
      'last_message': text,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<List<Map<String, dynamic>>> getMyGroupChats() async {
    final res = await _supabase
        .from('group_members')
        .select('group_id, study_groups(id, name, subject, group_code, join_code, description, created_by, owner_id, created_at)')
        .eq('user_id', currentUserId);

    final rows = (res as List).cast<Map<String, dynamic>>();

    return rows.map((row) {
      final group = row['study_groups'] as Map<String, dynamic>;

      return {
        'id': group['id'],
        'name': group['name'],
        'subject': group['subject'],
        'group_code': group['group_code'] ?? group['join_code'] ?? '',
        'join_code': group['join_code'] ?? group['group_code'] ?? '',
        'description': group['description'],
        'created_by': group['created_by'] ?? group['owner_id'],
        'owner_id': group['owner_id'] ?? group['created_by'],
        'created_at': group['created_at'],
      };
    }).toList();
  }
}