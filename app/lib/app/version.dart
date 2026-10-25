/// The app's version. CI passes the real values with
/// `--dart-define=APP_VERSION=... --dart-define=APP_BUILD=...` (see
/// .github/workflows/app.yml); [appVersion]'s default must match
/// `version:` in pubspec.yaml (test/version_test.dart checks it).
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.5.0');
const appBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');

String get appVersionLabel => '$appVersion ($appBuild)';
