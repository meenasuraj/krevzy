import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../services/post_actions_service.dart';
import '../screens/comments_screen.dart';
import '../screens/public_profile_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  Post get _post => widget.post;
  bool _isLiked = false;
  bool _isLikeLoading = false;
  bool _isDeleteLoading = false;
  bool _isSaved = false;
  bool _isSaveLoading = false;

  late final AnimationController
      _likeAnimationController;

  late final Animation<double>
      _likeScaleAnimation;

  @override
  void initState() {
    super.initState();

    _likeAnimationController =
        AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 220,
      ),
    );

    _likeScaleAnimation =
        TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.22,
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.22,
          end: 1.0,
        ),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _loadLikeStatus();
    _loadSavedStatus();
  }

  @override
  void didUpdateWidget(
    covariant PostCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id != _post.id) {
      _isLiked = false;
      _isSaved = false;
      _loadLikeStatus();
      _loadSavedStatus();
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedStatus() async {
    try {
      final saved = await PostActionsService.isSaved(_post.id);
      if (mounted) setState(() => _isSaved = saved);
    } catch (_) {}
  }

  Future<void> _toggleSaved() async {
    if (_isSaveLoading) return;
    setState(() => _isSaveLoading = true);
    try {
      final saved = await PostActionsService.toggleSaved(_post.id);
      if (mounted) {
        setState(() => _isSaved = saved);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved ? 'Post saved.' : 'Post removed from saved posts.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to save post: $e')));
    } finally { if (mounted) setState(() => _isSaveLoading = false); }
  }

  // ============================================================
  // LOAD CURRENT USER LIKE STATUS
  // ============================================================

  Future<void> _loadLikeStatus() async {
    try {
      final liked =
          await PostService.hasLiked(
        _post.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLiked = liked;
      });
    } catch (_) {
      // Keep default false.
    }
  }

  // ============================================================
  // TOGGLE LIKE
  // ============================================================

  Future<void> _toggleLike() async {
    if (_isLikeLoading) {
      return;
    }

    setState(() {
      _isLikeLoading = true;
    });

    try {
      await PostService.likePost(
        _post.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLiked = !_isLiked;
      });

      if (_isLiked) {
        await _likeAnimationController.forward(
          from: 0,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Like update nahi ho saka: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  void _openComments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          postId: _post.id,
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: _post.userId,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  Future<void> _deletePost() async {
    if (_isDeleteLoading) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete post?',
          ),
          content: const Text(
            'This post will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleteLoading = true;
    });

    try {
      await PostService.deletePost(
        _post.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post deleted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post delete nahi ho saka: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleteLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final difference =
        DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    final photo =
        _post.userPhotoUrl.trim();

    if (photo.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photo),
      );
    }

    final name =
        _post.userName.trim().isNotEmpty
            ? _post.userName.trim()
            : _post.username.trim();

    final letter = name.isNotEmpty
        ? name[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 20,
      child: Text(
        letter,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // POST MENU
  // ============================================================

  Future<void> _showPostMenu() async {
    final currentUserId =
        PostService.currentUserId;

    final isOwner =
        currentUserId == _post.userId;

    if (!isOwner) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(
              Icons.delete_outline,
            ),
            title: const Text(
              'Delete post',
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _deletePost();
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final displayName =
        _post.userName.trim().isNotEmpty
            ? _post.userName.trim()
            : _post.username.trim();

    final username =
        _post.username.trim();

    return Card(
      margin: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        10,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              8,
              8,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _openProfile,
                  borderRadius:
                      BorderRadius.circular(30),
                  child: _buildAvatar(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _openProfile,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isNotEmpty
                              ? displayName
                              : 'GAPSHAP User',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        if (username.isNotEmpty)
                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _formatDate(
                    _post.createdAt,
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'More',
                  onPressed: _showPostMenu,
                  icon: _isDeleteLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.more_vert,
                        ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // CAPTION
          // ------------------------------------------------------

          if (_post.caption
              .trim()
              .isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                14,
                4,
                14,
                12,
              ),
              child: Text(
                _post.caption,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),

          // ------------------------------------------------------
          // MEDIA
          // ------------------------------------------------------

          if (_post.mediaUrl
              .trim()
              .isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                _post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 50,
                    ),
                  );
                },
              ),
            ),

          // ------------------------------------------------------
          // LIVE COUNTS
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              10,
              14,
              4,
            ),
            child: StreamBuilder<int>(
              stream: PostService.getLikeCount(
                _post.id,
              ),
              builder: (
                context,
                likeSnapshot,
              ) {
                final likesCount =
                    likeSnapshot.data ?? 0;

                return Row(
                  children: [
                    if (likesCount > 0)
                      Text(
                        '$likesCount '
                        '${likesCount == 1 ? 'like' : 'likes'}',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    const Spacer(),
                    if (_post.commentsCount > 0)
                      InkWell(
                        onTap: _openComments,
                        child: Text(
                          '${_post.commentsCount} '
                          '${_post.commentsCount == 1 ? 'comment' : 'comments'}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ------------------------------------------------------
          // ACTIONS
          // ------------------------------------------------------

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation:
                        _likeScaleAnimation,
                    builder:
                        (context, child) {
                      return Transform.scale(
                        scale:
                            _likeScaleAnimation
                                .value,
                        child: child,
                      );
                    },
                    child: IconButton(
                      tooltip: _isLiked
                          ? 'Unlike'
                          : 'Like',
                      onPressed: _toggleLike,
                      icon: _isLikeLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isLiked
                                  ? Icons.favorite
                                  : Icons
                                      .favorite_border,
                              color: _isLiked
                                  ? Colors.red
                                  : null,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Comments',
                    onPressed: _openComments,
                    icon: const Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Share',
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Share coming soon',
                          ),
                          behavior:
                              SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Save',
                    onPressed: _isSaveLoading ? null : _toggleSaved,
                    icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
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