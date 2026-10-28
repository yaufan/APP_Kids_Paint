import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/repositories.dart';

void main() {
  late AppDatabase db;
  late ChildRepository children;
  late ArtworkRepository artworks;
  late SettingsRepository settings;
  late PlaceRepository places;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    children = ChildRepository(db);
    artworks = ArtworkRepository(db);
    settings = SettingsRepository(db);
    places = PlaceRepository(db);
  });

  tearDown(() => db.close());

  test('a default child is created on first launch, only once', () async {
    final first = await children.ensureDefault();
    final again = await children.ensureDefault();
    expect(again.id, first.id);
    expect(first.avatar, animals.first);
  });

  test('artworks are listed per child, newest first, with a favorites filter', () async {
    final kid = await children.ensureDefault();
    final sibling = await children.add('rabbit');
    final a = await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'a');
    final b = await artworks.create(childId: kid.id, style: 'cute', detail: 'simple', folder: 'b');
    await artworks.create(childId: sibling.id, style: 'cute', detail: 'simple', folder: 'c');

    expect((await artworks.watchForChild(kid.id).first).map((x) => x.id), [b.id, a.id]);

    await artworks.toggleFavorite(a.id);
    final favorites = await artworks.watchForChild(kid.id, favoritesOnly: true).first;
    expect(favorites.map((x) => x.id), [a.id]);
  });

  test('each kind has one default place per child', () async {
    final kid = await children.ensureDefault();
    final sibling = await children.add('cat');
    final park = await places.defaultPlace(kid.id, PlaceKind.park);
    expect((await places.defaultPlace(kid.id, PlaceKind.park)).id, park.id);
    expect((await places.defaultPlace(sibling.id, PlaceKind.park)).id, isNot(park.id));
    final named = await places.addNamed(kid.id, PlaceKind.park, '青年公園');
    expect(named.id, isNot(park.id));
    expect((await places.defaultPlace(kid.id, PlaceKind.park)).id, park.id);
    await places.rename(named.id, '  ');
    expect((await places.watchForChild(kid.id).first).firstWhere((p) => p.id == named.id).label, isNull);
  });

  test('sent postcards are on the map with their place; drafts are not', () async {
    final kid = await children.ensureDefault();
    final park = await places.defaultPlace(kid.id, PlaceKind.park);
    final home = await places.defaultPlace(kid.id, PlaceKind.home);
    final a = await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'a');
    final b = await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'b');
    await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'draft');
    expect(await artworks.suggestedKinds(kid.id), [PlaceKind.home, PlaceKind.park, PlaceKind.school, PlaceKind.grandma]);

    await artworks.send(a.id, park.id);
    await artworks.send(b.id, home.id);
    final postcards = await artworks.watchPostcards(kid.id).first;
    expect(postcards.map((p) => (p.artwork.id, p.place.kind)), [(b.id, 'home'), (a.id, 'park')]);
    expect(postcards.every((p) => p.artwork.isCompleted && p.artwork.sentAt != null), isTrue);
    // The last place comes first.
    expect((await artworks.suggestedKinds(kid.id)).first, PlaceKind.home);
  });

  test('creatures that moved into the zoo do not crowd the places to send to', () async {
    final kid = await children.ensureDefault();
    final park = await places.defaultPlace(kid.id, PlaceKind.park);
    final zoo = await places.defaultPlace(kid.id, PlaceKind.zoo);
    final dinoPark = await places.defaultPlace(kid.id, PlaceKind.dinoPark);
    final photo = await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'a');
    await artworks.send(photo.id, park.id);
    for (final (i, (template, place)) in [('lion', zoo), ('panda', zoo), ('trex', dinoPark)].indexed) {
      final c = await artworks.create(childId: kid.id, style: 'cute', detail: 'simple', folder: 'c$i', template: template);
      await artworks.send(c.id, place.id);
    }
    final kinds = await artworks.suggestedKinds(kid.id);
    expect(kinds.first, PlaceKind.park);
    expect(kinds, isNot(contains(PlaceKind.zoo)));
    expect(kinds, isNot(contains(PlaceKind.dinoPark)));
  });

  test("today's count is the child's pictures started and finished today, not old ones opened again", () async {
    final child = await children.ensureDefault();
    final sibling = await children.add('cat');
    final start = DateTime.now().subtract(const Duration(minutes: 5));
    Future<Artwork> finished(int childId) async {
      final art = await artworks.create(childId: childId, style: 'blank', detail: 'simple', folder: 'f${DateTime.now().microsecondsSinceEpoch}');
      await artworks.touch(art.id, completed: true);
      return art;
    }

    final old = await finished(child.id);
    await (db.update(db.artworks)..where((a) => a.id.equals(old.id))).write(ArtworksCompanion(createdAt: Value(DateTime(2026, 1, 2))));
    await artworks.touch(old.id, completed: true); // opened again today
    await finished(child.id);
    await finished(sibling.id);
    expect(await artworks.finishedSince(child.id, start), 1);
  });

  test('sounds are on until a parent turns them off', () async {
    expect(await settings.soundOn(), isTrue);
    await settings.setSoundOn(false);
    expect(await settings.soundOn(), isFalse);
  });

  test('daily limit has a default and can be changed', () async {
    expect(await settings.dailyMinutes(), SettingsRepository.defaultDailyMinutes);
    await settings.setDailyMinutes(45);
    expect(await settings.dailyMinutes(), 45);
  });

  test('delete everything removes children and artworks', () async {
    final kid = await children.ensureDefault();
    await artworks.create(childId: kid.id, style: 'cute', detail: 'simple', folder: 'x');
    await settings.deleteEverything();
    expect(await children.watchAll().first, isEmpty);
    expect(await artworks.watchForChild(kid.id).first, isEmpty);
  });
}
