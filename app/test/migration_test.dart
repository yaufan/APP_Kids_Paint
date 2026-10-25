import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/repositories.dart';

/// The schema version 1 shipped with (avatars as emoji, places with a
/// coarse location that was never written).
const v1Schema = r'''
CREATE TABLE "children" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "avatar" TEXT NOT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "places" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "child_id" INTEGER NOT NULL REFERENCES children (id), "type" TEXT NOT NULL, "label" TEXT NULL, "district" TEXT NULL, "geohash6" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "artworks" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "child_id" INTEGER NOT NULL REFERENCES children (id), "place_id" INTEGER NULL REFERENCES places (id), "style" TEXT NOT NULL, "detail" TEXT NOT NULL, "folder" TEXT NOT NULL UNIQUE, "tags" TEXT NOT NULL DEFAULT '', "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), "is_completed" INTEGER NOT NULL DEFAULT 0 CHECK ("is_completed" IN (0, 1)), "shared_at" INTEGER NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
''';

/// Version 2: the town's places, postcards with the time they were sent.
const v2Schema = r'''
CREATE TABLE "children" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "avatar" TEXT NOT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "places" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "child_id" INTEGER NOT NULL REFERENCES children (id), "kind" TEXT NOT NULL, "label" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "artworks" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "child_id" INTEGER NOT NULL REFERENCES children (id), "place_id" INTEGER NULL REFERENCES places (id), "style" TEXT NOT NULL, "detail" TEXT NOT NULL, "folder" TEXT NOT NULL UNIQUE, "tags" TEXT NOT NULL DEFAULT '', "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK ("is_favorite" IN (0, 1)), "is_completed" INTEGER NOT NULL DEFAULT 0 CHECK ("is_completed" IN (0, 1)), "sent_at" INTEGER NULL, "shared_at" INTEGER NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)));
CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
''';

void main() {
  test('a version 2 database upgrades: artworks get a template column, postcards stay', () async {
    final dir = Directory.systemTemp.createTempSync('kp_migration2');
    addTearDown(() => dir.deleteSync(recursive: true));
    final db = AppDatabase(NativeDatabase(File('${dir.path}/db.sqlite'), setup: (raw) {
      if (raw.userVersion != 0) return;
      raw.execute(v2Schema);
      raw.execute("INSERT INTO children (avatar) VALUES ('cat')");
      raw.execute("INSERT INTO places (child_id, kind) VALUES (1, 'park')");
      raw.execute("INSERT INTO artworks (child_id, place_id, style, detail, folder, is_completed, sent_at) VALUES (1, 1, 'cute', 'simple', 'a', 1, 1761300000)");
      raw.userVersion = 2;
    }));
    addTearDown(db.close);
    final postcards = await ArtworkRepository(db).watchPostcards(1).first;
    expect(postcards.map((p) => (p.artwork.folder, p.artwork.template, p.place.kind)), [('a', null, 'park')]);
  });

  test('a version 1 database upgrades: avatars become animals, old pictures move home', () async {
    final dir = Directory.systemTemp.createTempSync('kp_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    // Build the old database right as it is opened, before drift migrates it.
    final db = AppDatabase(NativeDatabase(file, setup: (raw) {
      if (raw.userVersion != 0) return;
      raw.execute(v1Schema);
      raw.execute("INSERT INTO children (avatar) VALUES ('🐰')");
      raw.execute("INSERT INTO artworks (child_id, style, detail, folder, is_completed) VALUES (1, 'realistic', 'simple', 'done', 1)");
      raw.execute("INSERT INTO artworks (child_id, style, detail, folder, is_completed) VALUES (1, 'realistic', 'simple', 'draft', 0)");
      raw.userVersion = 1;
    }));
    addTearDown(db.close);
    final kids = await ChildRepository(db).watchAll().first;
    expect(kids.single.avatar, 'rabbit');
    final postcards = await ArtworkRepository(db).watchPostcards(kids.single.id).first;
    expect(postcards.map((p) => (p.artwork.folder, p.place.kind)), [('done', 'home')]);
    final drafts = await ArtworkRepository(db).watchForChild(kids.single.id).first;
    expect(drafts.where((a) => a.sentAt == null).map((a) => a.folder), ['draft']);
  });
}
