#!/usr/bin/env python3
"""Save publisher credentials locally without echoing their values."""
import json
import os
from pathlib import Path
import re
import sys
import termios


def main():
    destination = Path.home() / '.config/countdowns-media/publisher.env'
    if destination.exists():
        raise ValueError('Credentials already exist. Move the old file aside before replacing it.')
    old = None
    try:
        if sys.stdin.isatty():
            old = termios.tcgetattr(sys.stdin)
            silent = old.copy()
            silent[3] &= ~termios.ECHO
            termios.tcsetattr(sys.stdin, termios.TCSANOW, silent)
        print('Paste one line of publisher credentials JSON; input is hidden:', flush=True)
        data = json.loads(sys.stdin.readline())
    finally:
        if old is not None:
            termios.tcsetattr(sys.stdin, termios.TCSANOW, old)
    required = ['R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_ENDPOINT', 'CF_API_TOKEN', 'CF_ZONE_ID']
    for key in required:
        if not isinstance(data.get(key), str) or not data[key] or any(c in data[key] for c in '\r\n\x00'):
            raise ValueError('A required credential is missing or malformed.')
    if not re.fullmatch(r'https://[a-f0-9]{32}(?:\.(?:eu|us))?\.r2\.cloudflarestorage\.com/?', data['R2_ENDPOINT']):
        raise ValueError('Unexpected R2 endpoint.')
    if not re.fullmatch(r'[a-f0-9]{32}', data['CF_ZONE_ID']):
        raise ValueError('Unexpected Cloudflare zone ID.')
    private_media = Path.home() / 'Library/Application Support/Countdowns Media'
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(destination.parent, 0o700)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, 'O_NOFOLLOW', 0)
    with os.fdopen(os.open(destination, flags, 0o600), 'w') as output:
        output.write('# Private Countdowns publisher settings. Never copy into the repository.\n')
        for key in required:
            output.write(f'{key}={json.dumps(data[key])}\n')
        output.write(f'COUNTDOWNS_MEDIA_DIR={json.dumps(str(private_media))}\n')
    print(f'Credentials saved with mode 600 at {destination}. No values were printed.')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        # Do not print input or exception messages that could include credentials.
        print('Credential setup failed. Check input and whether the private file already exists.', file=sys.stderr)
        sys.exit(1)
