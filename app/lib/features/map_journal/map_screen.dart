import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

/// Placeholder until the cute city map (phase 2). The database already has
/// a coarse `Places` table so artworks made before then get a history too.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, size: 160, color: KidTheme.grass),
                    const SizedBox(height: 24),
                    Text(Strings.mapComingSoon,
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: KidButton(
                icon: Icons.home_rounded,
                label: Strings.home,
                color: KidTheme.sun,
                size: KidTheme.toolButton,
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
