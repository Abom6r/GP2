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
    final profileService =
        Provider.of<ProfileService>(context, listen: false);
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

  Widget _buildNotificationButton() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<NotificationsService>().watchNotifications(),
      builder: (context, snapshot) {
        final unread = snapshot.data
                ?.where((n) => n['is_read'] == false)
                .length ??
            0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
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
            if (unread > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
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

  Widget _buildProgressAndTasks() {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final completed =
            tasks.where((t) => t.status == 'completed').length;
        final total = tasks.length;
        final progress = total == 0 ? 0.0 : completed / total;
        final percent = (progress * 100).round();

        final visibleTasks = tasks.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed of $total tasks completed ($percent%)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TasksScreen(),
                      ),
                    ).then((_) => setState(_reloadTasks));
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
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

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    value: checked,
                    onChanged: (_) => _toggleTask(task),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      task.priority.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildHomeTab() {
    final today = DateFormat('d MMM, yyyy').format(DateTime.now());

    return FutureBuilder<AppUser?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.fullName?.isNotEmpty == true
            ? user!.fullName
            : 'Ahmed';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [Color(0xFF005BEA), Color(0xFF00C6FB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'IU',
                        style: TextStyle(
                          color: Color(0xFF005BEA),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          today,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildNotificationButton(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildProgressAndTasks(),
              const SizedBox(height: 18),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Choose what you'd like to do today",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _QuickActionCard(
                      title: 'Schedule',
                      subtitle: 'Look to your schedule',
                      gradientColors: const [
                        Color(0xFF2D9CDB),
                        Color(0xFF2F80ED),
                      ],
                      icon: Icons.calendar_today,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: 'Tasks',
                      subtitle: 'Manage your tasks',
                      gradientColors: const [
                        Color(0xFF2D9CDB),
                        Color(0xFF2F80ED),
                      ],
                      icon: Icons.check_circle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TasksScreen(),
                          ),
                        ).then((_) => setState(_reloadTasks));
                      },
                    ),
                    _QuickActionCard(
                      title: 'Groups',
                      subtitle: 'Find study groups',
                      gradientColors: const [
                        Color(0xFF56CCF2),
                        Color(0xFF2F80ED),
                      ],
                      icon: Icons.group_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupsScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: 'Profile',
                      subtitle: 'View your profile',
                      gradientColors: const [
                        Color(0xFF9B51E0),
                        Color(0xFFBB6BD9),
                      ],
                      icon: Icons.person,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: 'Community',
                      subtitle: 'Join discussions',
                      gradientColors: const [
                        Color(0xFFF2C94C),
                        Color(0xFFF2994A),
                      ],
                      icon: Icons.groups,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityScreen(),
                          ),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: 'Messages',
                      subtitle: 'Chat with peers',
                      gradientColors: const [
                        Color(0xFFEB5757),
                        Color(0xFFFF758C),
                      ],
                      icon: Icons.chat_bubble_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConversationsScreen(),
                          ),
                        );
                      },
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
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}