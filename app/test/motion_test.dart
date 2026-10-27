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
      if (![Motion.float, Motion.crawl, Motion.sway, Motion.shelf, Motion.drift].contains(motion)) expect(turned, isTrue, reason: '$motion');
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

  test('each scene has six or eight things to color', () {
    for (final habitat in Habitat.values) {
      final six = {Habitat.zoo, Habitat.aquarium, Habitat.dinoPark, Habitat.botanical, Habitat.insects};
      expect(habitat.creatures, hasLength(six.contains(habitat) ? 6 : 8), reason: '$habitat');
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

  test("the shop's goods stand side by side on the shelves the screen shows", () {
    for (final screen in [const Size(390, 844), const Size(1280, 800), const Size(1024, 1366)]) {
      final view = SceneView(screen);
      final spots = shelfSpots(view);
      expect(spots.length, greaterThanOrEqualTo(8), reason: '$screen');
      for (final (i, a) in spots.indexed) {
        expect(shopBoards, contains(a.dy));
        expect(a.dx, inInclusiveRange(view.visible.left + 40, view.visible.right - 40), reason: '$screen');
        // Room for the goods above the board, clear of the buttons.
        expect(a.dy - 150, greaterThanOrEqualTo(view.visible.top + 110 / view.scale), reason: '$screen');
        for (final b in spots.skip(i + 1)) {
          expect((a - b).distance, greaterThan(129.9), reason: '$screen');
        }
      }
      // The lowest shelf fills first.
      expect(spots.first.dy, shopBoards.first);
      for (final creature in Habitat.shop.creatures) {
        final pose = poseAt(creature.motion, 12.3, 5, Rect.fromPoints(spots[2], spots[2]));
        expect(pose.at, spots[2], reason: '$creature stays on its spot');
      }
    }
  });

  test("the night market's snacks stand on its counters", () {
    for (final screen in [const Size(390, 844), const Size(1280, 800)]) {
      final view = SceneView(screen);
      final spots = shelfSpots(view, boards: marketCounters);
      expect(spots.length, greaterThanOrEqualTo(6), reason: '$screen');
      expect(spots.map((s) => s.dy).toSet().every(marketCounters.contains), isTrue);
    }
  });

  test('orcas keep to the icy sea, goldfish to their pool; things in space drift and penguins slide', () {
    final view = SceneView(const Size(390, 844));
    for (var t = 0.0; t < 90; t += 0.5) {
      expect(poseAt(Motion.swim, t, 4, roamArea(Creature.orca, view)).at.dy, inInclusiveRange(530, 720), reason: 'orca at $t');
      expect(poseAt(Motion.swim, t, 4, roamArea(Creature.goldfish, view)).at.dy, inInclusiveRange(890, 1000), reason: 'goldfish at $t');
    }
    final turns = {for (var t = 0.0; t < 60; t += 0.5) (poseAt(Motion.drift, t, 9, roamArea(Creature.astronaut, view)).tilt * 10).round()};
    expect(turns.length, greaterThan(4), reason: 'an astronaut turns slowly as it drifts');
    final slides = [for (var t = 0.0; t < 120; t += 0.25) poseAt(Motion.slide, t, 2, roamArea(Creature.penguin, view)).tilt.abs()];
    expect(slides.any((tilt) => tilt > 1), isTrue, reason: 'now and then the penguin is on its belly');
    expect(slides.any((tilt) => tilt < 0.2), isTrue, reason: 'and then it waddles again');
  });
}
