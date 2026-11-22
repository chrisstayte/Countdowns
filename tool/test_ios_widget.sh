#!/bin/bash
# Run the native widget regressions on an already booted iOS simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
simulator_id="${1:?Usage: bash tool/test_ios_widget.sh <booted-simulator-uuid>}"
widget_test_build="$(mktemp -d "${TMPDIR:-/tmp}/countdowns-widget-tests.XXXXXX")"
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SDKROOT="$sdk_path" xcrun swiftc -parse-as-library \
  -target "$(uname -m)-apple-ios17.0-simulator" -sdk "$sdk_path" \
  -module-cache-path "$widget_test_build/module-cache" \
  ios/CountdownsWidget/Snapshot.swift \
  ios/CountdownsWidget/Configuration.swift \
  ios/CountdownsWidget/Provider.swift \
  ios/CountdownsWidget/Fonts.swift \
  tool/widget_native_tests.swift \
  -o "$widget_test_build/widget-tests"
xcrun simctl spawn "$simulator_id" "$widget_test_build/widget-tests" "$PWD" "$widget_test_build"
