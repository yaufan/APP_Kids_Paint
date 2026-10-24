import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/repositories.dart';

void main() {
  late AppDatabase db;
  late ChildRepository children;
  late ArtworkRepository artworks;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    children = ChildRepository(db);
    artworks = ArtworkRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('a default child is created on first launch, only once', () async {
    final first = await children.ensureDefault();
    final again = await children.ensureDefault();
    expect(again.id, first.id);
    expect(first.avatar, avatars.first);
  });

  test('artworks are listed per child, newest first, with a favorites filter', () async {
    final kid = await children.ensureDefault();
    final sibling = await children.add('🐰');
    final a = await artworks.create(childId: kid.id, style: 'realistic', detail: 'simple', folder: 'a');
    final b = await artworks.create(childId: kid.id, style: 'cute', detail: 'simple', folder: 'b');
    await artworks.create(childId: sibling.id, style: 'cute', detail: 'simple', folder: 'c');

    expect((await artworks.watchForChild(kid.id).first).map((x) => x.id), [b.id, a.id]);

    await artworks.toggleFavorite(a.id);
    final favorites = await artworks.watchForChild(kid.id, favoritesOnly: true).first;
    expect(favorites.map((x) => x.id), [a.id]);
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
