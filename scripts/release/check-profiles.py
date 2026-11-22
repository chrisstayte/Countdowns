"""Check both distribution profiles before importing any signing assets."""

import datetime
import os
import plistlib
import re
import sys
from pathlib import Path

directory = Path(sys.argv[1])
profiles = []
for name, bundle in (("app", os.environ["BUNDLE_ID"]), ("widget", os.environ["WIDGET_BUNDLE_ID"])):
    with (directory / f"{name}.plist").open("rb") as file:
        profile = plistlib.load(file)
    team = profile["TeamIdentifier"][0]
    entitlements = profile["Entitlements"]
    if not re.fullmatch(r"[A-Z0-9]{10}", team) or not re.fullmatch(r"[a-fA-F0-9-]{36}", profile["UUID"]):
        sys.exit(f"Invalid {name} profile identifiers.")
    if entitlements.get("application-identifier") != f"{team}.{bundle}":
        sys.exit(f"Wrong bundle ID in {name} profile.")
    if profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
        sys.exit(f"The {name} provisioning profile has expired.")
    if profile.get("ProvisionedDevices") or profile.get("ProvisionsAllDevices") or entitlements.get("get-task-allow"):
        sys.exit(f"Use an App Store Connect distribution profile for {name}.")
    if os.environ["APP_GROUP"] not in entitlements.get("com.apple.security.application-groups", []):
        sys.exit(f"The {name} profile does not include the shared widget App Group.")
    if name == "app" and entitlements.get("aps-environment") != "production":
        sys.exit("The app profile must allow production push notifications.")
    profiles.append(profile)
if profiles[0]["TeamIdentifier"] != profiles[1]["TeamIdentifier"]:
    sys.exit("App and widget profiles must use the same Apple team.")
if not set(profiles[0]["DeveloperCertificates"]) & set(profiles[1]["DeveloperCertificates"]):
    sys.exit("App and widget profiles must share a distribution certificate.")
print("App and widget distribution profiles are valid.")
