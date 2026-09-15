import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/follow_service.dart';
import '../widgets/post_card.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState
    extends State<PublicProfileScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _name = '';
  String _username = '';
  String _bio = '';
  String _photoUrl = '';

  int _postsCount = 0;

  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) {
        return;
      }

      if (!snapshot.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.data() ?? {};

      setState(() {
        _name = data['name']?.toString() ?? '';
        _username =
            data['username']?.toString() ?? '';
        _bio = data['bio']?.toString() ?? '';
        _photoUrl =
            data['photoUrl']?.toString() ?? '';

        _postsCount =
            _toInt(data['postsCount']);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load profile: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // INTEGER CONVERTER
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // FOLLOW / UNFOLLOW
  // ============================================================

  Future<void> _toggleFollow(
    bool isFollowing,
  ) async {
    if (_isActionLoading) {
      return;
    }

    setState(() {
      _isActionLoading = true;
    });

    try {
      if (isFollowing) {
        await FollowService.unfollow(
          widget.userId,
        );
      } else {
        await FollowService.follow(
          targetUserId: widget.userId,
          targetUsername: _username,
          targetName: _name,
          targetPhotoUrl: _photoUrl,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update follow status: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PROFILE INITIALS
  // ============================================================

  String _initials() {
    final value =
        _name.isNotEmpty ? _name : _username;

    if (value.isEmpty) {
      return '?';
    }

    final parts =
        value.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}'
          '${parts[1][0]}'
          .toUpperCase();
    }

    return value[0].toUpperCase();
  }

  // ============================================================
  // USER POSTS STREAM
  // ============================================================

  Stream<List<Post>> _userPostsStream() {
    return _firestore
        .collection('posts')
        .where(
          'userId',
          isEqualTo: widget.userId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Post.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    final isOwnProfile =
        currentUser?.uid == widget.userId;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _username.isNotEmpty
              ? '@$_username'
              : 'Profile',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            // ==================================================
            // PROFILE PHOTO
            // ==================================================

            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundImage:
                    _photoUrl.isNotEmpty
                        ? NetworkImage(
                            _photoUrl,
                          )
                        : null,
                child: _photoUrl.isEmpty
                    ? Text(
                        _initials(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // NAME
            // ==================================================

            Center(
              child: Text(
                _name.isNotEmpty
                    ? _name
                    : _username,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            // ==================================================
            // USERNAME
            // ==================================================

            if (_username.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@$_username',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],

            // ==================================================
            // BIO
            // ==================================================

            if (_bio.isNotEmpty) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  _bio,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ==================================================
            // PROFILE STATS
            // ==================================================

            StreamBuilder<int>(
              stream: FollowService
                  .followersCountStream(
                widget.userId,
              ),
              builder:
                  (context, followerSnapshot) {
                final followers =
                    followerSnapshot.data ??
                        0;

                return StreamBuilder<int>(
                  stream: FollowService
                      .followingCountStream(
                    widget.userId,
                  ),
                  builder: (
                    context,
                    followingSnapshot,
                  ) {
                    final following =
                        followingSnapshot
                                .data ??
                            0;

                    return Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        _StatItem(
                          value: _postsCount,
                          label: 'Posts',
                        ),
                        const SizedBox(
                          width: 35,
                        ),
                        _StatItem(
                          value: followers,
                          label: 'Followers',
                        ),
                        const SizedBox(
                          width: 35,
                        ),
                        _StatItem(
                          value: following,
                          label: 'Following',
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 25),

            // ==================================================
            // FOLLOW BUTTON
            // ==================================================

            if (!isOwnProfile)
              StreamBuilder<bool>(
                stream: FollowService
                    .followingStream(
                  widget.userId,
                ),
                builder:
                    (context, snapshot) {
                  final isFollowing =
                      snapshot.data ?? false;

                  return SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed:
                          _isActionLoading
                              ? null
                              : () =>
                                  _toggleFollow(
                                    isFollowing,
                                  ),
                      child:
                          _isActionLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                  ),
                                )
                              : Text(
                                  isFollowing
                                      ? 'Following'
                                      : 'Follow',
                                ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            // ==================================================
            // POSTS TITLE
            // ==================================================

            const Text(
              'Posts',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // USER POSTS
            // ==================================================

            StreamBuilder<List<Post>>(
              stream: _userPostsStream(),
              builder:
                  (context, snapshot) {
                // --------------------------------------------
                // ERROR
                // --------------------------------------------

                if (snapshot.hasError) {
                  return const Padding(
                    padding:
                        EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Unable to load posts.',
                      ),
                    ),
                  );
                }

                // --------------------------------------------
                // LOADING
                // --------------------------------------------

                if (snapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding:
                        EdgeInsets.all(30),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                final posts =
                    snapshot.data ?? [];

                // --------------------------------------------
                // NO POSTS
                // --------------------------------------------

                if (posts.isEmpty) {
                  return Container(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color:
                            Colors.grey.shade300,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'No posts yet.',
                      ),
                    ),
                  );
                }

                // --------------------------------------------
                // REUSABLE POST CARD
                // --------------------------------------------

                return Column(
                  children: posts.map(
                    (post) {
                      return PostCard(
                        key: ValueKey(post.id),
                        post: post,
                      );
                    },
                  ).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAT ITEM
// ============================================================

class _StatItem
    extends StatelessWidget {
  final int value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}