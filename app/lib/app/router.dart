import 'dart:typed_data';

import 'package:go_router/go_router.dart';

import '../features/canvas/canvas_screen.dart';
import '../features/capture/capture_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lineart/style_picker_screen.dart';
import '../features/map_journal/map_screen.dart';
import '../features/parent/parent_screen.dart';

GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
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
        GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
        GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
        // Only reached through the parent gate on the home screen.
        GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
      ],
    );
