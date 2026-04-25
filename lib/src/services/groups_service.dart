import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_group.dart';

class GroupsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _uidOrThrow() {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  String _generateGroupCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<List<StudyGroup>> getGroups({String query = ''}) async {
    final uid = _uidOrThrow();

    final groupsRes = await _supabase
        .from('study_groups')
        .select()
        .order('created_at', ascending: false);

    final groupsRows = (groupsRes as List).cast<Map<String, dynamic>>();

    final membersRes = await _supabase.from('group_members').select();

    final memberRows = (membersRes as List).cast<Map<String, dynamic>>();

    final q = query.trim().toLowerCase();

    return groupsRows.where((group) {
      if (q.isEmpty) return true;

      final name = (group['name'] ?? '').toString().toLowerCase();
      final subject = (group['subject'] ?? '').toString().toLowerCase();
      final code = (group['group_code'] ?? group['join_code'] ?? '')
          .toString()
          .toLowerCase();

      return name.contains(q) || subject.contains(q) || code.contains(q);
    }).map((group) {
      final groupId = group['id'] as String;

      final count = memberRows.where((m) => m['group_id'] == groupId).length;

      final isMember = memberRows.any(
        (m) => m['group_id'] == groupId && m['user_id'] == uid,
      );

      return StudyGroup.fromMap(
        group,
        membersCount: count,
        isMember: isMember,
      );
    }).toList();
  }

  Future<void> createGroup({
    required String name,
    required String subject,
    String? description,
  }) async {
    final uid = _uidOrThrow();
    final code = _generateGroupCode();

    final inserted = await _supabase
        .from('study_groups')
        .insert({
          'name': name.trim(),
          'subject': subject.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
          'group_code': code,
          'join_code': code,
          'created_by': uid,
          'owner_id': uid,
        })
        .select()
        .single();

    final groupId = inserted['id'] as String;

    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': uid,
      'role': 'owner',
    });
  }

  Future<void> joinGroup(String groupId) async {
    final uid = _uidOrThrow();

    await _supabase.from('group_members').upsert({
      'group_id': groupId,
      'user_id': uid,
      'role': 'member',
    });
  }

  Future<void> leaveGroup(String groupId) async {
    final uid = _uidOrThrow();

    await _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', uid);
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final membersRes = await _supabase
        .from('group_members')
        .select()
        .eq('group_id', groupId)
        .order('id', ascending: true);

    final members = (membersRes as List).cast<Map<String, dynamic>>();

    if (members.isEmpty) {
      return [];
    }

    final userIds = members
        .map((m) => m['user_id'] as String)
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

    return members.map((m) {
      final profile = profileMap[m['user_id']];

      return {
        ...m,
        'profiles': profile,
      };
    }).toList();
  }

  Future<void> pinFile({
    required String groupId,
    required String fileUrl,
    required String fileName,
  }) async {
    final uid = _uidOrThrow();

    await _supabase.from('pinned_files').insert({
      'group_id': groupId,
      'file_url': fileUrl,
      'file_name': fileName,
      'pinned_by': uid,
    });
  }

  Future<List<Map<String, dynamic>>> getPinnedFiles(String groupId) async {
    final res = await _supabase
        .from('pinned_files')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    return (res as List).cast<Map<String, dynamic>>();
  }
}