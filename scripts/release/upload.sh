#!/usr/bin/env bash
set -euo pipefail
umask 077

: "${ASC_KEY:?Missing App Store Connect private key}"
[[ "$ASC_KEY_ID" =~ ^[A-Z0-9]+$ && "$ASC_ISSUER_ID" =~ ^[a-fA-F0-9-]{36}$ ]]
shopt -s nullglob
ipas=(build/ios/ipa/*.ipa)
[[ "${#ipas[@]}" == 1 ]] || { echo "Expected exactly one IPA."; exit 1; }

exported=$(mktemp -d "$RUNNER_TEMP/exported-ipa.XXXXXX")
trap 'rm -rf -- "$exported"' EXIT
unzip -q "${ipas[0]}" -d "$exported"
apps=("$exported"/Payload/*.app)
[[ "${#apps[@]}" == 1 ]] || { echo "Expected exactly one exported app."; exit 1; }
python3 scripts/release/check-app.py "${apps[0]}/Info.plist"
codesign --verify --deep --strict "${apps[0]}"

key_dir="$HOME/.appstoreconnect/private_keys"
mkdir -p "$key_dir"
key="$key_dir/AuthKey_$ASC_KEY_ID.p8"
trap 'rm -f -- "$key"; rm -rf -- "$exported"' EXIT
printf '%s\n' "$ASC_KEY" > "$key"
unset ASC_KEY
case "${1:-}" in
  validate) operation=--validate-app ;;
  upload) operation=--upload-app ;;
  *) echo "Expected validate or upload." >&2; exit 2 ;;
esac
xcrun altool "$operation" --type ios --file "${ipas[0]}" --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"
