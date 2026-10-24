import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'walkthrough.dart';

/// Runs the walk-through on a real device or simulator (iPhone, iPad, Android):
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_flow_test.dart -d DEVICE_ID
/// Screenshots are saved by the driver into $SCREENSHOT_DIR.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walk-through on a device', (tester) async {
    await binding.convertFlutterSurfaceToImage(); // once, Android only; no-op elsewhere
    await runWalkthrough(
      tester,
      photo: syntheticPhoto(),
      shot: (name) async {
        await tester.pump();
        await binding.takeScreenshot(name);
      },
    );
  });
}
