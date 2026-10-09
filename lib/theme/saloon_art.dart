import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/hand_eval.dart' as cards;
import 'poker_themes.dart';

/// Shared western-saloon UI kit for Lone Star Poker.
/// Pseudo-3D physical materials: felt, wood, brass. No neon, no gradients
/// abuse — depth comes from shadows, bevels and layered panels.
class Saloon {
  static TextStyle display(double size,
          {required PokerThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: color ?? theme.accentLight,
        shadows: const [
          Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 6),
        ],
      );

  static TextStyle title(double size,
          {required PokerThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color ?? theme.textOnFelt,
        shadows: const [
          Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size,
          {required PokerThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? theme.textOnFelt.withValues(alpha: 0.92),
      );

  static TextStyle label(double size,
          {required PokerThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: color ?? theme.accentLight.withValues(alpha: 0.9),
      );

  /// Chunky wooden button with brass edge and press squash.
  static Widget button({
    required PokerThemeDef theme,
    required String text,
    required VoidCallback? onTap,
    IconData? icon,
    bool primary = true,
    double fontSize = 17,
  }) {
    final enabled = onTap != null;
    return _Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: primary ? theme.accent : theme.railWood,
            border: Border.all(
              color: primary ? theme.accentLight : theme.railDark,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                offset: const Offset(0, 5),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                offset: const Offset(0, 1),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: fontSize + 3,
                    color: primary
                        ? theme.railDark
                        : theme.accentLight),
                const SizedBox(width: 10),
              ],
              Text(
                text.toUpperCase(),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: primary ? theme.railDark : theme.accentLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small circular icon button (brass ring on wood).
  static Widget iconButton({
    required PokerThemeDef theme,
    required IconData icon,
    required VoidCallback? onTap,
    double size = 46,
  }) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.railWood,
          border: Border.all(color: theme.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: theme.accentLight, size: size * 0.5),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// Full-screen felt + vignette + wooden rail frame.
class FeltBackdrop extends StatelessWidget {
  final PokerThemeDef theme;
  final Widget child;
  const FeltBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.feltTop, theme.feltBottom],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.15,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: theme.railWood, width: 10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 18,
                spreadRadius: 2,
              ),
              // Inner bevel highlight on the rail.
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.18),
                blurRadius: 6,
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.feltTop, theme.feltBottom],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A poker chip with edge spots and a denomination label.
class ChipWidget extends StatelessWidget {
  final PokerThemeDef theme;
  final ChipStyleDef style;
  final int amount;
  final double size;
  const ChipWidget({
    super.key,
    required this.theme,
    required this.style,
    required this.amount,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ChipPainter(
          edge: theme.chipEdge,
          spots: style.spots,
          felt: theme.feltBottom,
        ),
        child: Center(
          child: Text(
            amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : '$amount',
            style: TextStyle(
              fontSize: size * 0.26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 2)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  final Color edge;
  final List<Color> spots;
  final Color felt;
  _ChipPainter({required this.edge, required this.spots, required this.felt});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // Drop shadow.
    canvas.drawCircle(
        c + const Offset(0, 3), r, Paint()..color = Colors.black45);
    // Edge.
    canvas.drawCircle(c, r, Paint()..color = edge);
    // Spot ring.
    final spotPaint = Paint()..color = spots[0];
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawCircle(
          c + Offset(cos(a), sin(a)) * r * 0.78, r * 0.16, spotPaint);
    }
    // Inner face.
    canvas.drawCircle(c, r * 0.62, Paint()..color = felt);
    canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.06
          ..color = spots.length > 1 ? spots[1] : Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _ChipPainter old) =>
      old.edge != edge || old.spots != spots || old.felt != felt;
}

/// A single playing card: face-up rank/suit or face-down styled back.
class PlayingCardWidget extends StatelessWidget {
  final int? card; // null => face down
  final PokerThemeDef theme;
  final CardStyleDef cardStyle;
  final double width;
  const PlayingCardWidget({
    super.key,
    required this.card,
    required this.theme,
    required this.cardStyle,
    this.width = 52,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 1.42;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            offset: Offset(0, width * 0.08),
            blurRadius: width * 0.12,
          ),
        ],
      ),
      child: card == null
          ? CustomPaint(
              painter: _CardBackPainter(style: cardStyle),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.12),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.35), width: 1),
                ),
              ),
            )
          : _CardFace(card: card!, theme: theme, width: width),
    );
  }
}

class _CardFace extends StatelessWidget {
  final int card;
  final PokerThemeDef theme;
  final double width;
  const _CardFace(
      {required this.card, required this.theme, required this.width});

  @override
  Widget build(BuildContext context) {
    final rank = cards.Card.ranks[cards.Card.rankOf(card)];
    final suit = cards.Card.suits[cards.Card.suitOf(card)];
    final red =
        cards.Card.suitOf(card) == 1 || cards.Card.suitOf(card) == 2;
    final ink = red ? const Color(0xFF9C2B2E) : const Color(0xFF2B2B33);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardFront,
        borderRadius: BorderRadius.circular(width * 0.12),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, theme.cardFront],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.08,
            top: width * 0.05,
            child: Column(
              children: [
                Text(rank,
                    style: TextStyle(
                        fontSize: width * 0.30,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        height: 1.0)),
                Text(suit,
                    style: TextStyle(fontSize: width * 0.24, color: ink, height: 1.0)),
              ],
            ),
          ),
          Center(
            child: Text(suit,
                style: TextStyle(fontSize: width * 0.52, color: ink)),
          ),
          Positioned(
            right: width * 0.08,
            bottom: width * 0.05,
            child: Transform.rotate(
              angle: pi,
              child: Column(
                children: [
                  Text(rank,
                      style: TextStyle(
                          fontSize: width * 0.30,
                          fontWeight: FontWeight.w900,
                          color: ink,
                          height: 1.0)),
                  Text(suit,
                      style:
                          TextStyle(fontSize: width * 0.24, color: ink, height: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  final CardStyleDef style;
  _CardBackPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.12));
    canvas.drawRRect(rrect, Paint()..color = style.back);
    // Inner patterned panel.
    final inner = RRect.fromRectAndRadius(
        rect.deflate(size.width * 0.10), Radius.circular(size.width * 0.08));
    canvas.drawRRect(inner, Paint()..color = style.backPattern);
    // Motif.
    final c = Offset(size.width / 2, size.height / 2);
    final motifPaint = Paint()
      ..color = style.back.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final s = size.width * 0.22;
    switch (style.motif) {
      case 'star':
        _star(canvas, c, s, motifPaint);
        break;
      case 'brand':
        _brand(canvas, c, s, motifPaint);
        break;
      case 'diamond':
        final p = Path()
          ..moveTo(c.dx, c.dy - s)
          ..lineTo(c.dx + s * 0.7, c.dy)
          ..lineTo(c.dx, c.dy + s)
          ..lineTo(c.dx - s * 0.7, c.dy)
          ..close();
        canvas.drawPath(p, motifPaint);
        break;
      case 'moon':
        canvas.drawCircle(c, s, motifPaint);
        canvas.drawCircle(c + Offset(s * 0.45, -s * 0.25), s * 0.8,
            Paint()..color = style.backPattern);
        break;
      case 'cactus':
        final cp = Paint()
          ..color = style.back.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.28
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c + Offset(0, s), c + Offset(0, -s), cp);
        canvas.drawLine(c + Offset(0, s * 0.2), c + Offset(-s * 0.7, s * 0.2), cp);
        canvas.drawLine(c + Offset(-s * 0.7, s * 0.2), c + Offset(-s * 0.7, -s * 0.4), cp);
        canvas.drawLine(c + Offset(0, -s * 0.1), c + Offset(s * 0.7, -s * 0.1), cp);
        canvas.drawLine(c + Offset(s * 0.7, -s * 0.1), c + Offset(s * 0.7, -s * 0.6), cp);
        break;
    }
    // Cross-hatch texture lines.
    final linePaint = Paint()
      ..color = style.back.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (double y = -size.height; y < size.height; y += 7) {
      canvas.drawLine(Offset(0, y + size.width * 0.4),
          Offset(size.width, y - size.width * 0.4), linePaint);
    }
  }

  void _star(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? s : s * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final pt = c + Offset(cos(a) * r, sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  void _brand(Canvas canvas, Offset c, double s, Paint p) {
    // Cattle-brand: circle with a bar through it.
    final ring = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.3;
    canvas.drawCircle(c, s * 0.75, ring);
    canvas.drawLine(c + Offset(-s * 1.1, 0), c + Offset(s * 1.1, 0),
        Paint()..color = p.color..strokeWidth = s * 0.3..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _CardBackPainter old) => old.style != style;
}

/// Pop-in animation for newly dealt cards (new widget keys re-run it).
class DealPop extends StatefulWidget {
  final Widget child;
  final int staggerMs;
  const DealPop({super.key, required this.child, this.staggerMs = 0});

  @override
  State<DealPop> createState() => _DealPopState();
}

class _DealPopState extends State<DealPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.staggerMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
