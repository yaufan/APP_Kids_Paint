import 'package:drift/drift.dart';

import 'creatures.dart';
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

  /// Names the child's town and/or picks their animal.
  Future<void> update(int id, {String? name, String? avatar}) =>
      (_db.update(_db.children)..where((c) => c.id.equals(id))).write(ChildrenCompanion(
        name: name == null ? const Value.absent() : Value(name.trim().isEmpty ? null : name.trim()),
        avatar: avatar == null ? const Value.absent() : Value(avatar),
      ));

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

  Future<Place?> get(int? id) =>
      id == null ? Future.value() : (_db.select(_db.places)..where((p) => p.id.equals(id))).getSingleOrNull();

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

  /// The child's finished pages made from any of [templates] (a scene's
  /// creatures), newest first.
  Stream<List<Artwork>> watchMadeFrom(int childId, Iterable<String> templates, {int limit = 12}) => (_db.select(_db.artworks)
        ..where((a) => a.childId.equals(childId) & a.template.isIn(templates) & a.sentAt.isNotNull())
        ..orderBy([(a) => OrderingTerm.desc(a.sentAt), (a) => OrderingTerm.desc(a.id)])
        ..limit(limit))
      .watch();

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

  /// The longest note a parent can write on a postcard's back.
  static const noteLength = 60;

  /// What the child said about it, on its back (blank: none).
  Future<void> setNote(int id, String? note) {
    final text = note?.trim() ?? '';
    final kept = text.isEmpty ? null : String.fromCharCodes(text.runes.take(noteLength));
    return (_db.update(_db.artworks)..where((a) => a.id.equals(id))).write(ArtworksCompanion(note: Value(kept)));
  }

  Future<void> touch(int id, {bool? completed}) =>
      (_db.update(_db.artworks)..where((a) => a.id.equals(id))).write(ArtworksCompanion(
        updatedAt: Value(DateTime.now()),
        isCompleted: completed == null ? const Value.absent() : Value(completed),
      ));

  Future<void> delete(int id) => (_db.delete(_db.artworks)..where((a) => a.id.equals(id))).go();

  /// Every child's finished pictures, oldest first.
  Future<List<Artwork>> finished() => (_db.select(_db.artworks)
        ..where((a) => a.isCompleted.equals(true))
        ..orderBy([(a) => OrderingTerm.asc(a.id)]))
      .get();

  /// How many pictures [childId] started since [since] and finished (today,
  /// on the rest screen). Opening an old one again does not count.
  Future<int> finishedSince(int childId, DateTime since) async => (await (_db.select(_db.artworks)
            ..where((a) => a.childId.equals(childId) & a.isCompleted.equals(true) & a.createdAt.isBiggerOrEqualValue(since)))
          .get())
      .length;

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
  /// most used, then home and the usual everyday places. Creatures that
  /// moved into the zoo or the aquarium do not count: they say nothing
  /// about where the child goes.
  Future<List<PlaceKind>> suggestedKinds(int childId, {int count = 4}) async {
    final creatures = [for (final c in Creature.values) c.name];
    final rows = await (_db.select(_db.artworks).join([innerJoin(_db.places, _db.places.id.equalsExp(_db.artworks.placeId))])
          ..where(_db.artworks.childId.equals(childId) &
              _db.artworks.sentAt.isNotNull() &
              (_db.artworks.template.isNull() | _db.artworks.template.isNotIn(creatures)))
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

  /// The daily limit that means no limit.
  static const noLimit = 0;

  Future<int> dailyMinutes() async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(dailyMinutesKey)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? defaultDailyMinutes;
  }

  Future<void> setDailyMinutes(int minutes) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(Setting(key: dailyMinutesKey, value: '$minutes'));

  static const voiceKey = 'voice';

  /// Whether the creatures' lines are read out loud (on unless a parent turned it off).
  Future<bool> voiceOn() async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(voiceKey))).getSingleOrNull();
    return row?.value != 'off';
  }

  Future<void> setVoiceOn(bool on) =>
      _db.into(_db.settings).insertOnConflictUpdate(Setting(key: voiceKey, value: on ? 'on' : 'off'));

  Future<String?> _value(String key) async =>
      (await (_db.select(_db.settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> _put(String key, String value) => _db.into(_db.settings).insertOnConflictUpdate(Setting(key: key, value: value));

  static const soundKey = 'sound';

  /// Whether the sound effects and background sounds play (0.16; on unless turned off).
  Future<bool> soundOn() async => await _value(soundKey) != 'off';

  Future<void> setSoundOn(bool on) => _put(soundKey, on ? 'on' : 'off');

  static const exportedKey = 'exported_up_to';

  /// The newest picture already saved to the photo album (an artwork id).
  static const exportedIdsKey = 'exported_ids';

  /// The pictures already saved to the photo album: their ids, and before
  /// 0.15.1 only the highest id saved ([upTo]; everything up to it counts).
  Future<({int upTo, Set<int> ids})> exported() async => (
        upTo: int.tryParse(await _value(exportedKey) ?? '') ?? 0,
        ids: {for (final s in (await _value(exportedIdsKey) ?? '').split(',')) ?int.tryParse(s)},
      );

  Future<void> addExported(int id) async => _put(exportedIdsKey, ({...(await exported()).ids, id}).join(','));

  static const playKey = 'play_today';

  /// What was played on [day] (`2026-10-27`): seconds on screen and minutes
  /// a parent added. Another day's record counts as nothing.
  Future<({int seconds, int extraMinutes})> playOn(String day) async {
    final parts = (await _value(playKey) ?? '').split(' ');
    if (parts.length != 3 || parts[0] != day) return (seconds: 0, extraMinutes: 0);
    return (seconds: int.tryParse(parts[1]) ?? 0, extraMinutes: int.tryParse(parts[2]) ?? 0);
  }

  Future<void> setPlayOn(String day, {required int seconds, required int extraMinutes}) =>
      _put(playKey, '$day $seconds $extraMinutes');

  static const welcomedKey = 'welcomed';

  /// Whether the town has been named on the welcome screen (first launch,
  /// or again after a parent deleted everything).
  Future<bool> welcomed() async {
    final row = await (_db.select(_db.settings)..where((s) => s.key.equals(welcomedKey))).getSingleOrNull();
    return row != null;
  }

  Future<void> setWelcomed() => _db.into(_db.settings).insertOnConflictUpdate(const Setting(key: welcomedKey, value: '1'));

  /// Parent mode "delete all data": every row, children included.
  Future<void> deleteEverything() => _db.transaction(() async {
        await _db.delete(_db.artworks).go();
        await _db.delete(_db.places).go();
        await _db.delete(_db.children).go();
        await _db.delete(_db.settings).go();
      });
}

/// What a child's town is called before 的小鎮: the name they gave it, or
/// their animal's name until they do.
extension TownName on Child {
  String get townName {
    final given = name?.trim() ?? '';
    return given.isNotEmpty ? given : animalNames[avatar] ?? '';
  }
}
