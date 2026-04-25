import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/posts_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    try {
      await context.read<PostsService>().createPost(content: text);
      _postController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post failed: $e')),
      );
    }
  }

  void _openComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F6FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CommentsSheet(postId: post['id']),
    );
  }

  Widget _buildCreatePostBox() {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share something with the community...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.send),
                label: const Text('Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profile'];
    final name = profile?['full_name'] ?? 'User';
    final content = post['content'] ?? '';
    final createdAt = _formatDate(post['created_at']);
    final likes = post['likes_count'] ?? 0;
    final comments = post['comments_count'] ?? 0;
    final likedByMe = post['liked_by_me'] == true;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2F80ED),
                  child: Text(
                    name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content.toString(), style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await context.read<PostsService>().toggleLike(post['id']);
                  },
                  icon: Icon(
                    likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: likedByMe ? Colors.red : Colors.grey,
                  ),
                  label: Text('$likes'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _openComments(post),
                  icon: const Icon(Icons.comment_outlined),
                  label: Text('$comments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(title: const Text('Community Feed')),
      body: Column(
        children: [
          _buildCreatePostBox(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context.read<PostsService>().watchPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, index) {
                    return _buildPostCard(posts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;

  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _reloadComments();
  }

  void _reloadComments() {
    _commentsFuture = context.read<PostsService>().getComments(widget.postId);
  }

  Future<void> _sendComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    await context.read<PostsService>().addComment(
          postId: widget.postId,
          comment: comment,
        );

    _commentController.clear();

    if (!mounted) return;
    setState(_reloadComments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (_, index) {
                      final c = comments[index];
                      final name = c['profile']?['full_name'] ?? 'User';

                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF2F80ED),
                            child: Text(
                              name.toString().isNotEmpty
                                  ? name.toString()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            name.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(c['comment'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
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
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendComment,
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