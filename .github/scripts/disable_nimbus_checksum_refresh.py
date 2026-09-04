#!/usr/bin/env python3

import sys
from pathlib import Path


def main() -> None:
    script_path = Path(sys.argv[1])
    contents = script_path.read_text()
    block_start = "    # Check whether the cached copy is still the right one to use.\n"
    block_end = '    if [ -n "$FRESHEN_FML" ]; then\n'

    if block_start not in contents:
        if "NEW_CHECKSUM=" in contents:
            raise RuntimeError("Nimbus checksum refresh changed; update the local patch")
        print("Nimbus remote checksum refresh is already disabled")
        return

    start_index = contents.index(block_start)
    end_index = contents.index(block_end, start_index)
    script_path.write_text(contents[:start_index] + contents[end_index:])
    print("Disabled Nimbus remote checksum refresh")


if __name__ == "__main__":
    main()
