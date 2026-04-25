import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../services/tasks_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<Task>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<TasksService>().getTasks();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF5A5F);
      case 'medium':
        return const Color(0xFFF2C94C);
      case 'low':
        return const Color(0xFF2ECC71);
      default:
        return Colors.grey;
    }
  }

  Color _priorityBg(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFFE5E7);
      case 'medium':
        return const Color(0xFFFFF4B8);
      case 'low':
        return const Color(0xFFDFFFEA);
      default:
        return Colors.grey.shade200;
    }
  }

  String _priorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
        return 'low';
      default:
        return priority;
    }
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    try {
      await context.read<TasksService>().updateTaskStatus(
            taskId: task.id,
            status: newStatus,
          );

      if (!mounted) return;
      setState(_reload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _showTaskDialog({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');

    DateTime? selectedDate = task?.dueDate;
    String selectedPriority = task?.priority ?? 'medium';
    String selectedStatus = task?.status ?? 'pending';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(task == null ? 'Add Task' : 'Edit Task'),
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
                      value: selectedPriority,
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
                          setLocalState(() => selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => selectedStatus = value);
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
                        selectedDate == null
                            ? 'No date selected'
                            : _formatDate(selectedDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedDate != null)
                            IconButton(
                              onPressed: () {
                                setLocalState(() => selectedDate = null);
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setLocalState(() => selectedDate = picked);
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
                  child: Text(task == null ? 'Add' : 'Save'),
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
      final service = context.read<TasksService>();

      if (task == null) {
        await service.addTask(
          title: titleController.text,
          description: descController.text,
          priority: selectedPriority,
          status: selectedStatus,
          dueDate: selectedDate,
        );
      } else {
        await service.updateTask(
          taskId: task.id,
          title: titleController.text,
          description: descController.text,
          priority: selectedPriority,
          status: selectedStatus,
          dueDate: selectedDate,
        );
      }

      if (!mounted) return;
      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task == null
                ? 'Task added successfully'
                : 'Task updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<TasksService>().deleteTask(task.id);

      if (!mounted) return;
      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _showTaskActions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit task'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTaskDialog(task: task);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete task',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTask(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0072FF),
            Color(0xFF00C6FB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            '$remaining tasks remaining',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == 'completed';

    return GestureDetector(
      onLongPress: () => _showTaskActions(task),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _toggleTaskStatus(task),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF266B6F)
                      : const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _showTaskActions(task),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: isCompleted
                            ? const Color(0xFF9AA4B2)
                            : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight:
                            isCompleted ? FontWeight.w400 : FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _priorityBg(task.priority),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _priorityText(task.priority),
                        style: TextStyle(
                          color: _priorityColor(task.priority),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Due: ${_formatDate(task.dueDate!)}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _future,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final remaining =
            tasks.where((task) => task.status != 'completed').length;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(remaining),
                Expanded(
                  child: snapshot.connectionState != ConnectionState.done
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError
                          ? Center(child: Text('Error: ${snapshot.error}'))
                          : tasks.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No tasks yet. Tap + to add one.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    setState(_reload);
                                    await _future;
                                  },
                                  child: ListView.builder(
                                    padding:
                                        const EdgeInsets.only(top: 18, bottom: 90),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: tasks.length,
                                    itemBuilder: (context, index) {
                                      return _buildTaskCard(tasks[index]);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF0072FF),
            onPressed: () => _showTaskDialog(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}