import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
import '../community/community_screen.dart';
import '../tasks/task_screen.dart';
import '../../models/app_user.dart';
import '../../models/task.dart';
import '../../services/profile_service.dart';
import '../../services/tasks_service.dart';
import '../../services/schedule_service.dart';
import '../../services/ai_planner_service.dart';
import '../chat/conversations_screen.dart';
import '../schedule/schedule_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/notifications_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late Future<AppUser?> _profileFuture;
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    final profileService = Provider.of<ProfileService>(context, listen: false);
    _profileFuture = profileService.getCurrentUserProfile();
    _reloadTasks();
  }

  void _reloadTasks() {
    _tasksFuture = context.read<TasksService>().getTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    await context.read<TasksService>().updateTask(
          taskId: task.id,
          title: task.title,
          description: task.description,
          priority: task.priority,
          status: newStatus,
          dueDate: task.dueDate,
        );

    setState(_reloadTasks);
  }

  Future<void> _runAIPlanner() async {
    final controller = TextEditingController();
    bool loading = false;

    final examples = [
      'I have a Database exam after 3 days\nChapter 1: Indexing\nChapter 2: Hashing',
      'Plan my study schedule for finals week',
      'Create tasks for Math assignment',
      'Organize group project deadlines',
    ];

    final prompt = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0072FF),
                              Color(0xFF00C6FB),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'AI Planner',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell me what you need, and I will create a smart schedule and task list for you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Try asking:',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...examples.map(
                        (e) => InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            controller.text = e;
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              e.split('\n').first,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller,
                        minLines: 4,
                        maxLines: 7,
                        decoration: InputDecoration(
                          hintText:
                              'Example:\nI have a Database exam after 3 days\nChapter 1: Indexing\nChapter 2: Hashing',
                          filled: true,
                          fillColor: const Color(0xFFF3F6FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0072FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: loading
                              ? null
                              : () {
                                  final text = controller.text.trim();
                                  if (text.isEmpty) return;
                                  setLocalState(() => loading = true);
                                  Navigator.pop(context, text);
                                },
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            'Generate Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (prompt == null || prompt.trim().isEmpty) return;

    try {
      final plan = await context.read<AIPlannerService>().generatePlan(prompt);

      final sessions =
          (plan['sessions'] as List).cast<Map<String, dynamic>>();
      final tasks = (plan['tasks'] as List).cast<Map<String, dynamic>>();

      for (final s in sessions) {
        await context.read<ScheduleService>().addSession(
              title: s['title'] ?? 'Study Session',
              description: s['description'],
              sessionType: s['session_type'] ?? 'study',
              sessionDate: DateTime.parse(s['session_date']),
              startTime: s['start_time'] ?? '18:00:00',
              endTime: s['end_time'] ?? '20:00:00',
            );
      }

      for (final t in tasks) {
        await context.read<TasksService>().addTask(
              title: t['title'] ?? 'Study Task',
              description: t['description'],
              priority: t['priority'] ?? 'medium',
              status: 'pending',
              dueDate: DateTime.parse(t['due_date']),
            );
      }

      if (!mounted) return;
      setState(_reloadTasks);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Plan Created Successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI failed: $e')),
      );
    }
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<NotificationsService>().watchNotifications(),
      builder: (context, snapshot) {
        final unread =
            snapshot.data?.where((n) => n['is_read'] == false).length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        bottom: false,
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF006BFF),
        unselectedItemColor: const Color(0xFF9AA4B2),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_2_outlined),
            activeIcon: Icon(Icons.groups_2_rounded),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 2:
        return const ConversationsScreen();
      case 3:
        return const ProfileScreen();
      case 1:
      default:
        return const CommunityScreen();
    }
  }

  Widget _buildHomeTab() {
    final today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return FutureBuilder<AppUser?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name =
            user?.fullName?.isNotEmpty == true ? user!.fullName : 'Alex Johnson';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(name, today),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayTasksCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAIPlannerCard(),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _SmallActionCard(
                          title: 'Schedule',
                          subtitle: 'Study sessions',
                          icon: Icons.calendar_today_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ScheduleScreen(),
                              ),
                            );
                          },
                        ),
                        _SmallActionCard(
                          title: 'Tasks',
                          subtitle: 'Manage to-dos',
                          icon: Icons.check_box_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TasksScreen(),
                              ),
                            ).then((_) => setState(_reloadTasks));
                          },
                        ),
                        _SmallActionCard(
                          title: 'Groups',
                          subtitle: 'Study groups',
                          icon: Icons.groups_2_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GroupsScreen(),
                              ),
                            );
                          },
                        ),
                        _SmallActionCard(
                          title: 'Community',
                          subtitle: 'Social feed',
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CommunityScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name, String today) {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final completed =
            tasks.where((t) => t.status == 'completed').length;
        final total = tasks.length;
        final progress = total == 0 ? 0.0 : completed / total;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0072FF),
                Color(0xFF00C6FB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationButton(),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Today's Progress",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$completed/$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.35),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayTasksCard() {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final visibleTasks = tasks.take(3).toList();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Tasks",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (visibleTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tasks yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...visibleTasks.map((task) {
                  final checked = task.status == 'completed';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _toggleTask(task),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: checked
                                  ? const Color(0xFF266B6F)
                                  : const Color(0xFF3C3C3C),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: checked
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                color: checked
                                    ? const Color(0xFF9AA4B2)
                                    : const Color(0xFF0F172A),
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TasksScreen(),
                      ),
                    ).then((_) => setState(_reloadTasks));
                  },
                  child: const Text(
                    'View All Tasks →',
                    style: TextStyle(
                      color: Color(0xFF006BFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIPlannerCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _runAIPlanner,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF006BFF),
              Color(0xFF00BFEF),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006BFF).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Smart schedule & task creation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF006BFF),
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}