// Records a demo video of the app being used: a scripted child (and a white
// dot where the finger is) with a caption under the phone screen.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//
// Needs ffmpeg; writes build/demo/demo.mp4. Skipped in normal test runs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/capture_screen.dart';

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;

/// Creatures colored "before" the video starts, so the places are already
/// lived in: the biggest area of each page gets the first color, the other
/// areas take turns with the rest.
const _residents = <Creature, List<int>>{
  Creature.giraffe: [0xFFFFD166, 0xFFA0673F],
  Creature.lion: [0xFFFFC56B, 0xFFA0673F, 0xFFFFE2B0],
  Creature.monkey: [0xFFA0673F, 0xFFFFD2B8],
  Creature.zebra: [0xFFFFFFFF, 0xFFFFFFFF], // white between its black stripes
  Creature.clownfish: [0xFFFF9F45, 0xFFFFFFFF, 0xFF4DA3FF],
  Creature.octopus: [0xFF8C6CFF, 0xFFFFC2DA],
  Creature.turtle: [0xFF5FCB79, 0xFFB6E08A, 0xFF2EC4B6],
  Creature.jellyfish: [0xFFFF8FB1, 0xFFFFD6E5],
  Creature.crab: [0xFFFF5E5B, 0xFFFFB4A8],
  Creature.triceratops: [0xFF5FCB79, 0xFFFFD166, 0xFFFFFFFF],
  Creature.brachiosaurus: [0xFF4DA3FF, 0xFFFFD166],
  Creature.stegosaurus: [0xFFFF8FB1, 0xFFFFD166],
  Creature.pterosaur: [0xFFFF9F45, 0xFF8C6CFF],
  Creature.babyDino: [0xFF5FCB79, 0xFFFFF1DA, 0xFFFFD166],
  Creature.fireTruck: [0xFFFF5E5B, 0xFFA0E1FF, 0xFF34413A, 0xFFFFD166],
  Creature.bus: [0xFFFFD166, 0xFFA0E1FF, 0xFF34413A],
  Creature.train: [0xFFFF5E5B, 0xFF34413A, 0xFFFFD166],
  Creature.airplane: [0xFF4DA3FF, 0xFFFFFFFF],
  Creature.helicopter: [0xFFFFD166, 0xFFA0E1FF, 0xFF34413A],
  Creature.scooter: [0xFF4DA3FF, 0xFF34413A, 0xFFFFD166],
};

void main() {
  testWidgets('demo video', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('kp_demo'));
    final dbFile = File('${dir!.path}/db.sqlite');
    await tester.runAsync(() => _colorResidents(dbFile, dir));

    var now = DateTime(2026, 10, 27, 10, 15);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    final db = AppDatabase(NativeDatabase(dbFile));
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    databaseProvider.overrideWithValue(db),
                    artworkStoreProvider.overrideWithValue(ArtworkStore(dir)),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const KidsPaintApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF34413A),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Huninn', color: Colors.white, fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = await tester.runAsync(() => _Recorder.start(key));
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(() async {
          await rec!.capture();
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> until(Finder f, {double max = 30}) async {
      for (var i = 0; i < max * _fps && f.evaluate().isEmpty; i++) {
        await frames(1);
      }
      expect(f, findsWidgets);
    }

    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(3);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Future<void> tap(Finder f) => touch(tester.getCenter(f.first));
    Future<void> stroke(List<Offset> points) async {
      finger.value = points.first;
      final g = await tester.startGesture(points.first);
      await frames(2);
      for (final p in points.skip(1)) {
        await g.moveTo(p);
        finger.value = p;
        await frames(1);
      }
      await g.up();
      finger.value = null;
      await frames(2);
    }

    Future<void> fill(List<(int, double, double)> spots) async {
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      for (final (color, dx, dy) in spots) {
        await tap(find.byKey(ValueKey('swatch-$color')));
        await touch(page.topLeft + Offset(page.width * dx, page.height * dy));
        await frames(3);
      }
    }

    // 1. The town.
    caption.value = '小鎮地圖：小朋友自己的小鎮\n（今天白天，手指可以拖動地圖）';
    await until(find.bySemanticsLabel(Strings.takePhoto));
    await seconds(2.5);
    await stroke([for (var i = 0; i <= 10; i++) Offset(300 - i * 16.0, 520 - i * 4.0)]);
    await seconds(1);
    await stroke([for (var i = 0; i <= 10; i++) Offset(140 + i * 16.0, 480 + i * 4.0)]);
    await seconds(1);

    // 2. Photo -> magic -> styles -> coloring -> send.
    caption.value = '點紅色相機：拍照或選照片\n（影片裡用一張咖啡杯照片代替真的拍照）';
    await tap(find.bySemanticsLabel(Strings.takePhoto));
    await until(find.bySemanticsLabel(Strings.camera));
    await seconds(2);
    final photo = File('test/assets/coffee.jpg').readAsBytesSync();
    GoRouter.of(tester.element(find.byType(CaptureScreen))).push('/styles', extra: photo);
    caption.value = '魔法變身：照片變成著色畫';
    await until(find.bySemanticsLabel(Strings.realistic));
    caption.value = '選一張喜歡的：真實或可愛';
    await seconds(2);
    await tap(find.bySemanticsLabel(Strings.realistic));
    await until(find.byKey(const ValueKey('page')));
    caption.value = '著色：選顏色，用油漆桶點一下就填滿\n（不會塗出線外）';
    await seconds(1);
    await fill([(kidPalette[0], 0.5, 0.3), (kidPalette[2], 0.5, 0.55), (kidPalette[5], 0.1, 0.1), (kidPalette[3], 0.85, 0.85)]);
    caption.value = '魔法蠟筆：畫在一個區塊裡，也不會出界';
    await tap(find.bySemanticsLabel(Strings.crayon));
    await tap(find.byKey(ValueKey('swatch-${kidPalette[7]}')));
    final page = tester.getRect(find.byKey(const ValueKey('page')));
    await stroke([for (var i = 0; i <= 12; i++) page.topLeft + Offset(page.width * (0.3 + i * 0.03), page.height * 0.8 + (i.isEven ? -10 : 10))]);
    await seconds(0.5);
    caption.value = '新工具：彩虹筆、亮晶晶筆';
    for (final (tool, y) in [(Strings.rainbow, 0.62), (Strings.glitter, 0.92)]) {
      await tap(find.bySemanticsLabel(tool));
      await stroke([for (var i = 0; i <= 14; i++) page.topLeft + Offset(page.width * (0.12 + i * 0.05), page.height * y + (i.isEven ? -10 : 10))]);
    }
    caption.value = '新工具：印章（星星、愛心、花朵、腳印）';
    await tap(find.bySemanticsLabel(Strings.stamp));
    await seconds(0.5);
    final stamped = tester.getRect(find.byKey(const ValueKey('page')));
    for (final (shape, color, dx, dy) in [('星星', kidPalette[2], 0.15, 0.12), ('花朵', kidPalette[6], 0.12, 0.42), ('腳印', kidPalette[8], 0.85, 0.5)]) {
      await tap(find.bySemanticsLabel(Strings.stampOf(shape)));
      await tap(find.byKey(ValueKey('swatch-$color')));
      await touch(stamped.topLeft + Offset(stamped.width * dx, stamped.height * dy));
    }
    await seconds(1.5);
    caption.value = '畫好了，寄出：選要寄到哪裡';
    await tap(find.bySemanticsLabel(Strings.done));
    await until(find.bySemanticsLabel(Strings.sendTo(PlaceKind.park.label)));
    await seconds(1.5);
    await tap(find.bySemanticsLabel(Strings.sendTo(PlaceKind.park.label)));
    caption.value = '寄出囉！第一次寄到公園，公園就蓋起來';
    await until(find.bySemanticsLabel(Strings.pinLabel(PlaceKind.park.label, 1)), max: 10);
    await seconds(3.5);

    // 3. The zoo.
    caption.value = '右邊的招牌：去動物園';
    await tap(find.bySemanticsLabel(Strings.goTo(PlaceKind.zoo.label)));
    await seconds(1.5);
    await tap(find.bySemanticsLabel(Strings.enter(PlaceKind.zoo.label)));
    caption.value = '動物園：住著小朋友畫的動物\n角色會說話（手機上會念出來）';
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.zoo.label)));
    await seconds(3);
    caption.value = '點一下動物，牠會跳起來';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.lion.label)));
    await seconds(1.5);
    caption.value = '黃色按鈕：選一隻新的動物來畫';
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.zoo.label)));
    await until(find.byKey(const ValueKey('creature-elephant')));
    await seconds(1.5);
    await tap(find.byKey(const ValueKey('creature-elephant')));
    await until(find.byKey(const ValueKey('page')));
    caption.value = 'APP 提供的大象著色圖';
    await seconds(1);
    await fill([(kidPalette[5], 0.42, 0.56), (kidPalette[7], 0.75, 0.42), (kidPalette[7], 0.6, 0.4), (kidPalette[2], 0.3, 0.72)]);
    caption.value = '畫好了 → 大象住進動物園';
    await tap(find.bySemanticsLabel(Strings.done));
    await until(find.bySemanticsLabel(Strings.resident(Creature.elephant.label)));
    await seconds(5);

    // 4. The aquarium.
    caption.value = '回到小鎮，再去左邊的海洋館';
    await tap(find.bySemanticsLabel(Strings.backToTown));
    await until(find.bySemanticsLabel(Strings.blankPaper));
    await seconds(1);
    final sign = find.bySemanticsLabel(Strings.goTo(PlaceKind.aquarium.label));
    if (sign.evaluate().isNotEmpty) {
      await tap(sign);
      await seconds(1.5);
    }
    await tap(find.bySemanticsLabel(Strings.enter(PlaceKind.aquarium.label)));
    caption.value = '海洋館：魚會游、水母會飄、螃蟹橫著走';
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.aquarium.label)));
    await seconds(5);

    // 4b. The dinosaur park.
    caption.value = '新地方：恐龍樂園';
    await tap(find.bySemanticsLabel(Strings.backToTown));
    await until(find.bySemanticsLabel(Strings.blankPaper));
    await seconds(1);
    final dinoSign = find.bySemanticsLabel(Strings.goTo(PlaceKind.dinoPark.label));
    if (dinoSign.evaluate().isNotEmpty) {
      await tap(dinoSign);
      await seconds(1.5);
    }
    await tap(find.bySemanticsLabel(Strings.enter(PlaceKind.dinoPark.label)));
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.dinoPark.label)));
    caption.value = '恐龍樂園：翼龍會飛、恐龍寶寶會跳';
    await seconds(3);
    caption.value = '點一下恐龍：牠會跳起來、說一句話';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.triceratops.label)));
    await seconds(2.5);
    await tap(find.bySemanticsLabel(Strings.resident(Creature.babyDino.label)));
    await seconds(2.5);

    // 4c. The transport museum.
    caption.value = '新地方：交通車館（在小鎮右邊）';
    await tap(find.bySemanticsLabel(Strings.backToTown));
    await until(find.bySemanticsLabel(Strings.blankPaper));
    await seconds(1);
    final transportSign = find.bySemanticsLabel(Strings.goTo(PlaceKind.transport.label));
    if (transportSign.evaluate().isNotEmpty) {
      await tap(transportSign);
      await seconds(1.5);
    }
    await tap(find.bySemanticsLabel(Strings.enter(PlaceKind.transport.label)));
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.transport.label, vehicles: true)));
    caption.value = '汽車在馬路上開、火車在鐵軌上跑\n飛機和直升機在天上飛';
    await seconds(4);
    caption.value = '點一下火車：它會跳起來、說一句話';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.train.label)));
    await seconds(2.5);
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.transport.label, vehicles: true)));
    caption.value = '畫一台新的：8 台車可以選';
    await seconds(3);
    await touch(const Offset(195, 150)); // outside the sheet: it slides away
    await seconds(1);

    // 4d. The album as one timeline.
    caption.value = '明信片冊：右上角切換「依時間看」';
    await tap(find.bySemanticsLabel(Strings.backToTown));
    await until(find.bySemanticsLabel(Strings.album));
    await seconds(1);
    await tap(find.bySemanticsLabel(Strings.album));
    await until(find.bySemanticsLabel(Strings.byTime));
    await seconds(1.5);
    await tap(find.bySemanticsLabel(Strings.byTime));
    await until(find.byKey(const ValueKey('timeline')));
    caption.value = '所有作品依日期排開，可以選新到舊、舊到新';
    await seconds(2.5);
    await tap(find.bySemanticsLabel(Strings.oldestFirst));
    await seconds(1.5);
    await tap(find.bySemanticsLabel(Strings.newestFirst));
    await seconds(1);
    caption.value = '右邊的時間軸可以上下拖動';
    final rail = tester.getRect(find.byKey(const ValueKey('timeline-rail')));
    // Slowly down to the oldest month, a pause, then back up a little.
    Offset onRail(double f) => rail.topCenter + Offset(0, 10 + (rail.height - 20) * f);
    await stroke([
      for (var i = 0; i <= 60; i++) onRail(i / 60),
      for (var i = 0; i < 20; i++) onRail(1),
      for (var i = 0; i <= 40; i++) onRail(1 - 0.6 * i / 40),
      for (var i = 0; i < 20; i++) onRail(0.4),
    ]);
    await seconds(1.5);
    await tap(find.bySemanticsLabel(Strings.backToMap));
    await until(find.bySemanticsLabel(Strings.blankPaper));

    // 5. Blank paper.
    caption.value = '右下角的白紙：隨便畫';
    await seconds(1);
    await tap(find.bySemanticsLabel(Strings.blankPaper));
    await until(find.bySemanticsLabel(Strings.paperColor));
    await until(find.byKey(const ValueKey('page')));
    await seconds(0.5);
    final paper = tester.getRect(find.byKey(const ValueKey('page')));
    for (final (color, y) in [(kidPalette[5], 0.3), (kidPalette[0], 0.5), (kidPalette[3], 0.7)]) {
      await tap(find.byKey(ValueKey('swatch-$color')));
      await stroke([for (var i = 0; i <= 12; i++) paper.topLeft + Offset(paper.width * (0.15 + i * 0.055), paper.height * (y + (i.isEven ? -0.04 : 0.04)))]);
    }
    caption.value = '油漆桶在白紙上會換紙的顏色，畫好的線條不會被蓋掉';
    await tap(find.bySemanticsLabel(Strings.paperColor));
    await tap(find.byKey(ValueKey('swatch-${kidPalette[2]}')));
    await touch(paper.center);
    await seconds(2);

    // 6. Christmas Eve night.
    caption.value = '晚上的小鎮（聖誕夜）：窗戶亮燈、咕咕睡覺\n節日時咕咕會送來一封信';
    now = DateTime(2026, 12, 24, 19, 30);
    await tap(find.bySemanticsLabel(Strings.backToMap));
    final letter = find.bySemanticsLabel(Strings.openLetter(Festival.christmas.label));
    await until(letter);
    await seconds(5);
    caption.value = '打開信：聖誕節的著色圖';
    await tap(letter);
    await until(find.byKey(const ValueKey('page')));
    await seconds(1);
    await fill([(kidPalette[3], 0.5, 0.45), (kidPalette[2], 0.5, 0.1), (kidPalette[0], 0.25, 0.9)]);
    await seconds(2);

    await tester.runAsync(() => rec!.finish('build/demo/demo.mp4'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() => db.close());
  }, skip: !const bool.fromEnvironment('DEMO'), timeout: const Timeout(Duration(minutes: 20)));
}

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final fonts = {
    'MaterialIcons': '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    'Huninn': 'assets/fonts/jf-openhuninn-2.1.ttf',
    'Roboto': 'assets/fonts/jf-openhuninn-2.1.ttf',
  };
  for (final MapEntry(key: family, value: path) in fonts.entries) {
    if (!File(path).existsSync()) continue;
    await (FontLoader(family)..addFont(File(path).readAsBytes().then(ByteData.sublistView))).load();
  }
}

/// Colors the residents in a database of their own, before the app opens it.
Future<void> _colorResidents(File dbFile, Directory store) async {
  final db = AppDatabase(NativeDatabase(dbFile));
  final service = ArtworkService(ArtworkRepository(db), ArtworkStore(store));
  final child = await ChildRepository(db).ensureDefault();
  for (final (i, MapEntry(key: c, value: colors)) in _residents.entries.indexed) {
    final art = await service.saveTemplate(childId: child.id, template: c.name, png: File('assets/pages/${c.name}.png').readAsBytesSync());
    final page = await service.load(art.id);
    final regions = page.document.regions;
    final outside = regions.labelAt(0, 0);
    final area = <int, int>{}, first = <int, int>{};
    for (var i = 0; i < regions.labels.length; i++) {
      final l = regions.labels[i];
      area[l] = (area[l] ?? 0) + 1;
      first.putIfAbsent(l, () => i);
    }
    final order = [for (final l in area.keys) if (l != outside && area[l]! > 300) l]..sort((a, b) => area[b]!.compareTo(area[a]!));
    for (final (k, l) in order.indexed) {
      final color = k == 0 ? colors[0] : colors[1 + (k - 1) % (colors.length - 1)];
      page.document.fill((first[l]! % regions.width).toDouble(), (first[l]! ~/ regions.width).toDouble(), color);
    }
    await service.send(page, await PlaceRepository(db).defaultPlace(child.id, c.habitat.place));
    // Spread them over the last few months, so the timeline has months to drag through.
    final when = DateTime(2026, 10, 24, 16).subtract(Duration(days: i * 9));
    await (db.update(db.artworks)..where((a) => a.id.equals(art.id))).write(ArtworksCompanion(createdAt: Value(when), updatedAt: Value(when), sentAt: Value(when)));
  }
  await db.close();
}

/// The white dot where the finger touches.
class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: const Color(0xFF34413A).withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg, this._out);

  final GlobalKey _key;
  final Process _ffmpeg;
  final String _out;

  static Future<_Recorder> start(GlobalKey key) async {
    const out = 'build/demo/demo.mp4';
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', out,
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg, out);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish(String path) async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
    if (path != _out) File(_out).renameSync(path);
  }
}
