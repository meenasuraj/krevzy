import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/follow_service.dart';
import '../services/user_migration_service.dart';
import 'settings_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSyncingSearchProfile = false;

  String _username = '';
  String _name = '';
  String _bio = '';
  String _photoUrl = '';

  int _posts = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final document = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) {
        return;
      }

      if (document.exists) {
        final data = document.data() ?? {};

        setState(() {
          _name = (data['name'] ?? user.displayName ?? '').toString();

          _username = (data['username'] ?? '').toString();

          _bio = (data['bio'] ?? '').toString();

          _photoUrl = (data['photoUrl'] ?? '').toString();

          _posts = _readInt(data['postsCount']);

          _isLoading = false;
        });
      } else {
        setState(() {
          _name = user.displayName ?? '';

          _username = '';
          _bio = '';
          _photoUrl = '';
          _posts = 0;
          _isLoading = false;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint('Profile Firestore Error: ${e.code}');

      debugPrint('Profile Firestore Message: ${e.message}');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load profile.\n'
            'Firestore: ${e.code}',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Profile Load Error: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to load profile.')));
    }
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // SEARCH PROFILE SYNC
  // ============================================================

  Future<void> _syncSearchProfile() async {
    if (_isSyncingSearchProfile) {
      return;
    }

    setState(() {
      _isSyncingSearchProfile = true;
    });

    try {
      await UserMigrationService.migrateCurrentUser();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search profile synced successfully.')),
      );
    } catch (e) {
      debugPrint('Search Profile Sync Error: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search profile sync failed.\n$e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncingSearchProfile = false;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 16),

              _buildActionButtons(),

              const SizedBox(height: 12),

              _buildSearchSyncButton(),

              const SizedBox(height: 18),

              _buildProfileTabs(),

              _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    final username = _username.isEmpty ? 'profile' : _username;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Flexible(
            child: Text(
              '@$username',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.keyboard_arrow_down, size: 20),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Create',
          onPressed: _showCreateOptions,
          icon: const Icon(Icons.add_box_outlined),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _openSettings,
          icon: const Icon(Icons.menu),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _showProfilePhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: _buildProfileAvatar(size: 84),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          border: Border.all(
                            width: 3,
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(value: _posts, label: 'Posts'),

                    StreamBuilder<int>(
                      stream: FollowService.followersCountStream(user.uid),
                      builder: (context, snapshot) {
                        return _buildStat(
                          value: snapshot.data ?? 0,
                          label: 'Followers',
                          onTap: _openFollowers,
                        );
                      },
                    ),

                    StreamBuilder<int>(
                      stream: FollowService.followingCountStream(user.uid),
                      builder: (context, snapshot) {
                        return _buildStat(
                          value: snapshot.data ?? 0,
                          label: 'Following',
                          onTap: _openFollowing,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _name.isEmpty ? 'Gapshap User' : _name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          if (_username.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              '@$_username',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (_bio.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(_bio, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget _buildProfileAvatar({required double size}) {
    if (_photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: size / 2,
              child: Icon(Icons.person, size: size * 0.55),
            );
          },
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      child: Icon(Icons.person, size: size * 0.55),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStat({
    required int value,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            if (label == 'Posts') {
              _showComingSoon('Posts');
            }
          },
      child: Column(
        children: [
          Text(
            _formatNumber(value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }

    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }

    return number.toString();
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareProfile,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share Profile'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH SYNC
  // ============================================================

  Widget _buildSearchSyncButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isSyncingSearchProfile ? null : _syncSearchProfile,
          icon: _isSyncingSearchProfile
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(
            _isSyncingSearchProfile
                ? 'Syncing Search Profile...'
                : 'Sync Search Profile',
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE TABS
  // ============================================================

  Widget _buildProfileTabs() {
    return const SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: _ProfileTabButton(icon: Icons.grid_on, isSelected: true),
          ),
          Expanded(
            child: _ProfileTabButton(
              icon: Icons.video_collection_outlined,
              isSelected: false,
            ),
          ),
          Expanded(
            child: _ProfileTabButton(
              icon: Icons.bookmark_border,
              isSelected: false,
            ),
          ),
          Expanded(
            child: _ProfileTabButton(
              icon: Icons.person_pin_outlined,
              isSelected: false,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POSTS GRID
  // ============================================================

  Widget _buildPostsGrid() {
    if (_posts == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.grid_on,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              const Text(
                'No posts yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Your posts will appear here.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _posts,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        return _PostGridItem(
          index: index,
          onTap: () {
            _openPost(index);
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _editProfile() {
    final nameController = TextEditingController(text: _name);

    final usernameController = TextEditingController(text: _username);

    final bioController = TextEditingController(text: _bio);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (saving) {
                return;
              }

              final user = _auth.currentUser;

              if (user == null) {
                setDialogState(() {
                  errorText = 'You are not logged in.';
                });
                return;
              }

              final name = nameController.text.trim();

              final username = usernameController.text
                  .trim()
                  .toLowerCase()
                  .replaceAll(' ', '');

              final bio = bioController.text.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  errorText = 'Name cannot be empty.';
                });
                return;
              }

              if (username.length < 3) {
                setDialogState(() {
                  errorText = 'Username must be at least 3 characters.';
                });
                return;
              }

              if (!RegExp(r'^[a-z0-9._]+$').hasMatch(username)) {
                setDialogState(() {
                  errorText = 'Username can contain letters, numbers, . and _.';
                });
                return;
              }

              if (bio.length > 150) {
                setDialogState(() {
                  errorText = 'Bio cannot be longer than 150 characters.';
                });
                return;
              }

              setDialogState(() {
                saving = true;
                errorText = null;
              });

              try {
                // ================================================
                // USERNAME CHECK
                // ================================================

                if (username != _username) {
                  final usernameQuery = await _firestore
                      .collection('users')
                      .where('usernameLowercase', isEqualTo: username)
                      .limit(1)
                      .get();

                  final taken = usernameQuery.docs.any(
                    (doc) => doc.id != user.uid,
                  );

                  if (taken) {
                    setDialogState(() {
                      saving = false;
                      errorText = 'This username is already taken.';
                    });
                    return;
                  }
                }

                // ================================================
                // SAVE FIRESTORE PROFILE
                // ================================================

                await _firestore.collection('users').doc(user.uid).set({
                  'uid': user.uid,
                  'name': name,
                  'nameLowercase': name.toLowerCase(),
                  'username': username,
                  'usernameLowercase': username,
                  'email': user.email ?? '',
                  'bio': bio,
                  'photoUrl': _photoUrl,
                  'postsCount': _posts,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // ================================================
                // UPDATE FIREBASE AUTH DISPLAY NAME
                // ================================================

                await user.updateDisplayName(name);

                if (!mounted) {
                  return;
                }

                setState(() {
                  _name = name;
                  _username = username;
                  _bio = bio;
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (!dialogContext.mounted) {
                  return;
                }

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully.'),
                  ),
                );
              } on FirebaseException catch (e) {
                debugPrint('Edit Profile Firebase Error: ${e.code}');

                debugPrint('Edit Profile Firebase Message: ${e.message}');

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  saving = false;
                  errorText = 'Unable to save profile: ${e.code}';
                });
              } catch (e) {
                debugPrint('Edit Profile Error: $e');

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  saving = false;
                  errorText = 'Something went wrong. Please try again.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: bioController,
                      enabled: !saving,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      usernameController.dispose();
      bioController.dispose();
    });
  }

  // ============================================================
  // FOLLOWERS
  // ============================================================

  void _openFollowers() {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FollowersScreen(userId: user.uid)),
    );
  }

  // ============================================================
  // FOLLOWING
  // ============================================================

  void _openFollowing() {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FollowingScreen(userId: user.uid)),
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  // ============================================================
  // SHARE PROFILE
  // ============================================================

  void _shareProfile() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final username = _username.isEmpty ? 'profile' : _username;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  '@$username',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy Profile Link'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile link copied.')),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share via other apps'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showComingSoon('External sharing');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE PHOTO OPTIONS
  // ============================================================

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Profile Photo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showComingSoon('Gallery');
                },
              ),

              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showComingSoon('Camera');
                },
              ),

              if (_photoUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove Profile Photo'),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    await _removeProfilePhoto();
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // REMOVE PROFILE PHOTO
  // ============================================================

  Future<void> _removeProfilePhoto() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _photoUrl = '';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
    } catch (e) {
      debugPrint('Remove Profile Photo Error: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove profile photo.')),
      );
    }
  }

  // ============================================================
  // CREATE OPTIONS
  // ============================================================

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Create',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('New Post'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showComingSoon('New Post');
                },
              ),

              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('New Reel'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showComingSoon('New Reel');
                },
              ),

              ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: const Text('New Story'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showComingSoon('New Story');
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // OPEN POST
  // ============================================================

  void _openPost(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Post ${index + 1}'),
          content: const Text('Full post viewer will be added here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshProfile() async {
    await _loadProfile();
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }
}

// ============================================================================
// PROFILE TAB BUTTON
// ============================================================================

class _ProfileTabButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _ProfileTabButton({required this.icon, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: isSelected ? 2 : 1,
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ============================================================================
// POST GRID ITEM
// ============================================================================

class _PostGridItem extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _PostGridItem({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.grey.shade200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(child: Icon(Icons.image_outlined, size: 42)),
            Positioned(
              right: 6,
              top: 6,
              child: Icon(
                index % 3 == 0
                    ? Icons.collections_outlined
                    : Icons.image_outlined,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
