import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'group_chat_screen.dart';
import '../../models/study_group.dart';
import '../../models/group_task.dart';
import '../../services/groups_service.dart';
import '../../services/group_tasks_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final StudyGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  late Future<List<Map<String, dynamic>>> _pinnedFuture;
  late Future<List<GroupTask>> _groupTasksFuture;

  bool get _isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid == widget.group.createdBy;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    final groupsService = context.read<GroupsService>();
    final groupTasksService = context.read<GroupTasksService>();

    _membersFuture = groupsService.getGroupMembers(widget.group.id);
    _pinnedFuture = groupsService.getPinnedFiles(widget.group.id);
    _groupTasksFuture = groupTasksService.getGroupTasks(widget.group.id);
  }

  void _reloadGroupTasks() {
    _groupTasksFuture =
        context.read<GroupTasksService>().getGroupTasks(widget.group.id);
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAddGroupTaskDialog() async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only group owner can add tasks')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();

    String priority = 'medium';
    DateTime? dueDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Add Group Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => priority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      title: const Text('Due Date'),
                      subtitle: Text(
                        dueDate == null
                            ? 'No date selected'
                            : _formatDate(dueDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dueDate != null)
                            IconButton(
                              onPressed: () {
                                setLocalState(() => dueDate = null);
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                              );

                              if (picked != null) {
                                setLocalState(() => dueDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    if (titleController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    try {
      await context.read<GroupTasksService>().addGroupTask(
            groupId: widget.group.id,
            title: titleController.text,
            description: descController.text,
            priority: priority,
            dueDate: dueDate,
          );

      if (!mounted) return;
      setState(_reloadGroupTasks);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group task added')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add failed: $e')),
      );
    }
  }

  Future<void> _toggleGroupTask(GroupTask task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    try {
      await context.read<GroupTasksService>().updateGroupTaskStatus(
            taskId: task.id,
            status: newStatus,
          );

      if (!mounted) return;
      setState(_reloadGroupTasks);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteGroupTask(GroupTask task) async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only group owner can delete tasks')),
      );
      return;
    }

    try {
      await context.read<GroupTasksService>().deleteGroupTask(task.id);

      if (!mounted) return;
      setState(_reloadGroupTasks);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group task deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Widget _buildGroupTasksSection() {
    return FutureBuilder<List<GroupTask>>(
      future: _groupTasksFuture,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];

        final total = tasks.length;
        final completed = tasks.where((t) => t.status == 'completed').length;
        final progress = total == 0 ? 0.0 : completed / total;
        final percent = (progress * 100).round();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Group Tasks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_isOwner)
                      IconButton(
                        onPressed: _showAddGroupTaskDialog,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Group Progress',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed of $total tasks completed ($percent%)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator())
                else if (tasks.isEmpty)
                  const Text(
                    'No group tasks yet',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...tasks.map((task) {
                    final checked = task.status == 'completed';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        leading: Checkbox(
                          value: checked,
                          onChanged: _isOwner ? (_) => _toggleGroupTask(task) : null,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration:
                                checked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((task.description ?? '').trim().isNotEmpty)
                              Text(task.description!),
                            if (task.dueDate != null)
                              Text('Due: ${_formatDate(task.dueDate!)}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _priorityColor(task.priority)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                task.priority.toUpperCase(),
                                style: TextStyle(
                                  color: _priorityColor(task.priority),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: _isOwner
                            ? IconButton(
                                onPressed: () => _deleteGroupTask(task),
                                icon: const Icon(Icons.delete_outline),
                              )
                            : null,
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Subject: ${group.subject}'),
                    const SizedBox(height: 4),
                    Text('Code: ${group.groupCode}'),
                    const SizedBox(height: 4),
                    Text('Members: ${group.membersCount}'),
                    if ((group.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        group.description!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(group: group),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Open Group Chat'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildGroupTasksSection(),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pinned Files',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _pinnedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final files = snapshot.data ?? [];

                if (files.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'No pinned files',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: files.map((f) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.push_pin),
                        title: Text(f['file_name'] ?? 'File'),
                        subtitle: const Text('Tap to open'),
                        onTap: () => _openFile(f['file_url']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Members',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return const Center(child: Text('No members'));
                }

                return Column(
                  children: members.map((m) {
                    final name = m['profiles']?['full_name'] ??
                        m['user_id'].toString().substring(0, 6);

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(name),
                      subtitle: Text(m['role']),
                      trailing: m['role'] == 'owner'
                          ? const Icon(Icons.star, color: Colors.orange)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}