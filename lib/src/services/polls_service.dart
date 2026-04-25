import 'package:supabase_flutter/supabase_flutter.dart';

class PollsService {
  final _supabase = Supabase.instance.client;

  String get uid => _supabase.auth.currentUser!.id;

  Future<String> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
  }) async {
    final poll = await _supabase
        .from('polls')
        .insert({
          'group_id': groupId,
          'question': question,
          'created_by': uid,
        })
        .select()
        .single();

    final pollId = poll['id'];

    for (final opt in options) {
      await _supabase.from('poll_options').insert({
        'poll_id': pollId,
        'option_text': opt,
      });
    }

    await _supabase.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': uid,
      'message': question,
      'message_type': 'poll',
      'poll_id': pollId,
    });

    return pollId;
  }

  Future<void> vote(String optionId) async {
    await _supabase.from('poll_votes').upsert({
      'option_id': optionId,
      'user_id': uid,
    });
  }

  Future<Map<String, dynamic>> getPoll(String pollId) async {
    final poll = await _supabase
        .from('polls')
        .select()
        .eq('id', pollId)
        .single();

    final options = await _supabase
        .from('poll_options')
        .select()
        .eq('poll_id', pollId);

    final votes = await _supabase.from('poll_votes').select();

    return {
      'poll': poll,
      'options': options,
      'votes': votes,
    };
  }
}