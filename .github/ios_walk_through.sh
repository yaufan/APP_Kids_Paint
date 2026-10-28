#!/bin/bash
# Walks through the app on the iOS simulator $1 (run from app/), then shuts
# the simulator down. Screenshots go to $SCREENSHOT_DIR.
#
# The app sometimes never starts on the simulator: flutter drive waits for
# it forever after "Xcode build done". A try that has not finished after
# 25 minutes (a normal one takes about 15) is stopped, the simulator is
# booted again and the walk-through runs once more. A test that fails is
# not tried again.
set -u
device=$1

boot() {
  xcrun simctl boot "$device" || return 1
  # Wait for a full boot before installing: installing onto a simulator
  # that is still booting can hang too.
  xcrun simctl bootstatus "$device" -b
}

boot || exit 1
for try in 1 2; do
  status=0
  perl -e 'alarm shift; exec @ARGV' 1500 \
    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/app_flow_test.dart -d "$device" || status=$?
  # 142 = stopped by the alarm (128 + SIGALRM).
  [ "$status" = 142 ] && [ "$try" = 1 ] || break
  echo "::warning::The walk-through did not finish in 25 minutes; booting the simulator again."
  xcrun simctl shutdown "$device" || true
  boot || exit 1
done
xcrun simctl shutdown "$device" || true
exit "$status"
