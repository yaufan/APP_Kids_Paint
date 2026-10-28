import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The phone's share sheet (LINE, IG, saving it...). Only parent mode
/// shares, a picture made for it (docs/safety-privacy.md §5).
abstract interface class Sharer {
  /// Offers [png] to the share sheet as [name]; [origin] is where on the
  /// screen the sheet points from (iPads need it).
  Future<void> shareImage(Uint8List png, {required String name, Rect? origin});
}

class SystemSharer implements Sharer {
  @override
  Future<void> shareImage(Uint8List png, {required String name, Rect? origin}) async {
    // Only the newest card is kept around for the share sheet to read.
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      sharePositionOrigin: origin,
    ));
  }
}
