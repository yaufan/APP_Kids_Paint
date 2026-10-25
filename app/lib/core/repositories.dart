import 'package:drift/drift.dart';

import 'db/database.dart';
import 'places.dart';

/// A postcard on the map: a sent artwork and the place it was sent to.
typedef Postcard = ({Artwork artwork, Place place});

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
    return first ?? add(animals.first);
  }
}

class PlaceRepository {
  PlaceRepository(this._db);

  final AppDatabase _db;

  /// The child's first place of [kind] (where postcards go unless a parent
  /// added more), created on first use. Parents may give it a name.
  Future<Place> defaultPlace(int childId, PlaceKind kind) async {
    final existing = await (_db.select(_db.places)
          ..where((p) => p.childId.equals(childId) & p.kind.equals(kind.name))
          ..orderBy([(p) => OrderingTerm(expression: p.id)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing;
    final id = await _db.into(_db.places).insert(PlacesCompanion.insert(childId: childId, kind: kind.name));
    return (_db.select(_db.places)..where((p) => p.id.equals(id))).getSingle();
  }

  /// A named place parents add, e.g. a second park.
  Future<Place> addNamed(int childId, PlaceKind kind, String label) async {
    final id = await _db
        .into(_db.places)
        .insert(PlacesCompanion.insert(childId: childId, kind: kind.name, label: Value(label)));
    return (_db.select(_db.places)..where((p) => p.id.equals(id))).getSingle();
  }

  Stream<List<Place>> watchForChild(int childId) => (_db.select(_db.places)
        ..where((p) => p.childId.equals(childId))
        ..orderBy([(p) => OrderingTerm(expression: p.id)]))
      .watch();

  Future<void> rename(int id, String? label) => (_db.update(_db.places)..where((p) => p.id.equals(id)))
      .write(PlacesCompanion(label: Value(label?.trim().isEmpty ?? true ? null : label!.trim())));
}

class ArtworkRepository {
  ArtworkRepository(this._db);

  final AppDatabase _db;

  Future<Artwork> create({
    required int childId,
    required String style,
    required String detail,
    required String folder,
    String? template,
    int? placeId,
  }) async {
    final id = await _db.into(_db.artworks).insert(ArtworksCompanion.insert(
          childId: childId,
          style: style,
          detail: detail,
          folder: folder,
          template: Value(template),
          placeId: Value(placeId),
        ));
    return get(id);
  }

  /// Whether the child has started a page from [template] since [since]:
  /// once they have, Gugu stops bringing that festival's letter.
  Stream<bool> watchHasTemplate(int childId, String template, DateTime since) => (_db.select(_db.artworks)
        ..where((a) =>
            a.childId.equals(childId) & a.template.equals(template) & a.createdAt.isBiggerOrEqualValue(since))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);

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

  /// Puts the postcard on the map at [placeId].
  Future<void> send(int id, int placeId) {
    final now = DateTime.now();
    return (_db.update(_db.artworks)..where((a) => a.id.equals(id))).write(ArtworksCompanion(
      placeId: Value(placeId),
      sentAt: Value(now),
      updatedAt: Value(now),
      isCompleted: const Value(true),
    ));
  }

  /// A child's postcards on the map with their places, newest first.
  Stream<List<Postcard>> watchPostcards(int childId) {
    final query = _db.select(_db.artworks).join([innerJoin(_db.places, _db.places.id.equalsExp(_db.artworks.placeId))])
      ..where(_db.artworks.childId.equals(childId) & _db.artworks.sentAt.isNotNull())
      ..orderBy([OrderingTerm.desc(_db.artworks.sentAt), OrderingTerm.desc(_db.artworks.id)]);
    return query.watch().map((rows) => [
          for (final r in rows) (artwork: r.readTable(_db.artworks), place: r.readTable(_db.places)),
        ]);
  }

  /// Kinds of places to offer first when sending: the last one, then the
  /// most used, then home and the usual everyday places.
  Future<List<PlaceKind>> suggestedKinds(int childId, {int count = 4}) async {
    final rows = await (_db.select(_db.artworks).join([innerJoin(_db.places, _db.places.id.equalsExp(_db.artworks.placeId))])
          ..where(_db.artworks.childId.equals(childId) & _db.artworks.sentAt.isNotNull())
          ..orderBy([OrderingTerm.desc(_db.artworks.sentAt), OrderingTerm.desc(_db.artworks.id)]))
        .get();
    final kinds = [for (final r in rows) PlaceKind.byName(r.readTable(_db.places).kind)];
    final uses = <PlaceKind, int>{};
    for (final k in kinds) {
      uses[k] = (uses[k] ?? 0) + 1;
    }
    final byUse = uses.keys.toList()..sort((a, b) => uses[b]!.compareTo(uses[a]!));
    final out = <PlaceKind>[];
    for (final k in [if (kinds.isNotEmpty) kinds.first, ...byUse, PlaceKind.home, PlaceKind.park, PlaceKind.school, PlaceKind.grandma]) {
      if (!out.contains(k)) out.add(k);
    }
    return out.take(count).toList();
  }
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
