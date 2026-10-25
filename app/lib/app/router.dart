import 'dart:typed_data';

import 'package:go_router/go_router.dart';

import '../core/places.dart';
import '../features/album/album_screen.dart';
import '../features/canvas/canvas_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/lineart/style_picker_screen.dart';
import '../features/parent/parent_screen.dart';
import '../features/parent/privacy_screen.dart';
import '../features/send/send_screen.dart';
import '../features/send/sent_screen.dart';
import '../features/town/town_screen.dart';

PlaceKind? _kind(String? name) => name == null ? null : PlaceKind.byName(name);

GoRouter buildRouter() => GoRouter(
      routes: [
        // The town map; after sending, ?focus=park (and &grow=park the first time).
        GoRoute(
          path: '/',
          builder: (_, state) => TownScreen(
            key: state.pageKey,
            focus: _kind(state.uri.queryParameters['focus']),
            grow: _kind(state.uri.queryParameters['grow']),
          ),
        ),
        GoRoute(path: '/capture', builder: (_, _) => const CaptureScreen()),
        GoRoute(
          path: '/styles',
          // The photo travels in memory; without it (e.g. after a restart) start over.
          redirect: (_, state) => state.extra is Uint8List ? null : '/capture',
          builder: (_, state) => StylePickerScreen(photo: state.extra! as Uint8List),
        ),
        GoRoute(
          path: '/canvas/:id',
          builder: (_, state) => CanvasScreen(artworkId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/send/:id',
          builder: (_, state) => SendScreen(artworkId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/sent/:id',
          builder: (_, state) => SentScreen(
            artworkId: int.parse(state.pathParameters['id']!),
            kind: PlaceKind.byName(state.uri.queryParameters['kind'] ?? 'home'),
            isNew: state.uri.queryParameters['new'] == '1',
          ),
        ),
        GoRoute(path: '/album', builder: (_, _) => const AlbumScreen()),
        // Only reached through the parent gate.
        GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
        GoRoute(path: '/parent/privacy', builder: (_, _) => const PrivacyScreen()),
      ],
    );
