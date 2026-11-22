#!/usr/bin/env bash
set -euo pipefail

# Install the compile SDK required by the app and home screen widgets.
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:?Missing Android SDK}}"
"$sdk_root/cmdline-tools/latest/bin/sdkmanager" --install 'platforms;android-37.0' 'build-tools;37.0.0'
