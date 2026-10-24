import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'strings.dart';
import 'theme.dart';

enum StickerShape { circle, rounded }

/// A big sticker-style picture button: thick ink outline, hard drop shadow,
/// sinks in when pressed. Children's screens use only these: no text, just
/// an icon, with [label] read out by screen readers.
class KidButton extends StatefulWidget {
  const KidButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.size = KidTheme.bigButton,
    this.shape = StickerShape.circle,
    this.selected = false,
    this.breathing = false,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double size;
  final StickerShape shape;

  /// Shown pressed in, for the active tool.
  final bool selected;

  /// Gently pulses to invite the first tap (the main action on a screen).
  final bool breathing;

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

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
    final enabled = widget.onPressed != null;
    final sunk = _down || widget.selected;
    final depth = KidTheme.depth * widget.size / KidTheme.bigButton + 2;
    final color = enabled ? widget.color : Color.lerp(widget.color, Colors.white, 0.55)!;
    final ShapeBorder shape = widget.shape == StickerShape.circle
        ? const CircleBorder(side: BorderSide(color: KidColors.ink, width: KidTheme.outline))
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.size * 0.3),
            side: const BorderSide(color: KidColors.ink, width: KidTheme.outline),
          );

    final face = AnimatedSlide(
      duration: const Duration(milliseconds: 90),
      offset: Offset(0, sunk ? depth / widget.size : 0),
      child: DecoratedBox(
        decoration: ShapeDecoration(color: color, shape: shape),
        child: SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glossy highlight, like a sticker catching the light.
              Positioned(
                top: widget.size * 0.12,
                left: widget.size * 0.18,
                child: Container(
                  width: widget.size * 0.26,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(widget.size),
                  ),
                ),
              ),
              Icon(
                widget.icon,
                size: widget.size * 0.5,
                color: widget.iconColor,
                shadows: [Shadow(color: KidColors.ink.withValues(alpha: 0.35), offset: const Offset(0, 3))],
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.05)
              .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: SizedBox(
            width: widget.size,
            height: widget.size + depth,
            child: Stack(
              children: [
                // The hard shadow the face sinks into.
                Positioned(
                  top: depth,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(color: enabled ? KidColors.ink : KidColors.ink.withValues(alpha: 0.3), shape: shape),
                    child: SizedBox.square(dimension: widget.size),
                  ),
                ),
                face,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small round sticker that only decorates (not a button).
class StickerBadge extends StatelessWidget {
  const StickerBadge({super.key, required this.icon, required this.color, this.size = 56});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: KidColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: KidColors.ink, offset: Offset(0, 4))],
      ),
      child: Icon(icon, size: size * 0.55, color: Colors.white),
    );
  }
}

/// White card with an ink outline and a hard shadow; [tilt] in degrees.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.tilt = 0,
    this.padding = const EdgeInsets.all(12),
    this.color = Colors.white,
    this.radius = 22,
    this.tape,
  });

  final Widget child;
  final double tilt;
  final EdgeInsets padding;
  final Color color;
  final double radius;

  /// Color of a strip of washi tape across the top, if any.
  final Color? tape;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: KidColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: KidColors.ink, offset: Offset(0, KidTheme.depth))],
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
                  top: -12,
                  child: Transform.rotate(
                    angle: -0.07,
                    child: Container(width: 72, height: 24, color: tape!.withValues(alpha: 0.75)),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The child's animal on a round sticker.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.avatar, this.size = 64, this.onTap});

  final String avatar;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(color: KidColors.ink, width: 3)),
          boxShadow: [BoxShadow(color: KidColors.ink, offset: Offset(0, 4))],
        ),
        child: Text(avatar, style: TextStyle(fontSize: size * 0.58, height: 1.15)),
      ),
    );
  }
}

/// Three bouncing crayon-colored dots: "working on it", without words.
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
                width: 28,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: KidColors.ink, width: 3),
                ),
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
      icon: Icon(Icons.lock_outline_rounded, color: KidColors.ink.withValues(alpha: 0.35)),
    );
  }
}

/// The small home button every child screen has in its top-left corner.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => KidButton(
        icon: Icons.home_rounded,
        label: Strings.home,
        color: KidColors.sun,
        size: KidTheme.toolButton,
        onPressed: onPressed,
      );
}
