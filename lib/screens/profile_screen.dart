import 'package:flutter/material.dart';

import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ---------------------------------------------------------------------------
  // PROFILE DATA
  // ---------------------------------------------------------------------------

  String _username = 'shakshi';
  String _name = 'Shakshi Meena';

  String _bio =
      'Welcome to my Gapshap profile 💜\n'
      'Connect • Share • Chat';
  final int _posts = 12;
  final int _followers = 248;
  final int _following = 186;
  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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

              const SizedBox(height: 10),

              _buildActionButtons(),

              const SizedBox(height: 18),

              _buildProfileTabs(),

              _buildPostsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 16,

      title: Row(
        children: [
          Text(
            '@$_username',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  // ---------------------------------------------------------------------------
  // PROFILE HEADER
  // ---------------------------------------------------------------------------

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // PROFILE PHOTO
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
                      child: const CircleAvatar(
                        child: Icon(Icons.person, size: 48),
                      ),
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

              // STATISTICS
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(value: _posts, label: 'Posts'),
                    _buildStat(value: _followers, label: 'Followers'),
                    _buildStat(value: _following, label: 'Following'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // NAME
          Text(
            _name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          // BIO
          Text(_bio, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STAT
  // ---------------------------------------------------------------------------

  Widget _buildStat({required int value, required String label}) {
    return GestureDetector(
      onTap: () {
        if (label == 'Followers') {
          _showComingSoon('Followers');
        } else if (label == 'Following') {
          _showComingSoon('Following');
        } else {
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

  // ---------------------------------------------------------------------------
  // ACTION BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _editProfile,
              child: const Text('Edit Profile'),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: OutlinedButton(
              onPressed: _shareProfile,
              child: const Text('Share Profile'),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE TABS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // POSTS GRID
  // ---------------------------------------------------------------------------

  Widget _buildPostsGrid() {
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

  // ---------------------------------------------------------------------------
  // EDIT PROFILE
  // ---------------------------------------------------------------------------

  void _editProfile() {
    final nameController = TextEditingController(text: _name);

    final usernameController = TextEditingController(text: _username);

    final bioController = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: bioController,
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();

                    final username = usernameController.text.trim().replaceAll(
                      ' ',
                      '',
                    );

                    final bio = bioController.text.trim();

                    if (name.isEmpty) {
                      setDialogState(() {
                        errorText = 'Name cannot be empty.';
                      });
                      return;
                    }

                    if (username.isEmpty) {
                      setDialogState(() {
                        errorText = 'Username cannot be empty.';
                      });
                      return;
                    }

                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
                      setDialogState(() {
                        errorText =
                            'Username can contain letters, numbers, . and _.';
                      });
                      return;
                    }

                    setState(() {
                      _name = name;
                      _username = username;
                      _bio = bio;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SETTINGS
  // ---------------------------------------------------------------------------

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const SettingsScreen();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARE PROFILE
  // ---------------------------------------------------------------------------

  void _shareProfile() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
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

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy Profile Link'),
                  onTap: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile link copied')),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share via other apps'),
                  onTap: () {
                    Navigator.pop(context);

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

  // ---------------------------------------------------------------------------
  // PROFILE PHOTO OPTIONS
  // ---------------------------------------------------------------------------

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
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
                  Navigator.pop(context);

                  _showComingSoon('Gallery');
                },
              ),

              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);

                  _showComingSoon('Camera');
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove Profile Photo'),
                onTap: () {
                  Navigator.pop(context);

                  _showComingSoon('Remove profile photo');
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE OPTIONS
  // ---------------------------------------------------------------------------

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
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
                  Navigator.pop(context);

                  _showComingSoon('New Post');
                },
              ),

              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('New Reel'),
                onTap: () {
                  Navigator.pop(context);

                  _showComingSoon('New Reel');
                },
              ),

              ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: const Text('New Story'),
                onTap: () {
                  Navigator.pop(context);

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

  // ---------------------------------------------------------------------------
  // OPEN POST
  // ---------------------------------------------------------------------------

  void _openPost(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Post ${index + 1}'),
          content: const Text('Full post viewer will be added here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  Future<void> _refreshProfile() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile refreshed'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMING SOON
  // ---------------------------------------------------------------------------

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
