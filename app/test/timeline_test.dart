import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/features/album/timeline_view.dart';

Artwork art(int id, DateTime when, {bool sent = true}) => Artwork(
      id: id,
      childId: 1,
      style: 'blank',
      detail: 'simple',
      folder: 'f$id',
      tags: '',
      isFavorite: false,
      isCompleted: sent,
      sentAt: sent ? when : null,
      createdAt: when,
      updatedAt: when,
    );

void main() {
  test('artworks are grouped by day, newest first or oldest first', () {
    final arts = [
      art(1, DateTime(2026, 9, 3, 10)),
      art(2, DateTime(2026, 10, 25, 9)),
      art(3, DateTime(2026, 10, 25, 18)),
      art(4, DateTime(2026, 10, 20, 8), sent: false),
    ];
    final newest = timelineDays(arts);
    expect([for (final d in newest) d.day], [DateTime(2026, 10, 25), DateTime(2026, 10, 20), DateTime(2026, 9, 3)]);
    expect([for (final a in newest.first.artworks) a.id], [3, 2]);
    final oldest = timelineDays(arts, newestFirst: false);
    expect(oldest.first.day, DateTime(2026, 9, 3));
    expect([for (final a in oldest.last.artworks) a.id], [2, 3]);
  });

  test('day labels name the weekday, and the year only when it is not this year', () {
    expect(Strings.dayLabel(DateTime(2026, 10, 25), DateTime(2026, 10, 26)), '10月25日 星期日');
    expect(Strings.dayLabel(DateTime(2025, 12, 31), DateTime(2026, 10, 26)), '2025年12月31日 星期三');
  });

  testWidgets('dragging the rail jumps through the months and shows which one', (tester) async {
    final arts = [
      for (var m = 1; m <= 10; m++)
        for (var d = 1; d <= 9; d++) art(m * 100 + d, DateTime(2026, m, d * 3)),
    ];
    final thumb = File('${Directory.systemTemp.path}/kp_missing_thumb.png');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TimelineView(artworks: arts, thumbnailOf: (_) => thumb, onOpen: (_) {})),
    ));
    expect(find.text(Strings.dayLabel(DateTime(2026, 10, 27), DateTime.now())), findsOneWidget);

    final rail = tester.getRect(find.byKey(const ValueKey('timeline-rail')));
    final gesture = await tester.startGesture(rail.topCenter + const Offset(0, 4));
    await gesture.moveTo(rail.bottomCenter - const Offset(0, 4));
    await tester.pump();
    expect(find.text(Strings.monthLong(DateTime(2026, 1))), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(find.text(Strings.dayLabel(DateTime(2026, 1, 3), DateTime.now())), findsOneWidget);
  });

  testWidgets('the bubble names the month beside the finger, even on the last screen', (tester) async {
    // One artwork every 9 days: the last screen holds two or three months.
    final arts = [for (var i = 0; i < 15; i++) art(i + 1, DateTime(2026, 10, 24, 16).subtract(Duration(days: i * 9)))];
    final thumb = File('${Directory.systemTemp.path}/kp_missing_thumb.png');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: TimelineView(artworks: arts, thumbnailOf: (_) => thumb, onOpen: (_) {})),
    ));
    final rail = tester.getRect(find.byKey(const ValueKey('timeline-rail')));
    final gesture = await tester.startGesture(rail.topCenter + const Offset(0, 4));
    await gesture.moveTo(rail.bottomCenter - const Offset(0, 4));
    await tester.pump();
    expect(find.text(Strings.monthLong(DateTime(2026, 6))), findsOneWidget);
    await gesture.up();
  });
}
