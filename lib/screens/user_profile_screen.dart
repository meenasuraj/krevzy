import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/follow_service.dart';
import 'follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String username;
  final String bio;
  final String photoUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.bio,
    required this.photoUrl,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
  });

  @override
  State<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState
    extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isFollowLoading = false;

  bool get _isOwnProfile =>
      _auth.currentUser?.uid == widget.userId;

  Stream<int> _followersCountStream() {
    return _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _followingCountStream() {
    return _firestore
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _toggleFollow(
    bool currentlyFollowing,
  ) async {
    if (_isFollowLoading) {
      return;
    }

    final currentUser = _auth.currentUser;

    if (currentUser == null || _isOwnProfile) {
      return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (currentlyFollowing) {
        await FollowService.unfollow(
          widget.userId,
        );
      } else {
        await FollowService.follow(
          targetUserId: widget.userId,
          targetUsername: widget.username,
          targetName: widget.name,
          targetPhotoUrl: widget.photoUrl,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyFollowing
                ? 'Unfollowed @${widget.username}'
                : 'Following @${widget.username}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Follow action failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    final displayName =
        widget.name.isNotEmpty
            ? widget.name
            : widget.username.isNotEmpty
                ? widget.username
                : 'GAPSHAP User';

    final firstLetter =
        displayName[0].toUpperCase();

    if (widget.photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 50,
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(
        widget.photoUrl,
      ),
    );
  }

  Widget _buildStat({
    required int value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        child: content,
      ),
    );
  }

  Widget _buildFollowButton() {
    if (_isOwnProfile) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: FollowService.followingStream(
        widget.userId,
      ),
      builder: (context, snapshot) {
        final isFollowing =
            snapshot.data ?? false;

        final isWaiting =
            snapshot.connectionState ==
                ConnectionState.waiting;

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                isWaiting || _isFollowLoading
                    ? null
                    : () {
                        _toggleFollow(
                          isFollowing,
                        );
                      },
            icon: _isFollowLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isFollowing
                        ? Icons.person_remove_alt_1
                        : Icons.person_add_alt_1,
                  ),
            label: Text(
              isFollowing
                  ? 'Following'
                  : 'Follow',
            ),
          ),
        );
      },
    );
  }

  void _openFollowers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: widget.userId,
          title: 'Followers',
          showFollowers: true,
        ),
      ),
    );
  }

  void _openFollowing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: widget.userId,
          title: 'Following',
          showFollowers: false,
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.grid_on_outlined,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No posts to show yet.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.name.isNotEmpty
            ? widget.name
            : 'GAPSHAP User';

    final displayUsername =
        widget.username.isNotEmpty
            ? '@${widget.username}'
            : '@user';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          displayUsername,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatar(),

            const SizedBox(height: 16),

            Text(
              displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              displayUsername,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 15,
              ),
            ),

            if (widget.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(
                  value: widget.postsCount,
                  label: 'Posts',
                ),

                StreamBuilder<int>(
                  stream: _followersCountStream(),
                  initialData: widget.followersCount,
                  builder: (context, snapshot) {
                    return _buildStat(
                      value: snapshot.data ??
                          widget.followersCount,
                      label: 'Followers',
                      onTap: _openFollowers,
                    );
                  },
                ),

                StreamBuilder<int>(
                  stream: _followingCountStream(),
                  initialData: widget.followingCount,
                  builder: (context, snapshot) {
                    return _buildStat(
                      value: snapshot.data ??
                          widget.followingCount,
                      label: 'Following',
                      onTap: _openFollowing,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildFollowButton(),

            const SizedBox(height: 28),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Posts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildPostsSection(),
          ],
        ),
      ),
    );
  }
}