import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/creatures.dart';
import '../../core/db/database.dart';
import '../../core/festivals.dart';
import '../../core/providers.dart';

/// Parent mode: coloring pages printed on real paper (0.18), A4, through
/// the phone's print dialog (or saved as a PDF). The app's own pages, and
/// the ones made from the family's photos.
class PrintScreen extends ConsumerStatefulWidget {
  const PrintScreen({super.key});

  /// At most this many at once.
  static const most = 12;

  @override
  ConsumerState<PrintScreen> createState() => _PrintScreenState();
}

/// One page to print: a built-in one by name, or one made from a photo.
typedef _Page = ({String? asset, Artwork? artwork});

class _PrintScreenState extends ConsumerState<PrintScreen> {
  final _chosen = <String>[];
  bool _printing = false;

  static String _key(_Page p) => p.asset ?? 'own-${p.artwork!.id}';

  void _toggle(_Page p) => setState(() {
        final key = _key(p);
        if (!_chosen.remove(key) && _chosen.length < PrintScreen.most) _chosen.add(key);
      });

  Future<void> _print(List<_Page> all) async {
    setState(() => _printing = true);
    try {
      final store = ref.read(artworkStoreProvider);
      final pages = [
        for (final key in _chosen)
          for (final p in all)
            if (_key(p) == key)
              p.asset != null
                  ? (await rootBundle.load(Art.page(p.asset!))).buffer.asUint8List()
                  : await store.open(p.artwork!.folder).lines.readAsBytes(),
      ];
      await ref.read(printerProvider).printPages(pages, name: Strings.printName);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.printFailed)));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(currentChildProvider).value;
    final artworks = child == null
        ? const <Artwork>[]
        : ref.watch(artworksProvider((childId: child.id, favoritesOnly: false))).value ?? const <Artwork>[];
    final store = ref.watch(artworkStoreProvider);
    final own = [for (final a in artworks) if (const {'realistic', 'cute'}.contains(a.style)) (asset: null, artwork: a)];
    final sections = <(String, List<_Page>)>[
      if (own.isNotEmpty) (Strings.printOwn, own),
      (Strings.printFestivals, [for (final f in Festival.values) if (f.hasPage) (asset: f.name, artwork: null)]),
      for (final h in Habitat.values) (h.label, [for (final c in h.creatures) (asset: c.name, artwork: null)]),
    ];
    final all = [for (final (_, pages) in sections) ...pages];
    final columns = (MediaQuery.sizeOf(context).width / 110).floor().clamp(3, 8);

    Widget tile(_Page p) {
      final on = _chosen.contains(_key(p));
      final label = p.asset == null
          ? Strings.printOwn
          : Creature.byName(p.asset)?.label ?? Festival.values.firstWhere((f) => f.name == p.asset).label;
      return Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('print-${_key(p)}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggle(p),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? KidColors.skyDark : Colors.white, width: 3),
            ),
            child: Stack(fit: StackFit.expand, children: [
              p.asset != null
                  ? Image.asset(Art.page(p.asset!), fit: BoxFit.contain, cacheWidth: 200)
                  : Image.file(store.open(p.artwork!.folder).lines, fit: BoxFit.contain, cacheWidth: 200,
                      errorBuilder: (_, _, _) => const SizedBox.shrink()),
              if (on)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: KidColors.skyDark, shape: BoxShape.circle),
                    child: const KidIcon('check', size: 14, color: Colors.white),
                  ),
                ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KidColors.parentBg,
      appBar: AppBar(
        backgroundColor: KidColors.parentBg,
        title: const Text(Strings.printTitle, style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: CustomScrollView(slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
          sliver: SliverToBoxAdapter(child: Text(Strings.printHint, style: TextStyle(fontSize: 15, color: KidColors.inkSoft, height: 1.4))),
        ),
        for (final (title, pages) in sections) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            sliver: SliverToBoxAdapter(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: columns,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3 / 4,
              children: [for (final p in pages) tile(p)],
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey('print-now'),
            onPressed: _chosen.isEmpty || _printing ? null : () => _print(all),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: KidColors.skyDark),
            icon: const KidIcon('printer', size: 22, color: Colors.white),
            label: Text(Strings.printNow(_chosen.length), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
