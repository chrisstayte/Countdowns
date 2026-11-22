import os
import re
import subprocess
from pathlib import Path

version, floor = re.search(
    r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$",
    Path("pubspec.yaml").read_text(),
    re.MULTILINE,
).groups()
seed = os.environ["BUILD_NUMBER_SEED"]
if not seed and os.environ["MODE"] == "validate":
    seed = "0"
if not re.fullmatch(r"[0-9]+", seed):
    raise SystemExit("Set MOBILE_BUILD_NUMBER_SEED to the highest manual store build first.")
tags = subprocess.check_output(["git", "tag", "--list", "mobile-v*+*"], text=True)
numbers = [int(n) for n in re.findall(r"^mobile-v\d+\.\d+\.\d+\+(\d+)$", tags, re.M)]
number = max(int(floor), int(seed), *numbers) + 1
if number > 2100000000:
    raise SystemExit("Build number exceeds the Google Play limit.")
with open(os.environ["GITHUB_OUTPUT"], "a") as output:
    print(f"version={version}\nnumber={number}\ntag=mobile-v{version}+{number}", file=output)
