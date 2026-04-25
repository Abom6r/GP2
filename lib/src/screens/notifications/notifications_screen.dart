import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notifications_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final local = date.toLocal();

    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<NotificationsService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await service.markAllAsRead();
            },
            child: const Text('Read all'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              final isRead = notification['is_read'] == true;
              final title = notification['title']?.toString() ?? '';
              final body = notification['body']?.toString() ?? '';
              final createdAt = _formatDate(notification['created_at']);

              return Card(
                color: isRead ? Colors.white : const Color(0xFFEAF2FF),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isRead ? Colors.grey : const Color(0xFF2F80ED),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (body.isNotEmpty) Text(body),
                      const SizedBox(height: 4),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : const Icon(
                          Icons.circle,
                          size: 10,
                          color: Color(0xFF2F80ED),
                        ),
                  onTap: () async {
                    await service.markAsRead(notification['id']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}