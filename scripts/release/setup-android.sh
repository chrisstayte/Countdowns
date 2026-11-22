#!/usr/bin/env bash
set -euo pipefail

# Install the compile SDK required by the app and home screen widgets.
sdkmanager --install 'platforms;android-37.0' 'build-tools;37.0.0'
