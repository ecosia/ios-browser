#!/usr/bin/env python3

import sys
from pathlib import Path


REFRESH_START = "    # Check whether the cached copy is still the right one to use.\n"
REFRESH_END = '    if [ -n "$FRESHEN_FML" ]; then\n'
DOWNLOADS = {
    'curl -L "$FML_URL" --output "$FML_DIR/nimbus-fml.zip"':
        'curl -fL --retry 3 --retry-all-errors "$FML_URL" --output "$FML_DIR/nimbus-fml.zip"',
    'curl -L "$CHECKSUM_URL" --output "$FML_DIR/nimbus-fml.sha256"':
        'curl -fL --retry 3 --retry-all-errors "$CHECKSUM_URL" --output "$FML_DIR/nimbus-fml.sha256"',
}


def main() -> None:
    script_path = Path(sys.argv[1])
    contents = script_path.read_text()
    original = contents

    if REFRESH_START in contents:
        start_index = contents.index(REFRESH_START)
        end_index = contents.index(REFRESH_END, start_index)
        contents = contents[:start_index] + contents[end_index:]
    elif "NEW_CHECKSUM=" in contents:
        raise RuntimeError("Nimbus checksum refresh changed; update the local patch")

    for upstream, hardened in DOWNLOADS.items():
        if upstream in contents:
            contents = contents.replace(upstream, hardened)
        elif hardened not in contents:
            raise RuntimeError("Nimbus FML download changed; update the local patch")

    if "shasum --check nimbus-fml.sha256" not in contents:
        raise RuntimeError("Nimbus checksum verification is missing; refusing to run an unverified binary")

    if contents != original:
        script_path.write_text(contents)
        print("Disabled Nimbus remote checksum refresh and hardened verified downloads")
    else:
        print("Nimbus FML script is already patched")


if __name__ == "__main__":
    main()
