import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/providers.dart';
import 'core/storage/artwork_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL-jf-openhuninn.txt');
    yield LicenseEntryWithLineBreaks(const ['jf open 粉圓 (jf-openhuninn)'], text);
  });
  final documents = await getApplicationDocumentsDirectory();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase()),
      artworkStoreProvider.overrideWithValue(ArtworkStore(Directory(p.join(documents.path, 'artworks')))),
    ],
    child: const KidsPaintApp(),
  ));
}
