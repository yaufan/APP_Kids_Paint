import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lineart/line_art.dart';
import '../features/lineart/teed_engine.dart';
import 'artwork_service.dart';
import 'creatures.dart';
import 'db/database.dart';
import 'festivals.dart';
import 'places.dart';
import 'repositories.dart';
import 'storage/artwork_store.dart';
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

/// The voice to speak with: the phone's, or none if turned off.
final voiceProvider = Provider<Voice>((ref) => ref.watch(voiceOnProvider) ? ref.watch(systemVoiceProvider) : const SilentVoice());
