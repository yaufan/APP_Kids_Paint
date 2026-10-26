import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';

/// When an artwork belongs on the timeline: when it was sent, or last colored.
DateTime timelineDate(Artwork a) => a.sentAt ?? a.updatedAt;

/// A section of the timeline: one day's artworks, in order.
typedef TimelineDay = ({DateTime day, List<Artwork> artworks});

/// [artworks] grouped by day, newest day first (or oldest first).
List<TimelineDay> timelineDays(List<Artwork> artworks, {bool newestFirst = true}) {
  final sorted = [...artworks]..sort((a, b) {
      final c = timelineDate(a).compareTo(timelineDate(b));
      return newestFirst ? -c : c;
    });
  final days = <TimelineDay>[];
  for (final a in sorted) {
    final t = timelineDate(a);
    final day = DateTime(t.year, t.month, t.day);
    if (days.isEmpty || days.last.day != day) days.add((day: day, artworks: []));
    days.last.artworks.add(a);
  }
  return days;
}

/// Every artwork at once in time order, a header per day, and a rail on the
/// right to drag through the months (a bubble shows the month).
class TimelineView extends StatefulWidget {
  const TimelineView({super.key, required this.artworks, required this.thumbnailOf, required this.onOpen, this.newestFirst = true});

  final List<Artwork> artworks;
  final File Function(Artwork artwork) thumbnailOf;
  final ValueChanged<Artwork> onOpen;
  final bool newestFirst;

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final _scroll = ScrollController();
  double? _drag; // where the finger is on the rail, 0..1

  static const _header = 52.0;
  static const _gap = 10.0;
  static const _rail = 46.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimelineView old) {
    super.didUpdateWidget(old);
    if (old.newestFirst != widget.newestFirst && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth - _rail;
      final columns = (width / 128).floor().clamp(3, 8);
      final cell = (width - 32 - (columns - 1) * _gap) / columns;
      final days = timelineDays(widget.artworks, newestFirst: widget.newestFirst);

      // Flatten into rows of fixed height so every position is known: the
      // rail can then jump straight to any month.
      final rows = <({DateTime day, List<Artwork>? row})>[];
      for (final d in days) {
        rows.add((day: d.day, row: null));
        for (var i = 0; i < d.artworks.length; i += columns) {
          rows.add((day: d.day, row: d.artworks.sublist(i, math.min(i + columns, d.artworks.length))));
        }
      }
      double extent(int i) => rows[i].row == null ? _header : cell + _gap;
      final offsets = <double>[];
      var total = 0.0;
      for (var i = 0; i < rows.length; i++) {
        offsets.add(total);
        total += extent(i);
      }
      total += 40; // bottom padding

      // Where each month starts, as a fraction of all the rows. With the
      // thumb at f the list is scrolled f of the way, so the row at f of
      // the content is on screen next to the thumb: the bubble names what
      // the child sees beside the finger, down to the last month.
      final months = <({DateTime month, double at})>[];
      for (var i = 0; i < rows.length; i++) {
        final m = DateTime(rows[i].day.year, rows[i].day.month);
        if (months.isEmpty || months.last.month != m) months.add((month: m, at: (offsets[i] / total).clamp(0.0, 1.0)));
      }
      DateTime monthAt(double f) {
        final target = f * total;
        var i = 0;
        while (i + 1 < rows.length && offsets[i + 1] <= target) {
          i++;
        }
        return DateTime(rows[i].day.year, rows[i].day.month);
      }

      void jump(double localY, double railHeight) {
        final f = (localY / railHeight).clamp(0.0, 1.0);
        setState(() => _drag = f);
        if (_scroll.hasClients) _scroll.jumpTo(f * _scroll.position.maxScrollExtent);
      }

      return Stack(children: [
        Positioned.fill(
          right: _rail,
          child: ListView.builder(
            key: const ValueKey('timeline'),
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: rows.length,
            itemExtentBuilder: (i, _) => i < rows.length ? extent(i) : null,
            itemBuilder: (context, i) {
              final r = rows[i];
              final row = r.row;
              if (row == null) {
                final count = days.firstWhere((d) => d.day == r.day).artworks.length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 6),
                  child: Row(children: [
                    const KidIcon('clock', size: 20, color: KidColors.inkSoft),
                    const SizedBox(width: 8),
                    Text(Strings.dayLabel(r.day, DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(Strings.count(count), style: const TextStyle(fontSize: 14, color: KidColors.inkSoft)),
                  ]),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, _gap),
                child: Row(children: [
                  for (final (k, art) in row.indexed) ...[
                    if (k > 0) const SizedBox(width: _gap),
                    _TimelineCard(artwork: art, size: cell, image: FileImage(widget.thumbnailOf(art)), onTap: () => widget.onOpen(art)),
                  ],
                ]),
              );
            },
          ),
        ),
        // The rail: month marks, a thumb that follows the scroll, and a
        // bubble with the month while dragging.
        Positioned(
          right: 0,
          top: 10,
          bottom: 10,
          width: _rail,
          child: LayoutBuilder(builder: (context, rail) {
            final h = rail.maxHeight;
            return Semantics(
              slider: true,
              label: Strings.timelineRail,
              child: GestureDetector(
                key: const ValueKey('timeline-rail'),
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (d) => jump(d.localPosition.dy, h),
                onVerticalDragUpdate: (d) => jump(d.localPosition.dy, h),
                onVerticalDragEnd: (_) => setState(() => _drag = null),
                onTapDown: (d) => jump(d.localPosition.dy, h),
                onTapUp: (_) => setState(() => _drag = null),
                child: AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    final scrolled = _scroll.hasClients && _scroll.position.hasContentDimensions
                        ? (_scroll.offset / math.max(1.0, _scroll.position.maxScrollExtent)).clamp(0.0, 1.0)
                        : 0.0;
                    final f = _drag ?? scrolled;
                    // At most one month label every 44 px.
                    final labels = <({DateTime month, double at})>[];
                    for (final m in months) {
                      if (labels.isEmpty || (m.at - labels.last.at) * h >= 44) labels.add(m);
                    }
                    return Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        left: _rail / 2 - 3,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 6, decoration: BoxDecoration(color: const Color(0xFFE9DFCC), borderRadius: BorderRadius.circular(3))),
                      ),
                      for (final m in labels)
                          Positioned(
                            right: 0,
                            left: 0,
                            top: (m.at * h - 9).clamp(0.0, h - 18),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                color: KidColors.paper,
                                child: Text(Strings.monthShort(m.month), style: const TextStyle(fontSize: 12, color: KidColors.inkSoft, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                      Positioned(
                        left: _rail / 2 - 14,
                        top: (f * h - 14).clamp(0.0, h - 28),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: KidColors.coral, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: KidShadows.soft()),
                        ),
                      ),
                      if (_drag != null && rows.isNotEmpty)
                        Positioned(
                          right: _rail + 4,
                          top: (f * h - 22).clamp(0.0, h - 44),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: KidColors.ink, borderRadius: BorderRadius.circular(22)),
                            child: Text(Strings.monthLong(monthAt(f)), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ]);
                  },
                ),
              ),
            );
          }),
        ),
      ]);
    });
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.artwork, required this.size, required this.image, required this.onTap});

  final Artwork artwork;
  final double size;
  final ImageProvider image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${shortDate(timelineDate(artwork))} 的明信片',
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: KidShadows.soft()),
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white)),
              ),
              if (artwork.sentAt == null)
                const Positioned(right: 4, top: 4, child: KidIcon('crayon', size: 20, color: KidColors.inkSoft)),
              if (artwork.isFavorite)
                const Positioned(left: 4, top: 4, child: KidIcon('heart', size: 20, color: Color(0xFFFF6F91), solid: true)),
            ]),
          ),
        ),
      );
}
