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
      if (motion != Motion.float && motion != Motion.crawl) expect(turned, isTrue, reason: '$motion');
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

  test('each scene has six creatures to color', () {
    for (final habitat in Habitat.values) {
      expect(habitat.creatures, hasLength(6));
      expect(Habitat.of(habitat.place), habitat);
    }
  });
}
