import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lineart/line_art.dart';
import 'album_export.dart';
import '../features/lineart/teed_engine.dart';
import 'artwork_service.dart';
import 'creatures.dart';
import 'db/database.dart';
import 'festivals.dart';
import 'places.dart';
import 'repositories.dart';
import 'printing.dart';
import 'sharing.dart';
import 'storage/artwork_store.dart';
import 'sounds.dart';
import 'voice.dart';

/// The time. Tests set it to see the town at night or on a festival.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Overridden in `main.dart` (and in tests) with the real instances.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('database'));
final artworkStoreProvider = Provider<ArtworkStore>((ref) => throw UnimplementedError('artwork store'));

final childRepositoryProvider = Provider((ref) => ChildRepository(ref.watch(databaseProvider)));
final artworkRepositoryProvider = Provider((ref) => ArtworkRepository(ref.watch(databaseProvider)));
final placeRepositoryProvider = Provider((ref) => PlaceRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final artworkServiceProvider = Provider(
  (ref) => ArtworkService(ref.watch(artworkRepositoryProvider), ref.watch(artworkStoreProvider)),
);

/// The phone's share sheet; tests use a pretend one.
final sharerProvider = Provider<Sharer>((ref) => SystemSharer());

/// The phone's print dialog; tests use recording ones.
final printerProvider = Provider<PagePrinter>((ref) => SystemPrinter());

/// The phone's photo album; tests use a pretend one.
final photoAlbumProvider = Provider<PhotoAlbum>((ref) => SystemPhotoAlbum());
final albumExportProvider = Provider((ref) => AlbumExport(ref.watch(artworkRepositoryProvider),
    ref.watch(settingsRepositoryProvider), ref.watch(artworkStoreProvider), ref.watch(photoAlbumProvider)));

/// Photo to coloring page, on the phone: TEED finds the outlines.
final lineArtEngineProvider = Provider<LineArtEngine>((ref) => TeedLineArtEngine(() async {
      final data = await rootBundle.load('assets/models/teed.bin');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }));

final childrenProvider = StreamProvider<List<Child>>((ref) => ref.watch(childRepositoryProvider).watchAll());

/// The child currently using the app; falls back to the first child.
final currentChildIdProvider = NotifierProvider<CurrentChildId, int?>(CurrentChildId.new);

class CurrentChildId extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int id) => state = id;
}

final currentChildProvider = FutureProvider<Child>((ref) async {
  final repo = ref.watch(childRepositoryProvider);
  final id = ref.watch(currentChildIdProvider);
  final children = ref.watch(childrenProvider.future);
  final fallback = await repo.ensureDefault();
  return (await children).where((c) => c.id == id).firstOrNull ?? fallback;
});

final artworksProvider = StreamProvider.family<List<Artwork>, ({int childId, bool favoritesOnly})>(
  (ref, q) => ref.watch(artworkRepositoryProvider).watchForChild(q.childId, favoritesOnly: q.favoritesOnly),
);

/// The child's postcards on the map, newest first.
final postcardsProvider = StreamProvider.family<List<Postcard>, int>(
  (ref, childId) => ref.watch(artworkRepositoryProvider).watchPostcards(childId),
);

final placesProvider = StreamProvider.family<List<Place>, int>(
  (ref, childId) => ref.watch(placeRepositoryProvider).watchForChild(childId),
);

/// A place picked before taking the photo ("draw here again"); sending
/// offers it first.
final preferredPlaceProvider = NotifierProvider<PreferredPlace, PlaceKind?>(PreferredPlace.new);

class PreferredPlace extends Notifier<PlaceKind?> {
  @override
  PlaceKind? build() => null;

  void choose(PlaceKind? kind) => state = kind;
}

/// Whether a child already opened this year's letter for a festival.
final festivalPageOpenedProvider = StreamProvider.family<bool, ({int childId, Festival festival, DateTime since})>(
  (ref, q) => ref.watch(artworkRepositoryProvider).watchHasTemplate(q.childId, q.festival.name, q.since),
);

/// The creatures a child colored for a scene, newest first: they live there.
final residentsProvider = StreamProvider.family<List<Artwork>, ({int childId, Habitat habitat})>(
  (ref, q) => ref.watch(artworkRepositoryProvider).watchMadeFrom(q.childId, [for (final c in q.habitat.creatures) c.name]),
);

/// Who comes to the shop to buy: the child's own animals that walk (from
/// the zoo, the dinosaur park and the insect museum), newest first.
final shopCustomersProvider = StreamProvider.family<List<Artwork>, int>(
  (ref, childId) => ref.watch(artworkRepositoryProvider).watchMadeFrom(childId, [
    for (final c in Creature.values)
      if ({Habitat.zoo, Habitat.dinoPark, Habitat.insects}.contains(c.habitat) && {Motion.walk, Motion.hop, Motion.crawl}.contains(c.motion)) c.name,
  ]),
);

/// The child's own pictures that live in the town (0.17): at each kind of
/// place, the two newest sent there that are not a scene's creatures, by
/// their cut-outs (made now for pictures from before there were any).
final townFolksProvider = FutureProvider.family<Map<PlaceKind, List<Artwork>>, int>((ref, childId) async {
  final postcards = await ref.watch(postcardsProvider(childId).future);
  final service = ref.watch(artworkServiceProvider);
  final folks = <PlaceKind, List<Artwork>>{};
  for (final p in postcards) {
    if (Creature.byName(p.artwork.template) != null) continue;
    final here = folks.putIfAbsent(PlaceKind.byName(p.place.kind), () => []);
    if (here.length >= townFolksPerPlace) continue;
    try {
      if (await service.ensureSprite(p.artwork)) here.add(p.artwork);
    } catch (_) {
      // A picture whose files are damaged just stays off the map.
    }
  }
  return folks;
});

const townFolksPerPlace = 2;

/// The child's own pictures to press onto pages as stamps (0.17): the
/// newest sent ones that have a cut-out, creatures and photos alike.
final stampPicturesProvider = FutureProvider.family<List<Artwork>, int>((ref, childId) async {
  final postcards = await ref.watch(postcardsProvider(childId).future);
  final service = ref.watch(artworkServiceProvider);
  final out = <Artwork>[];
  for (final p in postcards) {
    if (out.length >= stampPictureCount) break;
    try {
      if (await service.ensureSprite(p.artwork)) out.add(p.artwork);
    } catch (_) {
      // Damaged files: not offered.
    }
  }
  return out;
});

const stampPictureCount = 8;

/// The phone's speech engine; tests use a silent one.
final systemVoiceProvider = Provider<Voice>((ref) => SystemVoice());

/// Whether the town has been named yet (else the welcome screen shows).
final welcomedProvider = FutureProvider<bool>((ref) => ref.watch(settingsRepositoryProvider).welcomed());

/// Whether parents left the creatures' voices on.
final voiceOnProvider = NotifierProvider<VoiceOn, bool>(VoiceOn.new);

class VoiceOn extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(settingsRepositoryProvider).voiceOn().then((on) {
      if (ref.mounted) state = on;
    });
    return true;
  }

  Future<void> set(bool on) async {
    state = on;
    await ref.read(settingsRepositoryProvider).setVoiceOn(on);
  }
}

/// The phone's audio for sounds; tests use silent ones.
final systemSoundsProvider = Provider<Sounds>((ref) {
  final sounds = SystemSounds();
  ref.onDispose(sounds.dispose);
  return sounds;
});

/// Whether parents left the sounds on.
final soundOnProvider = NotifierProvider<SoundOn, bool>(SoundOn.new);

class SoundOn extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(settingsRepositoryProvider).soundOn().then((on) {
      if (ref.mounted) state = on;
    });
    return true;
  }

  Future<void> set(bool on) async {
    state = on;
    await ref.read(settingsRepositoryProvider).setSoundOn(on);
  }
}

/// The sounds to play with, quiet when parents turned them off.
final soundsProvider = Provider<Sounds>((ref) {
  final sounds = ref.watch(systemSoundsProvider);
  sounds.enabled = ref.watch(soundOnProvider);
  return sounds;
});

/// The voice to speak with: the phone's, or none if turned off.
final voiceProvider = Provider<Voice>((ref) => ref.watch(voiceOnProvider) ? ref.watch(systemVoiceProvider) : const SilentVoice());
