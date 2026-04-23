import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';
import '../chat/chat_screen.dart';

class TutorProfileScreen extends StatelessWidget {
  final AppUser user;

  const TutorProfileScreen({
    super.key,
    required this.user,
  });

  String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  Future<void> _openLinkedIn(BuildContext context, String url) async {
    final normalized = _normalizeUrl(url);
    try {
      final uri = Uri.parse(normalized);
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open LinkedIn link')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid LinkedIn URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedin = user.linkedinUrl; // يفترض عندك هذا الحقل في AppUser

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'Tutor Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent,
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              userRoleToString(user.role).toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),

            // ===== Bio =====
            if (user.bio.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  user.bio,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ===== LinkedIn (اختياري) =====
            if (linkedin != null && linkedin.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LinkedIn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _openLinkedIn(context, linkedin),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link,
                        color: Color(0xFF0A66C2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          linkedin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0A66C2),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ===== Skills & Subjects =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Skills & Subjects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...user.skills.map(
                    (s) => Chip(
                      label: Text(s),
                      backgroundColor: const Color(0xFFE3F2FD),
                    ),
                  ),
                  ...user.subjects.map(
                    (s) => Chip(
                      label: Text(s),
                      backgroundColor: const Color(0xFFE8F5E9),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // ===== Contact button =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  'Contact ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () async {
                  final chatService =
                      Provider.of<ChatService>(context, listen: false);
                  final profileService =
                      Provider.of<ProfileService>(context, listen: false);

                  // نجيب اسم المستخدم الحالي من البروفايل
                  final me =
                      await profileService.getCurrentUserProfile();
                  final currentUserName =
                      (me != null && me.fullName.isNotEmpty)
                          ? me.fullName
                          : 'You';

                  try {
                    final conv = await chatService.startOrGetConversation(
                      otherUserId: user.id,
                      currentUserName: currentUserName,
                      otherUserName: user.fullName,
                    );

                    if (!context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conv.id,
                          otherUserName: user.fullName,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open chat: $e'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}