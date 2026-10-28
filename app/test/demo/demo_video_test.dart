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
import 'package:image/image.dart' as img;
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/album_export.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/play_time.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/capture_screen.dart';

import '../../integration_test/walkthrough.dart' show answerParentGate, WalkthroughSharer;

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;

/// Creatures colored "before" the video starts, so the places are already
/// lived in: each area takes the color its subject really has there
/// (docs/design/v5/colors/, the same drawing in its colors).
const _residents = [
  Creature.giraffe, Creature.lion, Creature.monkey, Creature.zebra, Creature.tiger, Creature.koala, Creature.kangaroo, //
  Creature.clownfish, Creature.octopus, Creature.turtle, Creature.jellyfish, Creature.crab, Creature.dolphin, Creature.pufferfish,
  Creature.triceratops, Creature.brachiosaurus, Creature.stegosaurus, Creature.pterosaur, Creature.babyDino,
  Creature.fireTruck, Creature.bus, Creature.train, Creature.airplane, Creature.helicopter, Creature.scooter,
  Creature.tulip, Creature.cactus, Creature.rose, Creature.lotus,
  Creature.bee, Creature.dragonfly, Creature.beetle, Creature.mantis,
  Creature.milk, Creature.apple, Creature.bubbleTea, Creature.pudding, Creature.bread, Creature.banana, Creature.iceCream,
  Creature.rocket, Creature.astronaut, Creature.alien, Creature.ufo, Creature.saturn, Creature.spaceCat, Creature.star, Creature.moon,
  Creature.friedChicken, Creature.sausage, Creature.tanghulu, Creature.cottonCandy, Creature.shavedIce, Creature.takoyaki, Creature.goldfish,
  Creature.sweetPotatoBalls,
  Creature.penguin, Creature.polarBear, Creature.seal, Creature.snowman, Creature.arcticFox, Creature.orca, Creature.sled, Creature.igloo,
  Creature.lollipop, Creature.cupcake, Creature.gingerbread, Creature.candy, Creature.jelly, Creature.cookie, Creature.cake, Creature.candyCane,
];

/// The photo album, pretend: the demo has no phone to save to.
class _DemoAlbum implements PhotoAlbum {
  @override
  Future<bool> allow() async => true;

  @override
  Future<void> add(File picture) async {}
}

void main() {
  testWidgets('demo video', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('kp_demo'));
    final dbFile = File('${dir!.path}/db.sqlite');
    await tester.runAsync(() => _colorResidents(dbFile, dir));

    // A sunny late morning (the weather is made up from the time: see weather.dart).
    var now = DateTime(2026, 10, 26, 12, 15);
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
                    photoAlbumProvider.overrideWithValue(_DemoAlbum()),
                    sharerProvider.overrideWithValue(WalkthroughSharer()),
                    systemSoundsProvider.overrideWithValue(const SilentSounds()),
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
    // Where each part starts (frame number), to cut a short video of what is new.
    var frameCount = 0;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
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

    // From the town (or a place) into a place you can go into, with the
    // places button.
    Future<void> enterPlace(PlaceKind kind) async {
      final habitat = Habitat.of(kind)!;
      if (find.bySemanticsLabel(Strings.backToTown).evaluate().isNotEmpty) {
        await tap(find.bySemanticsLabel(Strings.backToTown));
        await until(find.bySemanticsLabel(Strings.blankPaper));
        await seconds(1);
      }
      await tap(find.bySemanticsLabel(Strings.places));
      await until(find.bySemanticsLabel(Strings.goTo(habitat.label)));
      await seconds(1.2);
      await tap(find.bySemanticsLabel(Strings.goTo(habitat.label)));
      await until(find.bySemanticsLabel(Strings.drawNew(habitat.label, residents: habitat.residents)));
    }

    // 0. The first day: name the town, pick a friend.
    caption.value = '第一天：幫小鎮取名字，再選一個好朋友';
    await until(find.text(Strings.welcome));
    await seconds(2);
    await tap(find.byKey(const ValueKey('buddy-rabbit')));
    await seconds(1.5);
    await tap(find.byKey(const ValueKey('buddy-bear')));
    await seconds(1);
    await tester.enterText(find.byKey(const ValueKey('town-name')), '小宇');
    await seconds(1.5);
    caption.value = '按「出發！」';
    await tester.ensureVisible(find.bySemanticsLabel(Strings.letsGo));
    await frames(3);
    await tap(find.bySemanticsLabel(Strings.letsGo));

    // 1. The town.
    caption.value = '小鎮地圖：「小宇的小鎮」\n（今天白天，手指可以拖動地圖）';
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
    mark('pens');
    caption.value = '魔法畫筆：畫在一個區塊裡，也不會出界';
    await tap(find.bySemanticsLabel(Strings.crayon));
    await tap(find.byKey(ValueKey('swatch-${kidPalette[7]}')));
    final page = tester.getRect(find.byKey(const ValueKey('page')));
    await stroke([for (var i = 0; i <= 12; i++) page.topLeft + Offset(page.width * (0.3 + i * 0.03), page.height * 0.8 + (i.isEven ? -10 : 10))]);
    await seconds(0.5);
    caption.value = '魔法畫筆有 7 種：蠟筆、粗粗筆、點點筆、噴漆、\n水彩筆、霓虹筆、條紋筆（按鈕上就是它畫出來的樣子）';
    await seconds(2.5);
    for (final (pen, color, y) in [
      (Strings.penDots, kidPalette[6], 0.18),
      (Strings.penSpray, kidPalette[0], 0.34),
      (Strings.penWatercolor, kidPalette[5], 0.5),
      (Strings.penNeon, kidPalette[7], 0.7),
      (Strings.penStripes, kidPalette[0], 0.88),
    ]) {
      await tap(find.bySemanticsLabel(pen));
      await tap(find.byKey(ValueKey('swatch-$color')));
      await stroke([for (var i = 0; i <= 14; i++) page.topLeft + Offset(page.width * (0.14 + i * 0.05), page.height * y + (i.isEven ? -10 : 10))]);
      await seconds(0.6);
    }
    caption.value = '更多顏色：旁邊的小圓圈換一組\n粉彩色、大地色和膚色';
    for (final set in [1, 2, 0]) {
      await tap(find.byKey(ValueKey('palette-$set')));
      await seconds(1.4);
    }
    await seconds(0.6);
    mark('pens_end');
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
    mark('own');
    caption.value = '新功能：塗好的東西會剪下來，住進小鎮\n在公園旁邊跳來跳去';
    final folk = find.bySemanticsLabel(Strings.townFolk(PlaceKind.park.label));
    await until(folk, max: 10);
    await seconds(2.5);
    caption.value = '點它一下，會跳起來翻個跟斗';
    await tap(folk);
    await seconds(1.5);
    await tap(folk);
    await seconds(1.5);
    mark('own_end');
    final coffee = (await tester.runAsync(() => (db.select(db.artworks)..where((a) => a.style.equals('realistic'))).getSingle()))!;

    // 3. The zoo.
    caption.value = '右上角「去哪裡玩」：11 個地方一次看到\n點一下就走進去';
    await enterPlace(PlaceKind.zoo);
    caption.value = '動物園：住著小朋友畫的動物\n角色會說話（手機上會念出來）';
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.zoo.label)));
    await seconds(3);
    caption.value = '點一下動物，牠會跳起來';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.lion.label)));
    await seconds(1.5);
    caption.value = '黃色按鈕：選一隻新的動物來畫\n每個地方都有 12 個，卡片上是彩色的樣子';
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.zoo.label)));
    await until(find.byKey(const ValueKey('creature-elephant')));
    await seconds(3);
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
    await enterPlace(PlaceKind.aquarium);
    caption.value = '海洋館：魚會游、水母會飄、螃蟹橫著走';
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.aquarium.label)));
    await seconds(5);

    // 4b. The dinosaur park.
    caption.value = '新地方：恐龍樂園';
    await enterPlace(PlaceKind.dinoPark);
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.dinoPark.label)));
    caption.value = '恐龍樂園：翼龍會飛、恐龍寶寶會跳';
    await seconds(3);
    caption.value = '點一下恐龍：牠會跳起來、說一句話';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.babyDino.label)));
    await seconds(2.5);
    mark('tickle');
    caption.value = '一直點牠，牠會說「呵呵呵，好癢喔！」\n（角色會看早上晚上、節日、旁邊的朋友說話）';
    for (var i = 0; i < 3; i++) {
      await tap(find.bySemanticsLabel(Strings.resident(Creature.triceratops.label)));
      await seconds(1.2);
    }
    await seconds(2);
    mark('tickle_end');

    // 4c. The transport museum.
    caption.value = '新地方：交通車館（在小鎮右邊）';
    await enterPlace(PlaceKind.transport);
    await until(find.bySemanticsLabel(Strings.drawNew(PlaceKind.transport.label, residents: Residents.vehicles)));
    caption.value = '汽車在馬路上開、火車在鐵軌上跑\n飛機和直升機在天上飛';
    await seconds(4);
    caption.value = '點一下火車：它會跳起來、說一句話';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.train.label)));
    await seconds(2.5);
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.transport.label, residents: Residents.vehicles)));
    caption.value = '畫一台新的：12 台車可以選\n（新的有計程車、垃圾車、挖土機、捷運）';
    await seconds(3);
    await touch(const Offset(195, 150)); // outside the sheet: it slides away
    await seconds(1);

    // 4d. The botanical garden and the insect museum.
    for (final (place, words) in [
      (PlaceKind.botanical, '新地方：植物園（小鎮左下角）\n植物種在花圃裡，跟著風輕輕搖'),
      (PlaceKind.insects, '新地方：昆蟲館（小鎮右下角）\n蜜蜂、蜻蜓會飛，獨角仙在地上爬'),
    ]) {
      caption.value = words.split('\n').first;
      await enterPlace(place);
      await until(find.bySemanticsLabel(Strings.drawNew(place.label, residents: Habitat.of(place)!.residents)));
      caption.value = words;
      await seconds(4);
    }

    // 4f. The shop (0.12): goods on the shelves, customers come to buy.
    mark('shop');
    caption.value = '新地方：商店（地圖中間，紅白條紋的遮雨棚）';
    await enterPlace(PlaceKind.shop);
    caption.value = '小朋友畫的牛奶、蘋果、珍珠奶茶⋯⋯\n都擺在架子上';
    await seconds(3);
    await until(find.bySemanticsLabel(Strings.customer));
    caption.value = '客人來買東西了：「我要買○○！」\n拿走就付一個金幣，架子馬上補貨';
    await seconds(8);
    caption.value = '畫一個新的：12 個可愛的商品可以選';
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.shop.label, residents: Residents.goods)));
    await until(find.byKey(const ValueKey('creature-carrot')));
    await seconds(2);
    await tap(find.byKey(const ValueKey('creature-carrot')));
    await until(find.byKey(const ValueKey('page')));
    caption.value = '胡蘿蔔的著色圖';
    await seconds(1);
    await fill([(kidPalette[1], 0.5, 0.6), (kidPalette[3], 0.5, 0.26), (kidPalette[3], 0.4, 0.31), (kidPalette[3], 0.6, 0.31)]);
    caption.value = '畫好了 → 胡蘿蔔上架到商店';
    await tap(find.bySemanticsLabel(Strings.done));
    await until(find.bySemanticsLabel(Strings.resident(Creature.carrot.label)));
    await seconds(6);
    mark('shop_end');

    // 4g. Space, the night market and the polar sea (0.13).
    mark('places13');
    caption.value = '新地方：太空（地圖左上角的火箭基地）';
    await enterPlace(PlaceKind.space);
    caption.value = '太空裡的東西都輕飄飄地飄著\n星星一閃一閃';
    await seconds(3.5);
    caption.value = '點一下火箭：「3、2、1，發射！」';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.rocket.label)));
    await seconds(5);
    caption.value = '新地方：夜市（就是掛著燈籠的「好吃的店」）';
    await enterPlace(PlaceKind.food);
    caption.value = '燈籠亮亮的，攤位上有雞排、糖葫蘆、刨冰⋯⋯\n金魚在池子裡游';
    await seconds(3.5);
    caption.value = '點一下食物：套圈圈，套中了！';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.friedChicken.label)));
    await seconds(2.8);
    await tap(find.bySemanticsLabel(Strings.resident(Creature.takoyaki.label)));
    await seconds(2.8);
    caption.value = '新地方：極地（地圖右上角的雪山）';
    await enterPlace(PlaceKind.polar);
    caption.value = '下雪了！企鵝搖搖擺擺，有時候用肚子滑\n虎鯨在海裡游';
    await seconds(7);
    mark('places13_end');

    // 4h. The candy house (0.15), on a rainy afternoon: it rains sprinkles.
    mark('candy');
    now = DateTime(2026, 10, 28, 12, 20);
    caption.value = '新地方：糖果館（地圖上面中間的薑餅屋）';
    await enterPlace(PlaceKind.candy);
    caption.value = '糖果王國：甜甜圈和餅乾滾來滾去\n軟糖熊跳跳跳，糖果像氣球一樣飄';
    await seconds(5);
    caption.value = '點一下薑餅人：它會跳起來、說一句話';
    await tap(find.bySemanticsLabel(Strings.resident(Creature.gingerbread.label)));
    await seconds(2.5);
    caption.value = '畫一個新的：12 個甜點可以選';
    await tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.candy.label, residents: Residents.sweets)));
    await until(find.byKey(const ValueKey('creature-donut')));
    await seconds(2.5);
    await tap(find.byKey(const ValueKey('creature-donut')));
    await until(find.byKey(const ValueKey('page')));
    caption.value = '甜甜圈的著色圖：用點點筆加上糖粒';
    await seconds(1);
    await fill([(kidPalette[1], 0.5, 0.78), (kidPalette[7], 0.5, 0.36)]);
    await tap(find.bySemanticsLabel(Strings.crayon));
    await tap(find.bySemanticsLabel(Strings.penDots));
    await tap(find.byKey(ValueKey('swatch-${kidPalette[0]}')));
    final donut = tester.getRect(find.byKey(const ValueKey('page')));
    await stroke([for (var i = 0; i <= 10; i++) donut.topLeft + Offset(donut.width * (0.3 + i * 0.04), donut.height * 0.66 + (i.isEven ? -6 : 6))]);
    caption.value = '畫好了 → 甜甜圈住進糖果館，滾呀滾';
    await tap(find.bySemanticsLabel(Strings.done));
    await until(find.bySemanticsLabel(Strings.resident(Creature.donut.label)));
    await seconds(6);
    mark('candy_end');

    // 4i. The weather (0.16).
    mark('weather');
    now = DateTime(2026, 10, 27, 10, 15);
    caption.value = '新功能：天氣！有時候下雨、颳風、多雲\n（不用網路，也不用定位）';
    await enterPlace(PlaceKind.zoo);
    caption.value = '動物園下雨了：滴答滴答～\n角色也會說「我們來躲雨吧！」';
    await seconds(4);
    await tap(find.bySemanticsLabel(Strings.resident(Creature.lion.label)));
    await seconds(2);
    now = DateTime(2026, 10, 27, 12, 15);
    caption.value = '雨停了，天上出彩虹！';
    await enterPlace(PlaceKind.botanical);
    await seconds(4);
    now = DateTime(2026, 10, 26, 10, 30);
    caption.value = '颳風的時候，葉子和花瓣會被吹起來';
    await enterPlace(PlaceKind.insects);
    await seconds(4);
    now = DateTime(2026, 10, 26, 12, 15);
    mark('weather_end');

    // 4e. The album as one timeline.
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
    mark('replay');
    caption.value = '新功能：明信片上的 ▶，再看一次畫畫的過程\n（縮時重播）';
    await tap(find.bySemanticsLabel(Strings.byPlace));
    await until(find.byKey(ValueKey('replay-${coffee.id}')));
    await seconds(1.5);
    await tap(find.byKey(ValueKey('replay-${coffee.id}')));
    await until(find.byKey(const ValueKey('replay-again')), max: 20);
    caption.value = '畫完了！可以「再看一次」';
    await seconds(2.5);
    await tap(find.bySemanticsLabel(Strings.backToAlbum));
    await until(find.bySemanticsLabel(Strings.backToMap));
    mark('replay_end');
    await seconds(0.5);
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
    mark('stamp_own');
    caption.value = '新功能：印章裡有你畫過的東西\n蓋在新的畫上';
    await tap(find.bySemanticsLabel(Strings.stamp));
    final ownStamp = find.byKey(ValueKey('picture-stamp-${coffee.id}'));
    await until(ownStamp);
    await tester.ensureVisible(ownStamp);
    await seconds(1);
    await tap(ownStamp);
    for (final (dx, dy) in [(0.3, 0.2), (0.72, 0.84)]) {
      await touch(paper.topLeft + Offset(paper.width * dx, paper.height * dy));
      await seconds(0.8);
    }
    await seconds(1.5);
    mark('stamp_own_end');

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

    // 7. Parent mode: save the pictures to the photo album (0.12).
    now = DateTime(2026, 10, 27, 16, 40);
    GoRouter.of(tester.element(find.byKey(const ValueKey('page')))).go('/');
    await until(find.byTooltip(Strings.parentMode));
    await seconds(1);
    mark('album');
    caption.value = '家長模式（要先回答家長關卡的題目）';
    await tap(find.byTooltip(Strings.parentMode));
    await until(find.text(Strings.parentGateTitle));
    await seconds(1.5);
    for (final digit in '${answerParentGate(tester)}'.split('')) {
      await tap(find.byKey(ValueKey('gate-key-$digit')));
    }
    await until(find.text(Strings.dailyLimit));
    caption.value = '每天可以玩多久：15～60 分鐘，或不限';
    await seconds(2.5);
    final keep = find.textContaining('存到相簿（');
    await tester.scrollUntilVisible(keep, 200, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await frames(3);
    caption.value = '存到相簿：不用帳號，換手機作品也不會不見\n（每張只存一次，下次只存新的）';
    await seconds(2);
    await tap(keep);
    await seconds(3);
    mark('album_end');
    mark('share');
    final share = find.byKey(const ValueKey('share-row'));
    await tester.scrollUntilVisible(share, 200, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await frames(3);
    caption.value = '新功能：分享作品（只有家長模式裡有）';
    await seconds(1.5);
    await tap(share);
    await until(find.byKey(ValueKey('share-pick-${coffee.id}')));
    await seconds(1.5);
    await tap(find.byKey(ValueKey('share-pick-${coffee.id}')));
    await until(find.text(Strings.shareNow));
    caption.value = '做成一張明信片圖卡：沒有原本的照片，也沒有名字\n地點可以只寫種類，或不寫';
    await seconds(3);
    await tap(find.text(Strings.sharedPlaceNone));
    await seconds(1.5);
    await tap(find.text(Strings.sharedPlaceKind));
    await seconds(1);
    caption.value = '按「分享」打開手機的分享選單：LINE、IG、存起來';
    await tester.ensureVisible(find.text(Strings.shareNow));
    await frames(2);
    await tap(find.text(Strings.shareNow));
    await seconds(2.5);
    mark('share_end');

    // 8. Time to rest, gently (0.12).
    mark('rest');
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
    await until(find.bySemanticsLabel(Strings.blankPaper));
    final app = ProviderScope.containerOf(tester.element(find.bySemanticsLabel(Strings.blankPaper)));
    Future<void> playTo(Duration at) => tester.runAsync(() => app.read(playTimeProvider.notifier).add(at - app.read(playTimeProvider)!.played));
    caption.value = '每天 30 分鐘：快到時間時，鴿子先提醒';
    await playTo(const Duration(minutes: 28));
    await seconds(4);
    caption.value = '時間到了，正在畫的畫不會被打斷';
    await tap(find.bySemanticsLabel(Strings.blankPaper));
    await until(find.byKey(const ValueKey('page')));
    await seconds(0.5);
    await playTo(const Duration(minutes: 30, seconds: 5));
    await seconds(1);
    final sheet = tester.getRect(find.byKey(const ValueKey('page')));
    await tap(find.byKey(ValueKey('swatch-${kidPalette[0]}')));
    await stroke([for (var i = 0; i <= 12; i++) sheet.topLeft + Offset(sheet.width * (0.2 + i * 0.05), sheet.height * (0.45 + (i.isEven ? -0.05 : 0.05)))]);
    await seconds(2.5);
    caption.value = '畫完寄出，才出現休息畫面';
    await tap(find.bySemanticsLabel(Strings.done));
    final where = find.bySemanticsLabel(RegExp('^${Strings.sendTo('')}'));
    await until(where);
    await seconds(1);
    await tap(where);
    await until(find.byKey(const ValueKey('rest-screen')), max: 20);
    caption.value = '休息畫面：今天畫了幾張，明天再來畫\n家長通過關卡可以再玩 10 分鐘';
    await seconds(6);
    await tap(find.byTooltip(Strings.parentMode).last);
    await until(find.text(Strings.parentGateTitle));
    await seconds(1);
    for (final digit in '${answerParentGate(tester)}'.split('')) {
      await tap(find.byKey(ValueKey('gate-key-$digit')));
    }
    await until(find.text(Strings.tenMoreMinutes));
    await seconds(1.5);
    await tap(find.text(Strings.tenMoreMinutes));
    await seconds(2.5);
    mark('rest_end');
    File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');

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
  for (final (i, c) in _residents.indexed) {
    final art = await service.saveTemplate(childId: child.id, template: c.name, png: File('assets/pages/${c.name}.png').readAsBytesSync());
    final page = await service.load(art.id);
    final regions = page.document.regions;
    final outside = regions.labelAt(0, 0);
    final real = img.decodePng(File('../docs/design/v5/colors/${c.name}.png').readAsBytesSync())!;
    final sum = <int, List<int>>{}, first = <int, int>{};
    for (var i = 0; i < regions.labels.length; i++) {
      final l = regions.labels[i];
      if (l == outside) continue;
      final p = real.getPixel((i % regions.width) * real.width ~/ regions.width, (i ~/ regions.width) * real.height ~/ regions.height);
      final s = sum.putIfAbsent(l, () => [0, 0, 0, 0]);
      s[0] += p.r.toInt();
      s[1] += p.g.toInt();
      s[2] += p.b.toInt();
      s[3]++;
      first.putIfAbsent(l, () => i);
    }
    for (final MapEntry(key: l, value: s) in sum.entries) {
      if (s[3] < 30) continue;
      final color = 0xFF000000 | (s[0] ~/ s[3]) << 16 | (s[1] ~/ s[3]) << 8 | (s[2] ~/ s[3]);
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
