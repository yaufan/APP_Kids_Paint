import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/features/scene/motion.dart';

void main() {
  test('every creature stays inside its area and the walkers turn around', () {
    const area = Rect.fromLTRB(100, 600, 900, 900);
    for (final motion in Motion.values) {
      var turned = false;
      for (var t = 0.0; t < 120; t += 0.25) {
        final pose = poseAt(motion, t, 42, area);
        expect(pose.at.dx, inInclusiveRange(area.left - 1, area.right + 1), reason: '$motion at $t');
        expect(pose.at.dy, inInclusiveRange(area.top - 70, area.bottom + 1), reason: '$motion at $t');
        turned |= pose.left;
      }
      if (![Motion.float, Motion.crawl, Motion.sway].contains(motion)) expect(turned, isTrue, reason: '$motion');
    }
  });

  test('roaming areas sit on screen on a phone and a landscape tablet', () {
    for (final screen in [const Size(390, 844), const Size(1280, 800)]) {
      final view = SceneView(screen);
      for (final creature in Creature.values) {
        final area = roamArea(creature, view);
        final visible = view.visible;
        expect(area.left, greaterThanOrEqualTo(visible.left), reason: '$creature on $screen');
        expect(area.right, lessThanOrEqualTo(visible.right), reason: '$creature on $screen');
        expect(area.top, greaterThan(visible.top), reason: '$creature on $screen');
        expect(area.bottom, lessThanOrEqualTo(visible.bottom), reason: '$creature on $screen');
      }
    }
  });

  test('each scene has six animals or plants, or eight vehicles, to color', () {
    for (final habitat in Habitat.values) {
      expect(habitat.creatures, hasLength(habitat.residents == Residents.vehicles ? 8 : 6));
      expect(Habitat.of(habitat.place), habitat);
    }
  });

  test('cars drive on the road, trains run on the track, planes fly above', () {
    final view = SceneView(const Size(390, 844));
    for (final creature in Habitat.transport.creatures) {
      final area = roamArea(creature, view);
      for (var t = 0.0; t < 60; t += 0.7) {
        final y = poseAt(creature.motion, t, 3, area).at.dy;
        switch (creature.motion) {
          case Motion.drive:
            expect(y, inInclusiveRange(780, 930), reason: '$creature');
          case Motion.rail:
            expect(y, closeTo(648, 2), reason: '$creature');
          default:
            expect(y, lessThan(600), reason: '$creature');
        }
      }
    }
  });

  test('plants stay where they grow, in the garden beds', () {
    final view = SceneView(const Size(390, 844));
    for (final creature in Habitat.botanical.creatures) {
      final area = roamArea(creature, view);
      final start = poseAt(creature.motion, 0, 5, area).at;
      for (var t = 0.0; t < 60; t += 0.7) {
        final pose = poseAt(creature.motion, t, 5, area);
        expect(pose.at, start, reason: '$creature');
        expect(pose.tilt.abs(), lessThan(0.1), reason: '$creature');
        expect(pose.at.dy, inInclusiveRange(720, 950), reason: '$creature');
      }
    }
  });
}
