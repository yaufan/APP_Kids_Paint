import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../places.dart';

part 'database.g.dart';

/// A child using the app. Siblings share a device, so there is no login:
/// each child just picks their own animal avatar.
@DataClassName('Child')
class Children extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// One of [animals].
  TextColumn get avatar => text()();

  /// What the town is called: the name in front of 的小鎮. Null until the child (with a
  /// parent's help) names it; the avatar's name stands in until then.
  TextColumn get name => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A place in a child's town. Children pick it when they send a postcard;
/// the app never uses location (docs/town-map.md).
class Places extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();

  /// A [PlaceKind] name.
  TextColumn get kind => text()();

  /// A parent's name for it, e.g. "大安森林公園"; null for the kind's default.
  TextColumn get label => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Artworks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();
  IntColumn get placeId => integer().nullable().references(Places, #id)();

  /// realistic | cute (from a photo) | template (a built-in page) | blank (empty paper)
  TextColumn get style => text()();

  /// The built-in page a template artwork was made from, e.g. a festival's name.
  TextColumn get template => text().nullable()();

  /// simple | normal | detailed
  TextColumn get detail => text()();

  /// Folder holding this artwork's files, relative to the artwork store.
  TextColumn get folder => text().unique()();

  /// Comma-separated categories from on-device image labeling.
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// When it was sent to its place on the map; null while it is a draft.
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get sharedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// What the child said about it, written on the back by a parent (0.18).
  TextColumn get note => text().nullable()();
}

/// Small key-value store for parent settings (daily time limit, ...).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Children, Places, Artworks, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'kids_paint'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Version 1 never wrote places (they were meant to hold a coarse
            // location); rebuild the table for the town's place kinds.
            await m.deleteTable('places');
            await m.createTable(places);
            await m.addColumn(artworks, artworks.sentAt);
            for (final MapEntry(key: emoji, value: name) in legacyAvatars.entries) {
              await customUpdate('UPDATE children SET avatar = ? WHERE avatar = ?',
                  variables: [Variable(name), Variable(emoji)], updates: {children});
            }
            // Finished pictures from before the town existed live at home.
            await customStatement("INSERT INTO places (child_id, kind) "
                "SELECT DISTINCT child_id, 'home' FROM artworks WHERE is_completed = 1");
            await customStatement('UPDATE artworks SET sent_at = updated_at, place_id = '
                "(SELECT id FROM places p WHERE p.child_id = artworks.child_id AND p.kind = 'home') "
                'WHERE is_completed = 1');
          }
          if (from < 3) {
            await m.addColumn(artworks, artworks.template);
          }
          if (from < 4) {
            await m.addColumn(children, children.name);
            // They already have a town: no first-day welcome (a parent can
            // still name it in the parent page).
            await into(settings).insertOnConflictUpdate(const Setting(key: 'welcomed', value: '1'));
          }
          if (from < 5) {
            await m.addColumn(artworks, artworks.note);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
