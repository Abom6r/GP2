import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_role.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController(); // نستخدمه كـ email
  final _fullNameCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _selectedCollege;
  UserRole? _selectedRole = UserRole.student;
  bool _loading = false;

  final List<String> _colleges = const [
    'College of Computer Science',
    'College of Engineering',
    'College of Sharia',
    'College of Hadith',
    'College of Qur\'an',
    'College of Da\'wah',
    'Other',
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _skillsCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final profileService =
        Provider.of<ProfileService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back arrow
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const SizedBox(height: 8),

                // Title
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151624),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join the Study Organzier community',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Username
                _SectionLabel('Email'),
                const SizedBox(height: 6),
                _InputCard(
                  icon: Icons.person_outline,
                  child: TextFormField(
                    controller: _usernameCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!v.contains('@')) {
                        // Supabase يحتاج ايميل
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Full name
                _SectionLabel('Full Name'),
                const SizedBox(height: 6),
                _InputCard(
                  icon: Icons.badge_outlined,
                  child: TextFormField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // College (dropdown)
                _SectionLabel('College'),
                const SizedBox(height: 6),
                _InputCard(
                  icon: Icons.school_outlined,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCollege,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    hint: const Text('Select your college'),
                    items: _colleges
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedCollege = val);
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please select your college';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Skills
                _SectionLabel('Skills'),
                const SizedBox(height: 6),
                _InputCard(
                  icon: Icons.lightbulb_outline,
                  child: TextFormField(
                    controller: _skillsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tell us about your skills and interests (comma separated)',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                
                const SizedBox(height: 16),

                // Password
                _SectionLabel('Password'),
                const SizedBox(height: 6),
                _InputCard(
                  icon: Icons.lock_outline,
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Create a strong password',
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Create account button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF355CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _loading
                        ? null
                        : () async {
                            if (_selectedRole == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select your role'),
                                ),
                              );
                              return;
                            }

                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            setState(() => _loading = true);
                            try {
                              final email = _usernameCtrl.text.trim();
                              final fullName = _fullNameCtrl.text.trim();
                              final password = _passwordCtrl.text.trim();
                              final skillsList = _skillsCtrl.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();

                              // 1) إنشاء المستخدم في auth
                              await auth.signUp(
                                email: email,
                                password: password,
                                fullName: fullName,
                              );

                              // 2) إنشاء البروفايل في جدول profiles
                              await profileService.createOrUpdateProfile(
                                role: _selectedRole!,
                                fullName: fullName,
                                email: email,
                                bio: _selectedCollege == null
                                    ? ''
                                    : 'College: $_selectedCollege',
                                skills: skillsList,
                                subjects: const [],
                                linkedinUrl: null,
                              );

                              if (!mounted) return;
                              // 3) الذهاب إلى الـ Home
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Register error: $e'),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _loading = false);
                              }
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Widgets مساعدة للشكل =====

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555B6A),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _InputCard({
    super.key,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF355CFF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF355CFF)
                : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF355CFF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
