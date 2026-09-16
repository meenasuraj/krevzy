import 'package:flutter/material.dart';

import '../models/sports_match.dart';
import '../services/sports_sync_service.dart';
import 'sports_match_room_screen.dart';

class SportsLiveScreen extends StatefulWidget {
  const SportsLiveScreen({super.key});

  @override
  State<SportsLiveScreen> createState() => _SportsLiveScreenState();
}

class _SportsLiveScreenState extends State<SportsLiveScreen> {
  final SportsSyncService _syncService = SportsSyncService.instance;

  String? _selectedSport;
  bool _syncing = false;

  static const List<String> _sports = [
    'All',
    'Cricket',
    'Football',
    'Hockey',
    'Basketball',
    'Tennis',
    'Baseball',
    'Volleyball',
    'Rugby',
    'Kabaddi',
    'Handball',
    'Badminton',
    'Table Tennis',
    'Golf',
    'Boxing',
    'Wrestling',
    'Athletics',
    'Motorsport',
    'Cycling',
    'Swimming',
    'Esports',
  ];

  String? get _sportFilter {
    if (_selectedSport == null || _selectedSport == 'All') {
      return null;
    }

    return _selectedSport;
  }

  Future<void> _syncLiveScores() async {
    if (_syncing) {
      return;
    }

    setState(() {
      _syncing = true;
    });

    try {
      await _syncService.syncLiveMatches();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Live scores updated.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update live scores: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  void _openMatch(SportsMatch match) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SportsMatchRoomScreen(match: match)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        title: const Row(
          children: [
            Icon(Icons.circle, size: 10, color: Color(0xFF625B9B)),
            SizedBox(width: 8),
            Text('Live Scores', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _syncing ? null : _syncLiveScores,
            icon: _syncing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBanner(),
            _buildSportFilter(),
            Expanded(
              child: StreamBuilder<List<SportsMatch>>(
                stream: _syncService.watchLiveMatches(sport: _sportFilter),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }

                  final matches = snapshot.data ?? const <SportsMatch>[];

                  if (matches.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _syncLiveScores,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LiveMatchCard(
                            match: match,
                            onTap: () => _openMatch(match),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEAE7FF), Color(0xFFF4F2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.sports_score_rounded,
                color: Color(0xFF625B9B),
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live right now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF20202A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Follow live matches and join the conversation.',
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

  Widget _buildSportFilter() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: _sports.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final sport = _sports[index];

          final selected =
              (_selectedSport == null && sport == 'All') ||
              _selectedSport == sport;

          return ChoiceChip(
            label: Text(sport),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedSport = sport == 'All' ? null : sport;
              });
            },
            selectedColor: const Color(0xFFDCD8FF),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF34313F),
            ),
            side: const BorderSide(color: Color(0xFFE5E2EF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Center(child: Text('🏟️', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'No live matches',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20202A),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'There are no live matches in the selected sport right now, or your sports provider has not supplied live data yet.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4, color: Color(0xFF555361)),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: _syncing ? null : _syncLiveScores,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Update Scores'),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF625B9B),
            ),
            const SizedBox(height: 14),
            const Text(
              'Live scores unavailable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF555361)),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: _syncLiveScores,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMatchCard extends StatelessWidget {
  final SportsMatch match;
  final VoidCallback onTap;

  const _LiveMatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6E3F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.competitionName.isEmpty
                          ? match.sport
                          : match.competitionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF777482),
                      ),
                    ),
                  ),
                  _StatusBadge(status: match.displayStatus),
                ],
              ),
              const SizedBox(height: 14),
              _TeamScoreRow(team: match.homeTeam, score: match.homeScore),
              const SizedBox(height: 10),
              _TeamScoreRow(team: match.awayTeam, score: match.awayScore),
              const SizedBox(height: 14),
              Row(
                children: [
                  if ((match.minute ?? 0) > 0)
                    Text(
                      '${match.minute}\'',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF625B9B),
                      ),
                    ),
                  const Spacer(),
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: Color(0xFF777482),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Join Room',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF625B9B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreRow extends StatelessWidget {
  final dynamic team;
  final int score;

  const _TeamScoreRow({required this.team, required this.score});

  @override
  Widget build(BuildContext context) {
    final name = team.name.toString();

    return Row(
      children: [
        _TeamLogo(url: team.logoUrl?.toString()),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name.isEmpty ? 'Unknown Team' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20202A),
            ),
          ),
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20202A),
          ),
        ),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String? url;

  const _TeamLogo({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.shield_outlined,
          size: 20,
          color: Color(0xFF625B9B),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        width: 38,
        height: 38,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shield_outlined,
              size: 20,
              color: Color(0xFF625B9B),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.isEmpty ? 'LIVE' : status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF625B9B),
        ),
      ),
    );
  }
}
