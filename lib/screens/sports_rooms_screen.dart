import 'package:flutter/material.dart';

import '../data/sports_room_catalog.dart';
import '../services/sports_room_service.dart';
import 'chat_room_screen.dart';
import 'sports_live_screen.dart';

class SportsRoomsScreen extends StatefulWidget {
  const SportsRoomsScreen({
    super.key,
  });

  @override
  State<SportsRoomsScreen> createState() => _SportsRoomsScreenState();
}

class _SportsRoomsScreenState extends State<SportsRoomsScreen> {
  final SportsRoomService _roomService = SportsRoomService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _isPreparing = false;

  List<SportsRoomDefinition> get _filteredSports {
    return _roomService.searchSports(_query);
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _query = _searchController.text;
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSport(
    SportsRoomDefinition sport,
  ) async {
    if (_isPreparing) {
      return;
    }

    setState(() {
      _isPreparing = true;
    });

    try {
      final roomId = await _roomService.prepareSportRoom(
        sport.name,
      );

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
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
            'Unable to open ${sport.name}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  Future<void> _prepareAllRooms() async {
    if (_isPreparing) {
      return;
    }

    setState(() {
      _isPreparing = true;
    });

    try {
      await _roomService.prepareAllSportsRooms();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sports rooms are ready.',
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
            'Could not prepare sports rooms: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreparing = false;
        });
      }
    }
  }

  void _openLiveScores() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SportsLiveScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sports = _filteredSports;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        title: const Text(
          'Sports',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Live Scores',
            onPressed: _openLiveScores,
            icon: const Icon(
              Icons.sports_score_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearch(),
            Expanded(
              child: sports.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _prepareAllRooms,
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          24,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.18,
                        ),
                        itemCount: sports.length,
                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final sport = sports[index];

                          return _SportCard(
                            sport: sport,
                            onTap: () => _openSport(sport),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEAE7FF),
              Color(0xFFF3F1FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.75,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🏆',
                style: TextStyle(
                  fontSize: 27,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sports Rooms',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF20202A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Join discussions, follow matches and connect with fans.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF555361),
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

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search sports',
          prefixIcon: const Icon(
            Icons.search_rounded,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.clear_rounded,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF625B9B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔎',
              style: TextStyle(
                fontSize: 42,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No sports found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching for another sport.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF555361),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
              },
              child: const Text(
                'Clear Search',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  final SportsRoomDefinition sport;
  final VoidCallback onTap;

  const _SportCard({
    required this.sport,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8E6F2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      sport.emoji,
                      style: const TextStyle(
                        fontSize: 25,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: Color(0xFF8A8795),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                sport.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20202A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Join Room',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF625B9B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}