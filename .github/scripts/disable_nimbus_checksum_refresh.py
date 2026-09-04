#!/usr/bin/env python3

import sys
from pathlib import Path


def main() -> None:
    script_path = Path(sys.argv[1])
    contents = script_path.read_text()
    block_start = "    # Check whether the cached copy is still the right one to use.\n"
    block_end = '    if [ -n "$FRESHEN_FML" ]; then\n'
    verification_start = "        # We also download the checksum\n"
    verification_end = "        popd\n"
    modified = False

    if block_start in contents:
        start_index = contents.index(block_start)
        end_index = contents.index(block_end, start_index)
        contents = contents[:start_index] + contents[end_index:]
        modified = True
    else:
        if "NEW_CHECKSUM=" in contents:
            raise RuntimeError("Nimbus checksum refresh changed; update the local patch")

    if verification_start in contents:
        start_index = contents.index(verification_start)
        end_index = contents.index(verification_end, start_index) + len(verification_end)
        contents = contents[:start_index] + contents[end_index:]
        modified = True
    elif "shasum --check nimbus-fml.sha256" in contents:
        raise RuntimeError("Nimbus checksum verification changed; update the local patch")

    if modified:
        script_path.write_text(contents)
        print("Disabled Nimbus remote checksum refresh and verification")
    else:
        print("Nimbus remote checksum operations are already disabled")


if __name__ == "__main__":
    main()
