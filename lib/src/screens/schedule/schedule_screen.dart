import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/study_session.dart';
import '../../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<StudySession>> _future;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<ScheduleService>().getSessions();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _dayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _displayTime12(String value) {
    final t = _parseTime(value);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'exam':
        return const Color(0xFFFF5A1F);
      case 'class':
        return const Color(0xFF0072FF);
      case 'study':
        return const Color(0xFF00C853);
      default:
        return const Color(0xFFB14DFF);
    }
  }

  Future<void> _showSessionDialog({StudySession? session}) async {
    final titleController = TextEditingController(text: session?.title ?? '');
    final descController =
        TextEditingController(text: session?.description ?? '');

    DateTime selectedDate = session?.sessionDate ?? _selectedDate;
    TimeOfDay startTime =
        session != null ? _parseTime(session.startTime) : TimeOfDay.now();

    TimeOfDay endTime = session != null
        ? _parseTime(session.endTime)
        : TimeOfDay(
            hour: (TimeOfDay.now().hour + 1) % 24,
            minute: TimeOfDay.now().minute,
          );

    String selectedType = session?.sessionType ?? 'study';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(session == null ? 'Add Session' : 'Edit Session'),
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
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'study', child: Text('Study')),
                        DropdownMenuItem(value: 'exam', child: Text('Exam')),
                        DropdownMenuItem(value: 'class', child: Text('Class')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      title: const Text('Date'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setLocalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setLocalState(() => startTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      trailing: const Icon(Icons.access_time_filled),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setLocalState(() => endTime = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      _saving ? null : () => Navigator.pop(context, true),
                  child: Text(session == null ? 'Add' : 'Save'),
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

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      _saving = true;

      final service = context.read<ScheduleService>();

      if (session == null) {
        await service.addSession(
          title: titleController.text,
          description: descController.text,
          sessionType: selectedType,
          sessionDate: selectedDate,
          startTime: _formatTimeOfDay(startTime),
          endTime: _formatTimeOfDay(endTime),
        );
      } else {
        await service.updateSession(
          sessionId: session.id,
          title: titleController.text,
          description: descController.text,
          sessionType: selectedType,
          sessionDate: selectedDate,
          startTime: _formatTimeOfDay(startTime),
          endTime: _formatTimeOfDay(endTime),
        );
      }

      if (!mounted) return;

      setState(() {
        _selectedDate = selectedDate;
        _reload();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            session == null
                ? 'Session added successfully'
                : 'Session updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      _saving = false;
    }
  }

  Future<void> _deleteSession(StudySession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
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
      await context.read<ScheduleService>().deleteSession(session.id);

      if (!mounted) return;
      setState(_reload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _showSessionActions(StudySession session) {
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
                  title: const Text('Edit session'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSessionDialog(session: session);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete session',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteSession(session);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    return List.generate(5, (index) => today.add(Duration(days: index - 2)));
  }

  Widget _buildHeader() {
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
              const Expanded(
                child: Text(
                  'Study Schedule',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
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

  Widget _buildDatePicker() {
    final days = _weekDays();

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: days.map((day) {
          final selected = _sameDay(day, _selectedDate);

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () {
                setState(() => _selectedDate = day);
              },
              child: Container(
                height: 68,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0072FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayName(day),
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF334155),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionCard(StudySession session) {
    final color = _typeColor(session.sessionType);

    return GestureDetector(
      onLongPress: () => _showSessionActions(session),
      onTap: () => _showSessionActions(session),
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFF0072FF).withOpacity(0.85),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF64748B),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${_displayTime12(session.startTime)} - ${_displayTime12(session.endTime)}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if ((session.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<StudySession> sessions) {
    final selectedSessions = sessions
        .where((s) => _sameDay(s.sessionDate, _selectedDate))
        .toList();

    selectedSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Expanded(
      child: selectedSessions.isEmpty
          ? const Center(
              child: Text(
                'No sessions for this day',
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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 0, 22, 16),
                    child: Text(
                      "Today's Sessions",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ...selectedSessions.map(_buildSessionCard),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudySession>>(
      future: _future,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FB),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                if (snapshot.connectionState != ConnectionState.done)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Expanded(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  )
                else ...[
                  _buildDatePicker(),
                  _buildSessionsList(sessions),
                ],
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF0072FF),
            onPressed: () => _showSessionDialog(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}