import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/chat_room_service.dart';
import 'chat_room_screen.dart';
import 'create_chat_room_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  static const List<String> categories = <String>[
    'All',
    'Study',
    'Gaming',
    'Business',
    'Share Market',
    'History',
    'Geography',
    'Cricket',
    'Hockey',
    'Football',
  ];

  final ChatRoomService _service = ChatRoomService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();

    if (value == _searchQuery) {
      return;
    }

    setState(() {
      _searchQuery = value;
    });
  }

  IconData _icon(String category) {
    switch (category) {
      case 'Study':
        return Icons.school_rounded;
      case 'Gaming':
        return Icons.sports_esports_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Share Market':
        return Icons.show_chart_rounded;
      case 'History':
        return Icons.history_edu_rounded;
      case 'Geography':
        return Icons.public_rounded;
      case 'Cricket':
        return Icons.sports_cricket_rounded;
      case 'Hockey':
        return Icons.sports_hockey_rounded;
      case 'Football':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.groups_rounded;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterRooms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
  ) {
    return rooms.where((document) {
      final data = document.data();

      final name = (data['name'] ?? '').toString().toLowerCase();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? 'Other').toString();

      final matchesCategory =
          _selectedCategory == 'All' || category == _selectedCategory;

      if (!matchesCategory) {
        return false;
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      return name.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _openCreateRoom() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateChatRoomScreen()),
    );
  }

  void _openRoom(String roomId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: roomId)),
    );
  }

  Future<void> _refresh() async {
    // Firestore snapshots are realtime, so there is no network reload
    // operation required here. Waiting briefly gives RefreshIndicator
    // a natural completion animation.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        titleSpacing: 20,
        title: const Text(
          'KREVZY Rooms',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        actions: [
          IconButton(
            tooltip: 'Create room',
            onPressed: _openCreateRoom,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRoom,
        backgroundColor: const Color(0xFF625B9B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Room',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchPublicRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error,
              onRetry: () {
                setState(() {});
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          final allRooms =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          final rooms = _filterRooms(allRooms);

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF625B9B),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderSection(totalRooms: allRooms.length),
                ),
                SliverToBoxAdapter(
                  child: _SearchBox(controller: _searchController),
                ),
                SliverToBoxAdapter(
                  child: _CategorySelector(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onSelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                ),
                if (rooms.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyRoomsState(
                      hasFilter:
                          _searchQuery.isNotEmpty || _selectedCategory != 'All',
                      onClearFilters: () {
                        _searchController.clear();
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                      onCreateRoom: _openCreateRoom,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                    sliver: SliverList.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final document = rooms[index];
                        return _RoomCard(
                          document: document,
                          icon: _icon(
                            (document.data()['category'] ?? 'Other').toString(),
                          ),
                          onTap: () => _openRoom(document.id),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final int totalRooms;

  const _HeaderSection({required this.totalRooms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDEBFF), Color(0xFFF7F5FF)],
          ),
          border: Border.all(color: const Color(0xFFE2DFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF625B9B),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find your community',
                    style: TextStyle(
                      color: Color(0xFF20202A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    totalRooms == 0
                        ? 'Create the first KREVZY Room.'
                        : '$totalRooms public ${totalRooms == 1 ? 'room' : 'rooms'} available',
                    style: const TextStyle(
                      color: Color(0xFF555361),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search rooms...',
          hintStyle: const TextStyle(color: Color(0xFF8A8795)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF625B9B),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Clear search',
                onPressed: controller.clear,
                icon: const Icon(Icons.close_rounded),
              );
            },
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4E2ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4E2ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF625B9B), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            selectedColor: const Color(0xFF625B9B),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? const Color(0xFF625B9B)
                  : const Color(0xFFE3E1EC),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF555361),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final IconData icon;
  final VoidCallback onTap;

  const _RoomCard({
    required this.document,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = document.data();

    final name = (data['name'] ?? 'KREVZY Room').toString().trim();
    final description = (data['description'] ?? '').toString().trim();
    final category = (data['category'] ?? 'Other').toString();
    final memberCount = _memberCount(data['memberCount']);

    final allowChallenges = data['allowMemberChallenges'] == true;
    final allowRules = data['allowMemberRules'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE9E7F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: const Color(0xFF625B9B), size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF20202A),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF8A8795),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFF625B9B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF666370),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                          icon: Icons.people_alt_outlined,
                          text:
                              '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                        ),
                        if (allowChallenges)
                          const _InfoPill(
                            icon: Icons.emoji_events_outlined,
                            text: 'Challenges',
                          ),
                        if (allowRules)
                          const _InfoPill(
                            icon: Icons.rule_rounded,
                            text: 'Community rules',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _memberCount(dynamic value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final count = value.toInt();
      return count < 0 ? 0 : count;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF625B9B)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF555361),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF625B9B)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF625B9B),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load rooms',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20202A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Something went wrong.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666370)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF625B9B),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRoomsState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateRoom;

  const _EmptyRoomsState({
    required this.hasFilter,
    required this.onClearFilters,
    required this.onCreateRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEBFF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: Color(0xFF625B9B),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilter ? 'No matching rooms' : 'No public rooms yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF20202A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter ? 'Try another search or category.' : 'Create a room and start building your community on KREVZY.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF666370),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear filters'),
              )
            else
              FilledButton.icon(
                onPressed: onCreateRoom,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF625B9B),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create first room'),
              ),
          ],
        ),
      ),
    );
  }
}
