import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/version.dart';

/// The version lives in three places; they must agree (docs/versioning.md).
void main() {
  final pubspec = RegExp(r'^version: *([0-9.]+)\+', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);

  test('the app reports the version in pubspec.yaml', () {
    expect(appVersion, pubspec);
  });

  test('CHANGELOG.md describes this version', () {
    expect(File('../CHANGELOG.md').readAsStringSync(), contains('## $pubspec '));
  });
}
