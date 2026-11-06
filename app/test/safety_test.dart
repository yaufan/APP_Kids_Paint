import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/parent/parent_gate.dart';

/// No pages opened by other apps, parent mode only through the gate
/// (docs/safety-privacy.md).
void main() {
  test('the app takes no links from other apps and asks for no network', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(manifest, contains('android:name="flutter_deeplinking_enabled" android:value="false"'));
    expect(File('ios/Runner/Info.plist').readAsStringSync(), contains('<key>FlutterDeepLinkingEnabled</key>\n\t<false/>'));
    expect(File('lib/app/router.dart').readAsStringSync(), contains('overridePlatformDefaultLocation: true'));
  });

  test('a right answer at the gate opens parent mode once', () {
    expect(ParentPass.take(), isFalse);
    ParentPass.grant();
    expect(ParentPass.take(), isTrue);
    expect(ParentPass.take(), isFalse, reason: 'used up');
  });
}
