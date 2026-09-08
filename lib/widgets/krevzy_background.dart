import 'package:flutter/material.dart';

class KrevzyBackground extends StatelessWidget {
  final Widget child;
  final String? photoUrl;
  final double overlayOpacity;

  const KrevzyBackground({
    super.key,
    required this.child,
    this.photoUrl,
    this.overlayOpacity = .05,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photoUrl != null && photoUrl!.isNotEmpty)
          Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _PosterGradient(),
          )
        else
          const _PosterGradient(),
        if (overlayOpacity > 0)
          Container(color: Colors.white.withValues(alpha: overlayOpacity)),
        child,
      ],
    );
  }
}

/// Poster-inspired KREVZY identity background:
/// white/cloud base + pink/lavender/sky-blue/peach glow.
class _PosterGradient extends StatelessWidget {
  const _PosterGradient();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFBFCFF),
                Color(0xFFF0F2FF),
                Color(0xFFFFEAF7),
                Color(0xFFEAE5FF),
                Color(0xFFDDF3FF),
                Color(0xFFFFF0E8),
              ],
              stops: [0.0, 0.16, 0.36, 0.58, 0.80, 1.0],
            ),
          ),
        ),
        _Glow(alignment: const Alignment(-.90, -.78), color: const Color(0xFFFFD9EE), size: 520),
        _Glow(alignment: const Alignment(.86, -.68), color: const Color(0xFFDDE6FF), size: 560),
        _Glow(alignment: const Alignment(-.72, .35), color: const Color(0xFFE8D9FF), size: 620),
        _Glow(alignment: const Alignment(.76, .42), color: const Color(0xFFFFDFD1), size: 620),
        _Glow(alignment: const Alignment(.05, .96), color: const Color(0xFFCFEFFF), size: 680),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Glow({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: .62),
                color.withValues(alpha: .28),
                color.withValues(alpha: 0),
              ],
              stops: const [0, .42, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class KrevzyGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const KrevzyGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD8F0), Color(0xFFD9EDFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .8)),
        boxShadow: const [
          BoxShadow(blurRadius: 24, offset: Offset(0, 10), color: Color(0x22000000)),
        ],
      ),
      child: child,
    );
  }
}
