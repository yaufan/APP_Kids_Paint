#!/bin/bash
# Walks through the app on the iOS simulator $1 (run from app/), then shuts
# the simulator down. Screenshots go to $SCREENSHOT_DIR.
#
# The app sometimes never starts on the simulator: flutter drive waits for
# it forever after "Xcode build done". A try that has not finished after
# 35 minutes (the first Xcode build alone can take 8, the walk-through
# about 15) is stopped, the simulator is booted again and the walk-through
# runs once more. A try stopped after its tests all passed (flutter drive
# can be slow to quit) counts as passed. A test that fails is not tried
# again.
set -u
device=$1
log=$(mktemp)

boot() {
  xcrun simctl boot "$device" || return 1
  # Wait for a full boot before installing: installing onto a simulator
  # that is still booting can hang too.
  xcrun simctl bootstatus "$device" -b
}

boot || exit 1
for try in 1 2; do
  perl -e 'alarm shift; exec @ARGV' 2100 \
    flutter drive --driver=test_driver/integration_test.dart \
      --target=integration_test/app_flow_test.dart -d "$device" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  # 142 = stopped by the alarm (128 + SIGALRM).
  if [ "$status" = 142 ] && grep -q 'All tests passed' "$log"; then
    echo "::notice::The walk-through passed; flutter drive was stopped while quitting."
    status=0
  fi
  [ "$status" = 142 ] && [ "$try" = 1 ] || break
  echo "::warning::The walk-through did not finish in 35 minutes; booting the simulator again."
  xcrun simctl shutdown "$device" || true
  boot || exit 1
done
xcrun simctl shutdown "$device" || true
exit "$status"
