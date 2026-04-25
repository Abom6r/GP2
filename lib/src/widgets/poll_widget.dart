import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/polls_service.dart';

class PollWidget extends StatelessWidget {
  final String pollId;

  const PollWidget({super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    final service = context.read<PollsService>();
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return FutureBuilder<Map<String, dynamic>>(
      future: service.getPoll(pollId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text('Poll error: ${snapshot.error}');
        }

        final data = snapshot.data!;
        final poll = data['poll'] as Map<String, dynamic>;
        final options = data['options'] as List;
        final votes = data['votes'] as List;

        final totalVotes = votes.length;

        Map<String, dynamic>? userVote;

        for (final v in votes) {
          final vote = v as Map<String, dynamic>;
          if (vote['user_id'] == currentUserId) {
            userVote = vote;
            break;
          }
        }

        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.poll, color: Color(0xFF2F80ED)),
                    SizedBox(width: 6),
                    Text(
                      'Poll',
                      style: TextStyle(
                        color: Color(0xFF2F80ED),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  poll['question'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                ...options.map((rawOpt) {
                  final opt = rawOpt as Map<String, dynamic>;

                  final count = votes.where((rawVote) {
                    final vote = rawVote as Map<String, dynamic>;
                    return vote['option_id'] == opt['id'];
                  }).length;

                  final percent = totalVotes == 0 ? 0.0 : count / totalVotes;

                  final isSelected =
                      userVote != null && userVote!['option_id'] == opt['id'];

                  return InkWell(
                    onTap: userVote != null
                        ? null
                        : () async {
                            await service.vote(opt['id']);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2F80ED).withOpacity(0.18)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2F80ED)
                              : Colors.transparent,
                        ),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: percent,
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F80ED)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 38,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt['option_text'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(percent * 100).round()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 4),

                Text(
                  '$totalVotes votes',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}