import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';  

import '../../models/app_user.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<AppUser?> _profileFuture;

  @override
  void initState() {
    super.initState();
    final profileService =
        Provider.of<ProfileService>(context, listen: false);
    _profileFuture = profileService.getCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;
            if (user == null) {
              return const Center(
                child: Text('No profile found'),
              );
            }

            // نجمع السكيلز والسبجكتس للعرض
            final skills = <String>{
              ...user.skills,
              ...user.subjects,
            }.where((e) => e.trim().isNotEmpty).toList();

            final bioText =
                user.bio.isNotEmpty ? user.bio : 'No bio added yet';

            // نقرأ رابط لينكدإن (لو موجود)
            final linkedinUrl = (user.linkedinUrl ?? '').trim();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // صورة البروفايل
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الاسم
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                 

                

                  // ===== Bio =====
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
                      bioText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== LinkedIn =====
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
                  _LinkCard(
  url: linkedinUrl.isEmpty ? null : linkedinUrl,
  onTap: () async {
    if (linkedinUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No LinkedIn URL added. Edit your profile to add one.',
          ),
        ),
      );
      return;
    }

    // نضيف https:// إذا المستخدم نسي يكتبه
    String formatted = linkedinUrl.trim();
    if (!formatted.startsWith('http://') &&
        !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }

    final uri = Uri.tryParse(formatted);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid LinkedIn URL')),
      );
      return;
    }

    // نحاول نفتح الرابط مباشرة
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  },
),


                  const SizedBox(height: 24),

                  // ===== Skills & Expertise =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Skills & Expertise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (skills.isEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No skills added yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills
                            .map(
                              (s) => Chip(
                                label: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: const Color(0xFFE3F2FD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // الأزرار: Edit Profile / View Posts / Logout
                  _ProfileButton(
                    text: 'Edit Profile',
                    icon: Icons.edit,
                    colors: const [Color(0xFF2D9CDB), Color(0xFF2F80ED)],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                      // بعد الرجوع نعيد تحميل البروفايل
                      setState(() {
                        final profileService =
                            Provider.of<ProfileService>(context,
                                listen: false);
                        _profileFuture =
                            profileService.getCurrentUserProfile();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProfileButton(
                    text: 'View Posts',
                    icon: Icons.article_outlined,
                    colors: const [Color(0xFF27AE60), Color(0xFF2ECC71)],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Posts feature coming soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProfileButton(
                    text: 'Logout',
                    icon: Icons.logout,
                    colors: const [Color(0xFFEB5757), Color(0xFFFF758C)],
                    onTap: () async {
                      final auth =
                          Provider.of<AuthService>(context, listen: false);
                      await auth.signOut();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.text,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// كارد جميل لرابط لينكدإن
class _LinkCard extends StatelessWidget {
  final String? url;
  final VoidCallback onTap;

  const _LinkCard({
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0A66C2),
              child: const Icon(Icons.link, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasUrl ? url! : 'No LinkedIn URL added',
                style: TextStyle(
                  fontSize: 13,
                  color: hasUrl ? Colors.black87 : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              hasUrl ? Icons.open_in_new : Icons.add_link,
              color: const Color(0xFF0A66C2),
            ),
          ],
        ),
      ),
    );
  }
}
