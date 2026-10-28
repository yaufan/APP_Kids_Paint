import 'dart:io';

import 'package:gal/gal.dart';

import '../app/strings.dart';
import 'repositories.dart';
import 'storage/artwork_store.dart';

/// The phone's photo album.
abstract class PhotoAlbum {
  /// Asks for permission to add pictures (the system asks once).
  Future<bool> allow();

  Future<void> add(File picture);
}

/// The album through the `gal` plugin: on Android an album named after
/// the app; on iPhone the camera roll, which needs only add-only access.
class SystemPhotoAlbum implements PhotoAlbum {
  @override
  Future<bool> allow() async => await Gal.hasAccess(toAlbum: Platform.isAndroid) || await Gal.requestAccess(toAlbum: Platform.isAndroid);

  @override
  Future<void> add(File picture) => Gal.putImage(picture.path, album: Platform.isAndroid ? Strings.appName : null);
}

/// Saves the finished pictures to the photo album, so they outlive the
/// phone: the app has no account to keep them anywhere else. Each picture
/// is saved once; the next time only newer ones go.
class AlbumExport {
  AlbumExport(this._artworks, this._settings, this._store, this._album);

  final ArtworkRepository _artworks;
  final SettingsRepository _settings;
  final ArtworkStore _store;
  final PhotoAlbum _album;

  /// Finished pictures not in the album yet, oldest first, by id: one
  /// started long ago and finished today is new too.
  Future<List<(int, File)>> _waiting() async {
    final exported = await _settings.exported();
    return [
      for (final art in await _artworks.finished())
        if (art.id > exported.upTo && !exported.ids.contains(art.id) && _store.open(art.folder).colored.existsSync())
          (art.id, _store.open(art.folder).colored),
    ];
  }

  /// How many finished pictures are not in the album yet.
  Future<int> waiting() async => (await _waiting()).length;

  /// Saves them, oldest first, and returns how many; null if the album may
  /// not be used.
  Future<int?> saveNew() async {
    if (!await _album.allow()) return null;
    var saved = 0;
    for (final (id, picture) in await _waiting()) {
      await _album.add(picture);
      await _settings.addExported(id);
      saved++;
    }
    return saved;
  }
}
