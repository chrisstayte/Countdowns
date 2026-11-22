"""Validate the app and embedded widget have the requested store identity."""

import os
import plistlib
import re
import sys
from pathlib import Path


def check(path, bundle):
    with path.open('rb') as file:
        info = plistlib.load(file)
    expected = {
        'CFBundleIdentifier': bundle,
        'CFBundleShortVersionString': os.environ['VERSION'],
        'CFBundleVersion': os.environ['BUILD_NUMBER'],
    }
    for key, value in expected.items():
        if info.get(key) != value:
            sys.exit(f'{path}: {key}: expected {value!r}, got {info.get(key)!r}')
    sdk = info.get('DTSDKName', '')
    match = re.fullmatch(r'iphoneos(\d+)(?:\.\d+)*', sdk) if isinstance(sdk, str) else None
    if not match or int(match.group(1)) < 27:
        sys.exit(f'{path}: expected iOS SDK 27 or newer, got {sdk!r}')
    print(f'{bundle}: version {expected["CFBundleShortVersionString"]}, build {expected["CFBundleVersion"]}, {sdk}')


app = Path(sys.argv[1])
check(app, os.environ['BUNDLE_ID'])
widget = app.parent / 'PlugIns/CountdownsWidget.appex/Info.plist'
check(widget, os.environ['WIDGET_BUNDLE_ID'])
