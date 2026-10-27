import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app is for children under 5 (the App Store's Kids category and
/// Google Play's Families policy): no ads, no analytics, no tracking, no
/// network. These checks fail the build if any of that sneaks in, so the
/// store review never finds it first (docs/safety-privacy.md).
void main() {
  test('no ad, analytics, tracking or crash-reporting package is built in', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final packages = RegExp(r'^  ([a-z0-9_]+):$', multiLine: true).allMatches(lock).map((m) => m[1]!).toList();
    expect(packages, isNotEmpty);
    final banned = RegExp(
      r'firebase|crashlytics|analytics|admob|google_mobile_ads|ads_sdk|_ads$|^ads_|facebook|meta_|appsflyer|adjust|'
      r'amplitude|mixpanel|segment|posthog|sentry|bugsnag|datadog|newrelic|onesignal|branch|clevertap|braze|'
      r'airbridge|kochava|singular|tenjin|appmetrica|applovin|ironsource|unity_ads|vungle|chartboost|tracking|'
      r'attribution|advertising_id|app_tracking',
    );
    expect(packages.where(banned.hasMatch), isEmpty);
  });

  test('the Android release build asks for no internet, ad ID, location or contacts', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final permission in [
      'INTERNET', 'AD_ID', 'ACCESS_NETWORK_STATE', 'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION', //
      'READ_CONTACTS', 'RECORD_AUDIO', 'READ_PHONE_STATE', 'GET_ACCOUNTS',
    ]) {
      expect(manifest.contains('android.permission.$permission'), isFalse, reason: permission);
    }
  });

  test('iOS asks only for the camera, photos to color and saving to the album', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final asks = RegExp(r'<key>(NS\w+UsageDescription)</key>').allMatches(plist).map((m) => m[1]).toSet();
    expect(asks, {'NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription', 'NSPhotoLibraryAddUsageDescription'});
    expect(plist.contains('NSUserTrackingUsageDescription'), isFalse);
  });

  test('the app code opens no network connection', () {
    final network = RegExp(r"HttpClient|package:http/|WebSocket|Socket\.connect|RawSocket|'https?://");
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart') && network.hasMatch(file.readAsStringSync())) file.path,
    ];
    expect(offenders, isEmpty);
  });
}
