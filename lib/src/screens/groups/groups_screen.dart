import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_group.dart';
import '../../services/groups_service.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late Future<List<StudyGroup>> _future;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context
        .read<GroupsService>()
        .getGroups(query: _searchController.text);
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Study Group'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    if (nameController.text.trim().isEmpty ||
        subjectController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name and subject are required')),
      );
      return;
    }

    try {
      await context.read<GroupsService>().createGroup(
            name: nameController.text,
            subject: subjectController.text,
            description: descController.text,
          );

      if (!mounted) return;
      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  Future<void> _joinOrLeave(StudyGroup group) async {
    try {
      final service = context.read<GroupsService>();

      if (group.isMember) {
        await service.leaveGroup(group.id);
      } else {
        await service.joinGroup(group.id);
      }

      if (!mounted) return;
      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            group.isMember
                ? 'Left group successfully'
                : 'Joined group successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }

  Widget _buildGroupCard(StudyGroup group) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailsScreen(group: group),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(14),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subject: ${group.subject}'),
              const SizedBox(height: 4),
              Text('Code: ${group.groupCode}'),
              const SizedBox(height: 4),
              Text('Members: ${group.membersCount}'),
              if ((group.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(group.description!),
              ],
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinOrLeave(group),
          child: Text(group.isMember ? 'Leave' : 'Join'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Study Groups'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(_reload);
              },
              decoration: InputDecoration(
                hintText: 'Search by group, subject, or code',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(_reload);
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StudyGroup>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final groups = snapshot.data ?? [];

                if (groups.isEmpty) {
                  return const Center(
                    child: Text('No groups found. Tap + to create one.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _future;
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: groups.length,
                    itemBuilder: (_, index) {
                      return _buildGroupCard(groups[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}