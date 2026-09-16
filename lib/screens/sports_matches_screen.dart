import 'package:flutter/material.dart';

import '../models/sports_match.dart';
// import '../services/sports_service.dart';
import '../services/sports_sync_service.dart';
import 'sports_match_room_screen.dart';

enum _MatchTab { upcoming, results }

class SportsMatchesScreen extends StatefulWidget {
  final String? sport;
  final String? competitionId;
  final String? competitionName;

  const SportsMatchesScreen({
    super.key,
    this.sport,
    this.competitionId,
    this.competitionName,
  });

  @override
  State<SportsMatchesScreen> createState() => _SportsMatchesScreenState();
}

class _SportsMatchesScreenState extends State<SportsMatchesScreen> {
  _MatchTab _tab = _MatchTab.upcoming;
  String? _selectedSport;

  bool _loading = true;
  bool _syncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.sport;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();

      if (_tab == _MatchTab.upcoming) {
        await SportsSyncService.instance.syncUpcomingMatches(
          sport: _selectedSport,
          from: now,
          to: now.add(const Duration(days: 30)),
        );
      } else {
        await SportsSyncService.instance.syncResults(
          sport: _selectedSport,
          from: now.subtract(const Duration(days: 30)),
          to: now,
        );
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    if (_syncing) return;

    setState(() {
      _syncing = true;
      _error = null;
    });

    try {
      final now = DateTime.now();

      if (_tab == _MatchTab.upcoming) {
        await SportsSyncService.instance.syncUpcomingMatches(
          sport: _selectedSport,
          from: now,
          to: now.add(const Duration(days: 30)),
        );
      } else {
        await SportsSyncService.instance.syncResults(
          sport: _selectedSport,
          from: now.subtract(const Duration(days: 30)),
          to: now,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
      }
    }
  }

  void _changeTab(_MatchTab tab) {
    if (_tab == tab) return;

    setState(() {
      _tab = tab;
    });

    _load();
  }

  void _changeSport(String? sport) {
    setState(() {
      _selectedSport = sport;
    });

    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: Text(
          widget.competitionName?.isNotEmpty == true
              ? widget.competitionName!
              : 'Matches',
        ),
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _syncing ? null : _refresh,
            icon: _syncing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          _buildSportSelector(),
          Expanded(child: _buildMatchList()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              selected: _tab == _MatchTab.upcoming,
              icon: Icons.event_outlined,
              title: 'Upcoming',
              onTap: () => _changeTab(_MatchTab.upcoming),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TabButton(
              selected: _tab == _MatchTab.results,
              icon: Icons.check_circle_outline,
              title: 'Results',
              onTap: () => _changeTab(_MatchTab.results),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportSelector() {
    const sports = <String>[
      'football',
      'cricket',
      'basketball',
      'tennis',
      'hockey',
      'baseball',
      'volleyball',
      'rugby',
      'kabaddi',
      'handball',
      'badminton',
      'table_tennis',
      'golf',
      'boxing',
      'wrestling',
      'athletics',
      'motorsport',
      'cycling',
      'swimming',
      'esports',
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _SportChip(
            label: 'All',
            selected: _selectedSport == null,
            onTap: () => _changeSport(null),
          ),
          ...sports.map(
            (sport) => _SportChip(
              label: _displaySport(sport),
              selected: _selectedSport == sport,
              onTap: () => _changeSport(sport),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList() {
    if (_selectedSport == null) {
      return _buildAllSportsStream();
    }

    return StreamBuilder<List<SportsMatch>>(
      stream: _tab == _MatchTab.upcoming
          ? SportsSyncService.instance.watchMatches(sport: _selectedSport)
          : SportsSyncService.instance.watchMatches(sport: _selectedSport),
      builder: (context, snapshot) {
        return _buildSnapshotContent(snapshot);
      },
    );
  }

  Widget _buildAllSportsStream() {
    return StreamBuilder<List<SportsMatch>>(
      stream: SportsSyncService.instance.watchMatches(),
      builder: (context, snapshot) {
        return _buildSnapshotContent(snapshot);
      },
    );
  }

  Widget _buildSnapshotContent(AsyncSnapshot<List<SportsMatch>> snapshot) {
    if (_loading && !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _ErrorState(message: snapshot.error.toString(), onRetry: _load);
    }

    if (_error != null && !snapshot.hasData) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    final allMatches = snapshot.data ?? const <SportsMatch>[];

    final matches = allMatches.where((match) {
      if (widget.competitionId != null &&
          widget.competitionId!.isNotEmpty &&
          match.competitionId != widget.competitionId) {
        return false;
      }

      if (_selectedSport != null &&
          match.sport.toLowerCase() != _selectedSport!.toLowerCase()) {
        return false;
      }

      if (_tab == _MatchTab.upcoming) {
        return !match.isFinished &&
            match.status != SportsMatchStatus.cancelled &&
            match.status != SportsMatchStatus.abandoned;
      }

      return match.isFinished;
    }).toList();

    matches.sort((a, b) {
      final aTime = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);

      if (_tab == _MatchTab.upcoming) {
        return aTime.compareTo(bTime);
      }

      return bTime.compareTo(aTime);
    });

    if (matches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Icon(
              _tab == _MatchTab.upcoming
                  ? Icons.event_busy_outlined
                  : Icons.sports_score_outlined,
              size: 52,
              color: const Color(0xFF625B9B),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _tab == _MatchTab.upcoming
                    ? 'No upcoming matches'
                    : 'No results available',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF20202A),
                ),
              ),
            ),
            const SizedBox(height: 7),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  'Pull down to refresh the latest available sports data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF777381)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MatchCard(
              match: match,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SportsMatchRoomScreen(match: match),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static String _displaySport(String sport) {
    return sport
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _TabButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _TabButton({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF625B9B) : Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? const Color(0xFF625B9B)
                  : const Color(0xFFE7E4F2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : const Color(0xFF625B9B),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : const Color(0xFF20202A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SportChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF555361),
        ),
        selectedColor: const Color(0xFF625B9B),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE7E4F2)),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final SportsMatch match;
  final VoidCallback onTap;

  const _MatchCard({required this.match, required this.onTap});

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
            border: Border.all(color: const Color(0xFFE7E4F2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.competitionName.isEmpty
                          ? _displaySport(match.sport)
                          : match.competitionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF625B9B),
                      ),
                    ),
                  ),
                  _StatusBadge(match: match),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Team(
                      name: match.homeTeam.name,
                      logoUrl: match.homeTeam.logoUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Text(
                        match.displayScore,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20202A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (match.startTime != null)
                        Text(
                          _formatTime(match.startTime!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF777381),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Team(
                      name: match.awayTeam.name,
                      logoUrl: match.awayTeam.logoUrl,
                      rightAligned: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.country,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777381),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 19,
                    color: Color(0xFFAAA6B5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime value) {
    final local = value.toLocal();

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  static String _displaySport(String sport) {
    return sport
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _Team extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final bool rightAligned;

  const _Team({
    required this.name,
    required this.logoUrl,
    this.rightAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: rightAligned
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!rightAligned) ...[_Logo(url: logoUrl), const SizedBox(width: 9)],
        Flexible(
          child: Text(
            name.isEmpty ? 'Team' : name,
            textAlign: rightAligned ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20202A),
            ),
          ),
        ),
        if (rightAligned) ...[const SizedBox(width: 9), _Logo(url: logoUrl)],
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;

  const _Logo({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.shield_outlined,
          size: 18,
          color: Color(0xFF625B9B),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: 34,
        height: 34,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: Color(0xFF625B9B),
            ),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SportsMatch match;

  const _StatusBadge({required this.match});

  @override
  Widget build(BuildContext context) {
    final live = match.isLive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFFFE8E8) : const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        match.displayStatus,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: live ? const Color(0xFFD84A4A) : const Color(0xFF625B9B),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFF625B9B),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load matches',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20202A),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF777381)),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
