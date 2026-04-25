import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/study_group.dart';
import '../../services/group_chat_service.dart';
import '../../services/groups_service.dart';
import '../../services/polls_service.dart';
import '../../widgets/poll_widget.dart';
class GroupChatScreen extends StatefulWidget {
  final StudyGroup group;

  const GroupChatScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _uploading = false;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  bool get _isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid == widget.group.createdBy;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    try {
      await context.read<GroupChatService>().sendMessage(
            groupId: widget.group.id,
            message: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_uploading) return;

    try {
      setState(() => _uploading = true);

      await context.read<GroupChatService>().uploadAndSendFile(
            groupId: widget.group.id,
          );

      if (!mounted) return;
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _showCreatePollDialog() async {
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();
    final option3Controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: option1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Option 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: option2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Option 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: option3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Option 3 optional',
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

    final question = questionController.text.trim();
    final options = [
      option1Controller.text.trim(),
      option2Controller.text.trim(),
      option3Controller.text.trim(),
    ].where((e) => e.isNotEmpty).toList();

    if (question.isEmpty || options.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question and at least 2 options are required'),
        ),
      );
      return;
    }

    try {
      await context.read<PollsService>().createPoll(
            groupId: widget.group.id,
            question: question,
            options: options,
          );

      if (!mounted) return;
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poll failed: $e')),
      );
    }
  }

  Future<void> _openFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!opened) {
        final openedExternal = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!openedExternal) {
          throw Exception('Could not launch URL');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
    }
  }

  Future<void> _pinFile({
    required String fileUrl,
    required String fileName,
  }) async {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only group owner can pin files')),
      );
      return;
    }

    try {
      await context.read<GroupsService>().pinFile(
            groupId: widget.group.id,
            fileUrl: fileUrl,
            fileName: fileName,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File pinned successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pin failed: $e')),
      );
    }
  }

  Widget _buildTextMessage({
    required bool isMe,
    required String message,
    required String formattedTime,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedTime,
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage({
    required bool isMe,
    required Map<String, dynamic> msg,
    required String formattedTime,
  }) {
    final fileName = msg['file_name'] ?? msg['message'] ?? 'File';
    final fileSize = msg['file_size'];
    final fileUrl = msg['file_url'];

    String sizeText = '';
    if (fileSize != null) {
      final size = int.tryParse(fileSize.toString()) ?? 0;
      if (size >= 1024 * 1024) {
        sizeText = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else if (size >= 1024) {
        sizeText = '${(size / 1024).toStringAsFixed(1)} KB';
      } else {
        sizeText = '$size B';
      }
    }

    return GestureDetector(
      onTap: fileUrl == null ? null : () => _openFile(fileUrl.toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                color: isMe ? Colors.white : const Color(0xFF2F80ED),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sizeText.isNotEmpty)
                      Text(
                        sizeText,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isOwner)
                IconButton(
                  icon: const Icon(Icons.push_pin, size: 18),
                  color: isMe ? Colors.white70 : Colors.grey,
                  onPressed: fileUrl == null
                      ? null
                      : () => _pinFile(
                            fileUrl: fileUrl.toString(),
                            fileName: fileName.toString(),
                          ),
                ),
            ],
          ),
          if (fileUrl != null) ...[
            const SizedBox(height: 6),
            Text(
              'Tap to open',
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _currentUserId;
    final message = msg['message'] ?? '';
    final messageType = msg['message_type'] ?? 'text';

    final name = msg['profile']?['full_name'] ??
        msg['sender_id'].toString().substring(0, 6);

    final time = DateTime.parse(msg['created_at']).toLocal();
    final formattedTime =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (messageType != 'poll')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                name,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: messageType == 'poll'
                  ? Colors.transparent
                  : isMe
                      ? const Color(0xFF2F80ED)
                      : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: messageType == 'file'
                ? _buildFileMessage(
                    isMe: isMe,
                    msg: msg,
                    formattedTime: formattedTime,
                  )
                : messageType == 'poll'
                    ? PollWidget(pollId: msg['poll_id'])
                    : _buildTextMessage(
                        isMe: isMe,
                        message: message,
                        formattedTime: formattedTime,
                      ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context
                  .read<GroupChatService>()
                  .watchMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = [...(snapshot.data ?? [])];

                messages.sort((a, b) {
                  final aTime = DateTime.parse(a['created_at']);
                  final bTime = DateTime.parse(b['created_at']);
                  return aTime.compareTo(bTime);
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the discussion.'),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: IconButton(
                    onPressed: _uploading ? null : _uploadFile,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.attach_file,
                            color: Color(0xFF2F80ED),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: IconButton(
                    onPressed: _showCreatePollDialog,
                    icon: const Icon(
                      Icons.poll,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2F80ED),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}