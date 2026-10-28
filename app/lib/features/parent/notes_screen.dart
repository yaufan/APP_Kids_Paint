import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';

/// Parent mode: write on a postcard's back what the child said about it
/// (0.18). Small children cannot write yet; a parent writes it down, and
/// the child hears it read out when they turn the postcard over.
class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  Future<void> _write(BuildContext context, WidgetRef ref, Postcard postcard) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KidColors.parentBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => _NoteEditor(postcard: postcard),
    );
    if (note == null) return;
    await ref.read(artworkRepositoryProvider).setNote(postcard.artwork.id, note);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.noteSaved)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(currentChildProvider).value;
    final postcards = child == null ? const <Postcard>[] : ref.watch(postcardsProvider(child.id)).value ?? const [];
    final store = ref.watch(artworkStoreProvider);
    return Scaffold(
      backgroundColor: KidColors.parentBg,
      appBar: AppBar(
        backgroundColor: KidColors.parentBg,
        title: const Text(Strings.notes, style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: postcards.isEmpty
          ? const Center(child: Text(Strings.nothingToShare, style: TextStyle(fontSize: 16, color: KidColors.inkSoft)))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              const Text(Strings.pickToWrite, style: TextStyle(fontSize: 15, color: KidColors.inkSoft, height: 1.4)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: (MediaQuery.sizeOf(context).width / 150).floor().clamp(2, 6),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final p in postcards)
                    Semantics(
                      button: true,
                      label: [shortDate(p.artwork.sentAt ?? p.artwork.updatedAt), if (p.artwork.note != null) Strings.hasNote].join('，'),
                      excludeSemantics: true,
                      child: InkWell(
                        key: ValueKey('note-pick-${p.artwork.id}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _write(context, ref, p),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Stack(fit: StackFit.expand, children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image(
                                image: FileImage(store.open(p.artwork.folder).thumbnail),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white),
                              ),
                            ),
                            if (p.artwork.note != null)
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: KidColors.skyDark, shape: BoxShape.circle),
                                  child: const KidIcon('mail', size: 16, color: Colors.white),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ]),
    );
  }
}

/// Writing on one postcard's back; it closes with what was written.
class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.postcard});

  final Postcard postcard;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  // Lives as long as the sheet, closing animation included.
  late final _text = TextEditingController(text: widget.postcard.artwork.note ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.postcard.artwork;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image(
              image: FileImage(ref.read(artworkStoreProvider).open(artwork.folder).thumbnail),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 12),
          Text(shortDate(artwork.sentAt ?? artwork.updatedAt), style: const TextStyle(fontSize: 16, color: KidColors.inkSoft)),
        ]),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('note-field'),
          controller: _text,
          autofocus: true,
          maxLength: ArtworkRepository.noteLength,
          maxLines: 3,
          minLines: 2,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(hintText: Strings.noteHint, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('note-save'),
          onPressed: () => Navigator.of(context).pop(_text.text),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: KidColors.skyDark),
          child: const Text(Strings.saveNote, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
