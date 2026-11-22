#!/usr/bin/env bash
set -euo pipefail
umask 077

dir="$RUNNER_TEMP/ios-signing"
keychain="$dir/build.keychain-db"
if [[ "${1:-}" == cleanup ]]; then
  if [[ -f "$dir/profile-paths" ]]; then
    while IFS= read -r profile; do rm -f -- "$profile"; done < "$dir/profile-paths"
  fi
  security delete-keychain "$keychain" 2>/dev/null || true
  rm -rf -- "$dir"
  exit 0
fi

: "${CERTIFICATE:?Missing distribution certificate}" "${CERTIFICATE_PASSWORD:?Missing certificate password}"
: "${PROFILE:?Missing app provisioning profile}" "${WIDGET_PROFILE:?Missing widget provisioning profile}"
mkdir -p "$dir"
printf '%s' "$CERTIFICATE" | base64 -D > "$dir/distribution.p12"
printf '%s' "$PROFILE" | base64 -D > "$dir/app.mobileprovision"
printf '%s' "$WIDGET_PROFILE" | base64 -D > "$dir/widget.mobileprovision"
unset CERTIFICATE PROFILE WIDGET_PROFILE
for target in app widget; do
  security cms -D -i "$dir/$target.mobileprovision" > "$dir/$target.plist"
done
python3 scripts/release/check-profiles.py "$dir"

password=$(openssl rand -hex 32)
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$dir/distribution.p12" -k "$keychain" -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
unset CERTIFICATE_PASSWORD
rm -f "$dir/distribution.p12"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain"
security list-keychains -d user -s "$keychain"
security find-identity -v -p codesigning "$keychain" | grep -F 'Apple Distribution:'

profiles="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profiles"
plist=/usr/libexec/PlistBuddy
team=$("$plist" -c 'Print :TeamIdentifier:0' "$dir/app.plist")
app_uuid=$("$plist" -c 'Print :UUID' "$dir/app.plist")
widget_uuid=$("$plist" -c 'Print :UUID' "$dir/widget.plist")
for target in app widget; do
  uuid=$("$plist" -c 'Print :UUID' "$dir/$target.plist")
  printf '%s\n' "$profiles/$uuid.mobileprovision" >> "$dir/profile-paths"
  cp "$dir/$target.mobileprovision" "$profiles/$uuid.mobileprovision"
done

GEM_HOME="$RUNNER_TEMP/signing-gems" gem install xcodeproj --version 1.27.0 --no-document
GEM_HOME="$RUNNER_TEMP/signing-gems" ruby -r xcodeproj - "$team" "$app_uuid" "$widget_uuid" <<'RUBY'
team, app_uuid, widget_uuid = ARGV
project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
{"Runner" => app_uuid, "CountdownsWidget" => widget_uuid}.each do |name, uuid|
  target = project.targets.find { |item| item.name == name }
  abort("Missing signing target #{name}") unless target
  release = target.build_configurations.find { |item| item.name == "Release" }
  release.build_settings.merge!(
    "CODE_SIGN_STYLE" => "Manual",
    "CODE_SIGN_IDENTITY" => "Apple Distribution",
    "CODE_SIGN_IDENTITY[sdk=iphoneos*]" => "Apple Distribution",
    "DEVELOPMENT_TEAM" => team,
    "PROVISIONING_PROFILE_SPECIFIER" => "",
    "PROVISIONING_PROFILE" => uuid
  )
end
project.save
RUBY

python3 - "$dir/export.plist" "$team" "$app_uuid" "$widget_uuid" <<'PY'
import os
import plistlib
import sys

path, team, app_uuid, widget_uuid = sys.argv[1:]
with open(path, "wb") as file:
    plistlib.dump({
        "destination": "export",
        "method": "app-store-connect",
        "manageAppVersionAndBuildNumber": False,
        "provisioningProfiles": {
            os.environ["BUNDLE_ID"]: app_uuid,
            os.environ["WIDGET_BUNDLE_ID"]: widget_uuid,
        },
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "teamID": team,
    }, file)
PY
