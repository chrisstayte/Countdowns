#!/usr/bin/env bash
set -euo pipefail

xcodebuild -version
sdk=$(xcrun --sdk iphoneos --show-sdk-version)
if [[ "${sdk%%.*}" -lt 27 ]]; then
  echo "iOS SDK 27 or newer is required; selected SDK is $sdk." >&2
  exit 1
fi
echo "Using iOS SDK $sdk"
sdk_dir="$RUNNER_TEMP/flutter"
git init --quiet "$sdk_dir"
git -C "$sdk_dir" remote add origin https://github.com/flutter/flutter.git
tag="refs/tags/$FLUTTER_VERSION"
git -C "$sdk_dir" fetch --depth=1 --no-tags origin "$tag:$tag"
[[ "$(git -C "$sdk_dir" rev-parse "$tag^{commit}")" == "$FLUTTER_COMMIT" ]]
git -C "$sdk_dir" checkout --quiet --detach "$FLUTTER_COMMIT"
"$sdk_dir/bin/flutter" --version
"$sdk_dir/bin/flutter" precache --ios
echo "$sdk_dir/bin" >> "$GITHUB_PATH"
