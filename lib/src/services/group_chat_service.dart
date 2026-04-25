import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _uidOrThrow() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  Future<void> _notifyGroupMembers({
    required String groupId,
    required String senderId,
    required String title,
    required String body,
    required String type,
  }) async {
    final membersRes = await _supabase
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final members = (membersRes as List).cast<Map<String, dynamic>>();

    final notifications = members
        .where((m) => m['user_id'] != senderId)
        .map((m) {
          return {
            'user_id': m['user_id'],
            'title': title,
            'body': body,
            'type': type,
            'related_id': groupId,
          };
        })
        .toList();

    if (notifications.isNotEmpty) {
      await _supabase.from('notifications').insert(notifications);
    }
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String groupId) {
    return _supabase
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at')
        .asyncMap((rows) async {
      final messages = rows.cast<Map<String, dynamic>>();

      if (messages.isEmpty) return [];

      final userIds = messages
          .map((m) => m['sender_id'] as String)
          .toSet()
          .toList();

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', userIds);

      final profiles = (profilesRes as List).cast<Map<String, dynamic>>();

      final profileMap = {
        for (final p in profiles) p['id']: p,
      };

      return messages.map((m) {
        return {
          ...m,
          'profile': profileMap[m['sender_id']],
        };
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String groupId,
    required String message,
  }) async {
    final uid = _uidOrThrow();

    if (message.trim().isEmpty) return;

    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'message': message.trim(),
      'message_type': 'text',
    });

    await _notifyGroupMembers(
      groupId: groupId,
      senderId: uid,
      title: 'New Group Message',
      body: message.trim(),
      type: 'group_message',
    );
  }

  Future<void> uploadAndSendFile({
    required String groupId,
  }) async {
    final uid = _uidOrThrow();

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final Uint8List? bytes = file.bytes;

    if (bytes == null) {
      throw Exception('File read failed');
    }

    final fileName = file.name.replaceAll(' ', '_');

    final path =
        '$groupId/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _supabase.storage.from('group-files').uploadBinary(path, bytes);

    final url = _supabase.storage.from('group-files').getPublicUrl(path);

    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'message': file.name,
      'message_type': 'file',
      'file_url': url,
      'file_name': file.name,
      'file_size': file.size,
    });

    await _notifyGroupMembers(
      groupId: groupId,
      senderId: uid,
      title: 'New Group File',
      body: file.name,
      type: 'group_file',
    );
  }
}