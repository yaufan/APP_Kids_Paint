import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'strings.dart';
import 'theme.dart';

/// Squishes when pressed and springs back when released, so every tap feels
/// like poking a toy.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _squish = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 480),
  );

  @override
  void dispose() {
    _squish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _squish.forward() : null,
      onTapCancel: () => _squish.reverse(),
      onTapUp: enabled ? (_) => _squish.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _squish,
        builder: (context, child) {
          // Elastic on the way back: a little overshoot, like rubber.
          final t = _squish.status == AnimationStatus.reverse
              ? Curves.elasticIn.transform(_squish.value)
              : Curves.easeOut.transform(_squish.value);
          return Transform.scale(scaleX: 1 - 0.08 * t, scaleY: 1 - 0.11 * t, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// The main button of the app: a soft white toy tile, like a keycap, with a
/// 3D illustration on it. Children's screens use only these: no text; [label]
/// is read out by screen readers.
class ToyButton extends StatefulWidget {
  const ToyButton({
    super.key,
    required this.art,
    required this.label,
    required this.onPressed,
    this.tint = KidColors.sky,
    this.size = KidTheme.bigButton,
    this.selected = false,
    this.breathing = false,
    this.round = false,
  });

  final String art;
  final String label;
  final VoidCallback? onPressed;

  /// Color of the tile's edge and of its selected state.
  final Color tint;
  final double size;
  final bool selected;

  /// Gently pulses to invite the first tap (the main action on a screen).
  final bool breathing;
  final bool round;

  @override
  State<ToyButton> createState() => _ToyButtonState();
}

class _ToyButtonState extends State<ToyButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  @override
  void initState() {
    super.initState();
    if (widget.breathing) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final edge = s * 0.06;
    final radius = widget.round ? BorderRadius.circular(s) : BorderRadius.circular(s * 0.3);
    final edgeColor = Color.lerp(widget.tint, Colors.black, 0.08)!;
    final face = widget.selected
        ? [Color.lerp(Colors.white, widget.tint, 0.32)!, Color.lerp(Colors.white, widget.tint, 0.5)!]
        : [Colors.white, Color.lerp(Colors.white, widget.tint, 0.12)!];

    final tile = SizedBox(
      width: s,
      height: s + edge,
      child: Stack(
        children: [
          // The colored edge underneath gives the tile its thickness.
          Positioned(
            top: edge,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(color: edgeColor, borderRadius: radius, boxShadow: KidShadows.toy(widget.tint)),
            ),
          ),
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: face),
              border: widget.selected ? Border.all(color: widget.tint, width: s * 0.05) : null,
            ),
            alignment: Alignment.center,
            child: ArtImage(widget.art, size: s * 0.66),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      selected: widget.selected,
      label: widget.label,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.45 : 1,
        child: Pressable(
          onTap: widget.onPressed,
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// A white card with a soft shadow; [tilt] in degrees, optional washi tape.
class ToyCard extends StatelessWidget {
  const ToyCard({
    super.key,
    required this.child,
    this.tilt = 0,
    this.padding = const EdgeInsets.all(12),
    this.radius = 26,
    this.tape,
  });

  final Widget child;
  final double tilt;
  final EdgeInsets padding;
  final double radius;
  final Color? tape;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: KidShadows.toy(),
      ),
      child: child,
    );
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: tape == null
          ? card
          : Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                card,
                Positioned(
                  top: -11,
                  child: Transform.rotate(
                    angle: -0.06,
                    child: Container(
                      width: 78,
                      height: 24,
                      decoration: BoxDecoration(
                        color: tape!.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The child's 3D animal on a round white token.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.avatar, this.size = 68, this.onTap});

  final String avatar;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: KidShadows.toy()),
        child: ArtImage(Art.avatar(avatar)),
      ),
    );
  }
}

/// A decorative round badge with a 3D illustration (not a button).
class ArtBadge extends StatelessWidget {
  const ArtBadge({super.key, required this.art, this.size = 60, this.tint = Colors.white});

  final String art;
  final double size;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle, boxShadow: KidShadows.toy()),
      child: ArtImage(art),
    );
  }
}

/// A white speech bubble with a tail pointing down-left at whoever speaks.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(),
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 26), child: child),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromLTRBR(0, 0, size.width, size.height - 14, const Radius.circular(24));
    final tail = Path()
      ..moveTo(size.width * 0.18, size.height - 16)
      ..lineTo(size.width * 0.1, size.height)
      ..lineTo(size.width * 0.34, size.height - 16)
      ..close();
    final shape = Path()
      ..addRRect(body)
      ..addPath(tail, Offset.zero);
    canvas.drawShadow(shape, const Color(0xFF6B4E71), 6, false);
    canvas.drawPath(shape, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

/// Pops in with a little bounce, after [delay]; lets a screen's toys arrive
/// one by one instead of all at once.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  static const _pop = Duration(milliseconds: 520);

  // The delay is the start of the animation's own timeline rather than a
  // timer, so nothing is left pending when the screen goes away early.
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + _pop)..forward();
  late final double _start = widget.delay.inMicroseconds / (widget.delay + _pop).inMicroseconds;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = _start + (1 - _start) * 0.4;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Interval(_start, fade)),
      // Screen readers see the buttons straight away, not after the pop.
      alwaysIncludeSemantics: true,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Interval(_start, 1, curve: Curves.easeOutBack)),
        child: widget.child,
      ),
    );
  }
}

/// Three bouncing colored dots: "working on it", without words.
class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [KidColors.berry, KidColors.sun, KidColors.sky];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(0, -18 * math.max(0, math.sin((_c.value - i * 0.18) * 2 * math.pi))),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle, boxShadow: KidShadows.toy(colors[i])),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small lock in a corner that opens the parent gate; deliberately
/// unremarkable so children leave it alone.
class ParentCornerButton extends StatelessWidget {
  const ParentCornerButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Strings.parentMode,
      onPressed: onPressed,
      icon: Icon(Icons.lock_outline_rounded, color: KidColors.ink.withValues(alpha: 0.3)),
    );
  }
}

/// The home button every child screen has in its top-left corner.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ToyButton(
        art: Art.home,
        label: Strings.home,
        tint: KidColors.sun,
        size: KidTheme.toolButton,
        onPressed: onPressed,
      );
}
