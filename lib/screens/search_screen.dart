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
  final TextEditingController _searchController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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

    _debounce = Timer(
      const Duration(milliseconds: 400),
      () {
        _searchUsers(text);
      },
    );
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
          .where(
            'usernameLowercase',
            isGreaterThanOrEqualTo: searchText,
          )
          .where(
            'usernameLowercase',
            isLessThanOrEqualTo: '$searchText\uf8ff',
          )
          .limit(30)
          .get();

      final nameResults = await _firestore
          .collection('users')
          .where(
            'nameLowercase',
            isGreaterThanOrEqualTo: searchText,
          )
          .where(
            'nameLowercase',
            isLessThanOrEqualTo: '$searchText\uf8ff',
          )
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
          content: Text(
            'Search error: $e',
          ),
        ),
      );
    }
  }

  void _openUserProfile(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
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

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  Widget _buildAvatar(
    Map<String, dynamic> data,
  ) {
    final photoUrl =
        data['photoUrl']?.toString() ?? '';

    final name =
        data['name']?.toString() ?? '';

    final username =
        data['username']?.toString() ?? '';

    final firstLetter = name.isNotEmpty
        ? name[0].toUpperCase()
        : username.isNotEmpty
            ? username[0].toUpperCase()
            : '?';

    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 27,
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 27,
      backgroundImage: NetworkImage(photoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(
                          Icons.clear,
                        ),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchText = '';
                            _users = [];
                            _isLoading = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: _searchText.isEmpty
                ? const _SearchEmptyState()
                : _users.isEmpty && !_isLoading
                    ? const _NoSearchResults()
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 24,
                        ),
                        itemCount: _users.length,
                        separatorBuilder: (_, _) =>
                            const Divider(
                          height: 1,
                          indent: 82,
                        ),
                        itemBuilder: (context, index) {
                          final document = _users[index];
                          final data = document.data();

                          final name =
                              data['name']?.toString() ?? '';

                          final username =
                              data['username']?.toString() ?? '';

                          final bio =
                              data['bio']?.toString() ?? '';

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: _buildAvatar(data),
                            title: Text(
                              name.isNotEmpty
                                  ? name
                                  : username.isNotEmpty
                                      ? username
                                      : 'GAPSHAP User',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (username.isNotEmpty)
                                  Text('@$username'),
                                if (bio.isNotEmpty)
                                  Text(
                                    bio,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () {
                              _openUserProfile(
                                document,
                              );
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
          ),
          SizedBox(height: 12),
          Text(
            'Find people on GAPSHAP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Search by name or username.',
          ),
        ],
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 64,
          ),
          SizedBox(height: 12),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another name or username.',
          ),
        ],
      ),
    );
  }
}