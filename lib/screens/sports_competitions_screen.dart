import 'package:flutter/material.dart';

import '../models/sports_competition.dart';
import '../services/sports_service.dart';
import 'sports_matches_screen.dart';

class SportsCompetitionsScreen extends StatefulWidget {
  final String? sport;

  const SportsCompetitionsScreen({
    super.key,
    this.sport,
  });

  @override
  State<SportsCompetitionsScreen> createState() =>
      _SportsCompetitionsScreenState();
}

class _SportsCompetitionsScreenState
    extends State<SportsCompetitionsScreen> {
  bool _loading = true;
  String? _error;

  List<SportsCompetition> _competitions =
      const <SportsCompetition>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await SportsService.instance.getCompetitions(
        sport: widget.sport,
      );

      if (!mounted) return;

      setState(() {
        _competitions = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Competitions'),
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Unable to load competitions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777381),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_competitions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.emoji_events_outlined,
              size: 52,
              color: Color(0xFF625B9B),
            ),
            SizedBox(height: 14),
            Center(
              child: Text(
                'No competitions available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _competitions.length,
        itemBuilder: (context, index) {
          final competition = _competitions[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CompetitionCard(
              competition: competition,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SportsMatchesScreen(
                      sport: competition.sport,
                      competitionId: competition.id,
                      competitionName:
                          competition.name,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final SportsCompetition competition;
  final VoidCallback onTap;

  const _CompetitionCard({
    required this.competition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              _Logo(
                url: competition.logoUrl,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20202A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (competition.sport.isNotEmpty)
                          _displaySport(
                            competition.sport,
                          ),
                        if (competition.country.isNotEmpty)
                          competition.country,
                        if (competition.season.isNotEmpty)
                          competition.season,
                      ].join(' • '),
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF777381),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFAAA6B5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _displaySport(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1)}',
        )
        .join(' ');
  }
}

class _Logo extends StatelessWidget {
  final String? url;

  const _Logo({
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.emoji_events_outlined,
          color: Color(0xFF625B9B),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url!,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF625B9B),
            ),
          );
        },
      ),
    );
  }
}