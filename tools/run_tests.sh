#!/bin/bash
# tools/run_tests.sh LOG TEST... : runs `flutter test` in app/ on a cloud
# machine whose sqlite3 has to come from the system. It adds the
# `hooks: user_defines: sqlite3: source: system` block to app/pubspec.yaml
# for the run and always takes it out again: that block must never be
# committed. Example:
#   tools/run_tests.sh /tmp/unit.log $(ls app/test/*.dart | grep -v -E "flow_test|/zz_")
#   TIMEOUT=3000 tools/run_tests.sh /tmp/flow.log test/flow_test.dart test/demo/demo_video_test.dart --dart-define=DEMO=true
# (paths after LOG are relative to app/). Set FLUTTER_BIN if flutter is not on PATH.
set -u
LOG=$1; shift
cd "$(dirname "$0")/../app" || exit 1
[ -n "${FLUTTER_BIN:-}" ] && export PATH="$FLUTTER_BIN:$PATH"
if grep -q 'source: system' pubspec.yaml; then echo "pubspec already has the sqlite block"; exit 2; fi
KEEP=$(mktemp)
cp pubspec.yaml "$KEEP"
restore() { cp "$KEEP" pubspec.yaml; rm -f "$KEEP"; echo "pubspec restored: $(grep -c 'source: system' pubspec.yaml) sqlite blocks left"; }
trap restore EXIT
printf '\nhooks:\n  user_defines:\n    sqlite3:\n      source: system\n' >> pubspec.yaml
timeout "${TIMEOUT:-1500}" flutter test "$@" > "$LOG" 2>&1
echo "flutter test exit $?"
