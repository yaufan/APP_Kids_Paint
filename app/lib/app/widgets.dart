import 'package:flutter/material.dart';

import 'theme.dart';

/// A big round picture button. Children's screens use only these: no text,
/// just an icon, with [label] read out by screen readers.
class KidButton extends StatelessWidget {
  const KidButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.size = KidTheme.bigButton,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Material(
        color: onPressed == null ? color.withValues(alpha: 0.35) : color,
        shape: CircleBorder(
          side: selected ? const BorderSide(color: KidTheme.ink, width: 5) : BorderSide.none,
        ),
        elevation: selected ? 0 : 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: size * 0.5, color: Colors.white),
          ),
        ),
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
      tooltip: '家長模式',
      onPressed: onPressed,
      icon: const Icon(Icons.lock_outline, color: Colors.black38),
    );
  }
}
