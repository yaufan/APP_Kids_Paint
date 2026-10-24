import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/widgets.dart';

/// Placeholder until the cute city map (phase 2). The database already has
/// a coarse `Places` table so artworks made before then get a history too.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SceneBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PopIn(child: ArtImage(Art.map, size: 180)),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: ToyCard(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            Strings.mapComingSoon,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(left: 16, top: 12, child: HomeButton(onPressed: () => context.go('/'))),
            ],
          ),
        ),
      ),
    );
  }
}
