import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../services/chat_service.dart';

import '../chat/chat_screen.dart';
import '../community/tutor_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  List<AppUser> _results = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    final profileService =
        Provider.of<ProfileService>(context, listen: false);

    final list = await profileService.searchTutors(query);

    if (!mounted) return;
    setState(() {
      _results = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // حقل البحث
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search tutors by skill or subject...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty && !_loading
                  ? const Center(
                      child: Text(
                        'Start searching for Groups...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final u = _results[i];
                        final skillsText = u.skills.isEmpty
                            ? 'No skills listed'
                            : u.skills.join(', ');

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              u.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              skillsText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // الضغط على الـ ListTile يفتح بروفايل المعلّم
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TutorProfileScreen(user: u),
                                ),
                              );
                            },

                            // زر الشات على اليمين
                            trailing: IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () async {
                                final chatService =
                                    Provider.of<ChatService>(context,
                                        listen: false);
                                final profileService =
                                    Provider.of<ProfileService>(context,
                                        listen: false);

                                // نجيب اسم المستخدم الحالي (اختياري)
                                final me = await profileService
                                    .getCurrentUserProfile();
                                final currentName =
                                    (me != null && me.fullName.isNotEmpty)
                                        ? me.fullName
                                        : 'You';

                                final conv =
                                    await chatService.startOrGetConversation(
                                  otherUserId: u.id,
                                  currentUserName: currentName,
                                  otherUserName: u.fullName,
                                );

                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: conv.id,
                                      otherUserName: u.fullName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
