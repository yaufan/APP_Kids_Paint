import 'package:drift/drift.dart';

import 'db/database.dart';

/// Animal avatars children pick from; no names or photos of children.
const avatars = ['🐻', '🐰', '🐱', '🐶', '🐼', '🦊', '🐸', '🐧'];

class ChildRepository {
  ChildRepository(this._db);

  final AppDatabase _db;

  Stream<List<Child>> watchAll() =>
      (_db.select(_db.children)..orderBy([(c) => OrderingTerm(expression: c.id)])).watch();

  Future<Child> add(String avatar) async {
    final id = await _db.into(_db.children).insert(ChildrenCompanion.insert(avatar: avatar));
    return (_db.select(_db.children)..where((c) => c.id.equals(id))).getSingle();
  }

  /// The first child, created on first launch so the app works right away.
  Future<Child> ensureDefault() async {
    final first = await (_db.select(_db.children)
          ..orderBy([(c) => OrderingTerm(expression: c.id)])
          ..limit(1))
        .getSingleOrNull();
    return first ?? add(avatars.first);
  }
}

class ArtworkRepository {
  ArtworkRepository(this._db);

  final AppDatabase _db;

  Future<Artwork> create({
    required int childId,
    required String style,
    required String detail,
    required String folder,
    int? placeId,
  }) async {
    final id = await _db.into(_db.artworks).insert(ArtworksCompanion.insert(
          childId: childId,
          style: style,
          detail: detail,
          folder: folder,
          placeId: Value(placeId),
        ));
    return get(id);
  }

  Future<Artwork> get(int id) =>
      (_db.select(_db.artworks)..where((a) => a.id.equals(id))).getSingle();

  /// A child's artworks, newest first.
  Stream<List<Artwork>> watchForChild(int childId, {bool favoritesOnly = false}) {
    final query = _db.select(_db.artworks)
      ..where((a) => a.childId.equals(childId))
      ..orderBy([(a) => OrderingTerm.desc(a.updatedAt), (a) => OrderingTerm.desc(a.id)]);
    if (favoritesOnly) query.where((a) => a.isFavorite.equals(true));
    return query.watch();
  }

  Future<void> toggleFavorite(int id) async {
    final art = await get(id);
    await (_db.update(_db.artworks)..where((a) => a.id.equals(id)))
        .write(ArtworksCompanion(isFavorite: Value(!art.isFavorite)));
  }

  Future<void> touch(int id, {bool? completed}) =>
      (_db.update(_db.artworks)..where((a) => a.id.equals(id))).write(ArtworksCompanion(
        updatedAt: Value(DateTime.now()),
        isCompleted: completed == null ? const Value.absent() : Value(completed),
      ));

  Future<void> delete(int id) => (_db.delete(_db.artworks)..where((a) => a.id.equals(id))).go();
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const dailyMinutesKey = 'daily_minutes';
  static const defaultDailyMinutes = 30;

  Future<int> dailyMinutes() async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(dailyMinutesKey)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? defaultDailyMinutes;
  }

  Future<void> setDailyMinutes(int minutes) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(Setting(key: dailyMinutesKey, value: '$minutes'));

  /// Parent mode "delete all data": every row, children included.
  Future<void> deleteEverything() => _db.transaction(() async {
        await _db.delete(_db.artworks).go();
        await _db.delete(_db.places).go();
        await _db.delete(_db.children).go();
        await _db.delete(_db.settings).go();
      });
}
