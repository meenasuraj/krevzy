import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Timer? _debounce;

  bool _isLoading = false;
  String _searchText = '';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final text = value.trim();

    setState(() {
      _searchText = text;
    });

    if (text.isEmpty) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(text);
    });
  }

  Future<void> _searchUsers(String text) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final searchText = text.toLowerCase();

      final usernameResults = await _firestore
          .collection('users')
          .where('usernameLowercase', isGreaterThanOrEqualTo: searchText)
          .where('usernameLowercase', isLessThanOrEqualTo: '$searchText\uf8ff')
          .limit(30)
          .get();

      final nameResults = await _firestore
          .collection('users')
          .where('nameLowercase', isGreaterThanOrEqualTo: searchText)
          .where('nameLowercase', isLessThanOrEqualTo: '$searchText\uf8ff')
          .limit(30)
          .get();

      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
      uniqueUsers = {};

      for (final document in usernameResults.docs) {
        if (document.id != currentUser.uid) {
          uniqueUsers[document.id] = document;
        }
      }

      for (final document in nameResults.docs) {
        if (document.id != currentUser.uid) {
          uniqueUsers[document.id] = document;
        }
      }

      if (!mounted) return;

      setState(() {
        _users = uniqueUsers.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _users = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text('Search error: $e'),
        ),
      );
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();

    setState(() {
      _searchText = '';
      _users = [];
      _isLoading = false;
    });
  }

  void _openUserProfile(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: document.id,
          name: data['name']?.toString() ?? '',
          username: data['username']?.toString() ?? '',
          bio: data['bio']?.toString() ?? '',
          photoUrl: data['photoUrl']?.toString() ?? '',
          postsCount: _readInt(data['postsCount']),
          followersCount: _readInt(data['followersCount']),
          followingCount: _readInt(data['followingCount']),
        ),
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final photoUrl = data['photoUrl']?.toString() ?? '';

    final name = data['name']?.toString() ?? '';

    final username = data['username']?.toString() ?? '';

    final firstLetter = name.isNotEmpty
        ? name[0].toUpperCase()
        : username.isNotEmpty
        ? username[0].toUpperCase()
        : '?';

    if (photoUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            firstLetter,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: colorScheme.surface,
        backgroundImage: NetworkImage(photoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_search_rounded,
                color: colorScheme.onPrimary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Text(
              'Discover People',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _SearchHeader(
            controller: _searchController,
            searchText: _searchText,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(minHeight: 3),
              ),
            ),
          Expanded(
            child: _searchText.isEmpty
                ? const _SearchEmptyState()
                : _users.isEmpty && !_isLoading
                ? const _NoSearchResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final document = _users[index];
                      final data = document.data();

                      return _UserResultCard(
                        data: data,
                        avatar: _buildAvatar(context, data),
                        onTap: () {
                          _openUserProfile(document);
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

// ============================================================
// SEARCH HEADER
// ============================================================

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find your people',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Search by name or username and connect.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.none,
            decoration: InputDecoration(
              hintText: 'Search people...',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 21,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 52,
              ),
              suffixIcon: searchText.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// USER RESULT CARD
// ============================================================

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({
    required this.data,
    required this.avatar,
    required this.onTap,
  });

  final Map<String, dynamic> data;
  final Widget avatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = data['name']?.toString() ?? '';

    final username = data['username']?.toString() ?? '';

    final bio = data['bio']?.toString() ?? '';

    final displayName = name.isNotEmpty
        ? name
        : username.isNotEmpty
        ? username
        : 'krevzy User';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY SEARCH STATE
// ============================================================

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Find people on KREVZY',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for friends, creators and people\n'
              'you want to connect with.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NO RESULTS
// ============================================================

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 42,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No users found',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Try another name or username.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
