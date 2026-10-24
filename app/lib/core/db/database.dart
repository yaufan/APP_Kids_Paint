import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// A child using the app. Siblings share a device, so there is no login:
/// each child just picks their own animal avatar.
@DataClassName('Child')
class Children extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get avatar => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Where artworks were made. Only a coarse location is ever stored: the
/// district and a ~1 km geohash, never exact coordinates.
class Places extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();

  /// auto | home | school | park | grandparents | custom
  TextColumn get type => text()();
  TextColumn get label => text().nullable()();
  TextColumn get district => text().nullable()();
  TextColumn get geohash6 => text().withLength(min: 6, max: 6).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Artworks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get childId => integer().references(Children, #id)();
  IntColumn get placeId => integer().nullable().references(Places, #id)();

  /// realistic | cute | template
  TextColumn get style => text()();

  /// simple | normal | detailed
  TextColumn get detail => text()();

  /// Folder holding this artwork's files, relative to the artwork store.
  TextColumn get folder => text().unique()();

  /// Comma-separated categories from on-device image labeling.
  TextColumn get tags => text().withDefault(const Constant(''))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get sharedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
