import 'package:flutter/material.dart';

import '../models/sports_match.dart';
import '../services/sports_room_service.dart';
import 'chat_room_screen.dart';

class SportsMatchRoomScreen extends StatefulWidget {
  final SportsMatch match;

  const SportsMatchRoomScreen({super.key, required this.match});

  @override
  State<SportsMatchRoomScreen> createState() => _SportsMatchRoomScreenState();
}

class _SportsMatchRoomScreenState extends State<SportsMatchRoomScreen> {
  final SportsRoomService _roomService = SportsRoomService.instance;

  bool _preparingRoom = true;
  String? _roomId;
  String? _error;

  SportsMatch get match => widget.match;

  @override
  void initState() {
    super.initState();
    _prepareRoom();
  }

  Future<void> _prepareRoom() async {
    setState(() {
      _preparingRoom = true;
      _error = null;
    });

    try {
      final roomId = await _roomService.prepareSportRoom(match.sport);

      if (!mounted) return;

      setState(() {
        _roomId = roomId;
        _preparingRoom = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _preparingRoom = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openDiscussion() async {
    final roomId = _roomId;

    if (roomId == null || roomId.isEmpty) {
      await _prepareRoom();
      return;
    }

    if (!mounted) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatRoomScreen(roomId: roomId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        title: const Text('Match Room'),
        backgroundColor: const Color(0xFFF8F7FF),
        foregroundColor: const Color(0xFF20202A),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _prepareRoom,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _MatchHeader(match: match),
            const SizedBox(height: 16),
            _MatchStatusCard(match: match),
            const SizedBox(height: 16),
            _MatchDetailsCard(match: match),
            const SizedBox(height: 20),
            _DiscussionCard(
              preparingRoom: _preparingRoom,
              error: _error,
              onRetry: _prepareRoom,
              onOpen: _openDiscussion,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  final SportsMatch match;

  const _MatchHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9E5FF), Color(0xFFF5F2FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            match.sport.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Color(0xFF625B9B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            match.competitionName.isEmpty ? 'Match' : match.competitionName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20202A),
            ),
          ),
          if (match.round.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              match.round,
              style: const TextStyle(color: Color(0xFF555361), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchStatusCard extends StatelessWidget {
  final SportsMatch match;

  const _MatchStatusCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E4F2)),
      ),
      child: Column(
        children: [
          _StatusBadge(match: match),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TeamBlock(
                  name: match.homeTeam.name,
                  logoUrl: match.homeTeam.logoUrl,
                  score: match.homeScore,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF777381),
                  ),
                ),
              ),
              Expanded(
                child: _TeamBlock(
                  name: match.awayTeam.name,
                  logoUrl: match.awayTeam.logoUrl,
                  score: match.awayScore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            match.displayScore,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20202A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final int? score;

  const _TeamBlock({
    required this.name,
    required this.logoUrl,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TeamLogo(url: logoUrl),
        const SizedBox(height: 10),
        Text(
          name.isEmpty ? 'Team' : name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF20202A),
          ),
        ),
        const SizedBox(height: 5),
        if (score != null)
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF625B9B),
            ),
          ),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String? url;

  const _TeamLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EEFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: Color(0xFF625B9B),
          size: 28,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url!,
        width: 54,
        height: 54,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF625B9B)),
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
    final isLive = match.isLive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFFFE9E9) : const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.circle : Icons.schedule_outlined,
            size: 10,
            color: isLive ? const Color(0xFFD84A4A) : const Color(0xFF625B9B),
          ),
          const SizedBox(width: 7),
          Text(
            match.displayStatus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isLive ? const Color(0xFFD84A4A) : const Color(0xFF625B9B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchDetailsCard extends StatelessWidget {
  final SportsMatch match;

  const _MatchDetailsCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow(
        icon: Icons.calendar_today_outlined,
        title: 'Start',
        value: _formatDate(match.startTime),
      ),
    ];

    if (match.venue.isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: Icons.location_on_outlined,
          title: 'Venue',
          value: match.venue,
        ),
      );
    }

    if (match.country.isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: Icons.public_outlined,
          title: 'Country',
          value: match.country,
        ),
      );
    }

    if (match.stage.isNotEmpty) {
      rows.add(
        _InfoRow(
          icon: Icons.account_tree_outlined,
          title: 'Stage',
          value: match.stage,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20202A),
            ),
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not available';
    }

    final local = value.toLocal();

    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF625B9B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777381),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF20202A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final bool preparingRoom;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  const _DiscussionCard({
    required this.preparingRoom,
    required this.error,
    required this.onRetry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.forum_outlined, color: Color(0xFF625B9B)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Match Discussion',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20202A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Join the Krevzy room for this sport and discuss the match with other users.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF555361),
            ),
          ),
          const SizedBox(height: 16),
          if (preparingRoom)
            const SizedBox(
              height: 46,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (error != null) ...[
            Text(
              error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB33A3A)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Open Discussion Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF625B9B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
