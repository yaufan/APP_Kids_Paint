import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lineart/line_art.dart';
import '../features/lineart/simple_engine.dart';
import 'artwork_service.dart';
import 'db/database.dart';
import 'repositories.dart';
import 'storage/artwork_store.dart';

/// Overridden in `main.dart` (and in tests) with the real instances.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('database'));
final artworkStoreProvider = Provider<ArtworkStore>((ref) => throw UnimplementedError('artwork store'));

final childRepositoryProvider = Provider((ref) => ChildRepository(ref.watch(databaseProvider)));
final artworkRepositoryProvider = Provider((ref) => ArtworkRepository(ref.watch(databaseProvider)));
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final artworkServiceProvider = Provider(
  (ref) => ArtworkService(ref.watch(artworkRepositoryProvider), ref.watch(artworkStoreProvider)),
);

/// Swap this for the DexiNed engine once it is ported.
final lineArtEngineProvider = Provider<LineArtEngine>((ref) => const SimpleLineArtEngine());

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
