"""Shared helpers for the upgrade tools: git access, the upstream base, exit codes.

Exit codes used by every tool:
  0   check passed (or the list was written)
  1   check failed: the output lists what needs a look
  2   could not run: a git command failed, an input is missing
  64  usage error
"""

import argparse
import subprocess
import sys
from pathlib import Path

OK, FAILED, ERROR, USAGE = 0, 1, 2, 64

UPSTREAM_BASE_FILE = "firefox-ios/EcosiaUpgrade/UPSTREAM_BASE"

# Folders that only hold Ecosia's own files; nothing in them is Firefox code.
ECOSIA_DIRS = ("firefox-ios/Client/Ecosia/", "firefox-ios/Ecosia/", "firefox-ios/EcosiaTests/",
               "firefox-ios/EcosiaUpgrade/")


def die(message, code=ERROR):
    print(f"{Path(sys.argv[0]).name}: {message}", file=sys.stderr)
    sys.exit(code)


class Parser(argparse.ArgumentParser):
    """argparse with usage errors exiting 64 instead of 2."""

    def error(self, message):
        self.print_usage(sys.stderr)
        die(message, USAGE)


def git(*args, cwd=None, check=True, binary=False):
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=not binary)
    if check and result.returncode != 0:
        err = result.stderr if not binary else result.stderr.decode(errors="replace")
        die(f"git {' '.join(args)} failed: {err.strip()}")
    return result.stdout


def repo_root():
    result = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if result.returncode != 0:
        die("not inside a git work tree", USAGE)
    return Path(result.stdout.strip())


def resolve_ref(ref, root):
    """Full name of `ref`. A bare Firefox tag name always resolves to refs/tags/..., because some
    clones have a branch with the same name (`firefox-v147.2`)."""
    if not ref.startswith("refs/"):
        tag = f"refs/tags/{ref}"
        if subprocess.run(["git", "rev-parse", "-q", "--verify", f"{tag}^{{commit}}"], cwd=root,
                          capture_output=True).returncode == 0:
            return tag
    if subprocess.run(["git", "rev-parse", "-q", "--verify", f"{ref}^{{commit}}"], cwd=root,
                      capture_output=True).returncode != 0:
        die(f"cannot resolve '{ref}' to a commit", USAGE)
    return ref


def upstream_base(root, at=None):
    """refs/tags/<tag> from UPSTREAM_BASE, read from the work tree or, with `at`, from that commit.
    Fails when the tag is missing or no longer points at the recorded hash."""
    if at:
        text = git("show", f"{at}:{UPSTREAM_BASE_FILE}", cwd=root, check=False)
        if not text:
            return None
    else:
        path = root / UPSTREAM_BASE_FILE
        if not path.exists():
            die(f"{UPSTREAM_BASE_FILE} not found")
        text = path.read_text()
    fields = text.strip().split("\t")
    if len(fields) != 2:
        die(f"{UPSTREAM_BASE_FILE} must be '<tag><TAB><hash>', got {text.strip()!r}")
    tag, recorded = fields
    ref = f"refs/tags/{tag}"
    actual = git("rev-parse", "-q", "--verify", f"{ref}^{{commit}}", cwd=root, check=False).strip()
    if not actual:
        die(f"tag {tag} from {UPSTREAM_BASE_FILE} not found: run `git fetch <firefox remote> tag {tag}`")
    if actual != recorded:
        die(f"tag {tag} points at {actual}, but {UPSTREAM_BASE_FILE} records {recorded}")
    return ref


def base_ref(arg, root):
    """The --base argument resolved, or the upstream base from UPSTREAM_BASE."""
    return resolve_ref(arg, root) if arg else upstream_base(root)


def changed_files(base, ref, root, diff_filter):
    """Paths whose status from `base` to `ref` matches `diff_filter` (rename detection off)."""
    out = git("diff", "--no-renames", f"--diff-filter={diff_filter}", "--name-only", "-z", base, ref,
              "--", cwd=root)
    return sorted(p for p in out.split("\0") if p)


def read_blobs(ref, paths, root):
    """{path: text} for each path at `ref`, read through one `git cat-file --batch`."""
    if not paths:
        return {}
    request = "".join(f"{ref}:{p}\n" for p in paths).encode()
    proc = subprocess.run(["git", "cat-file", "--batch"], cwd=root, input=request,
                          capture_output=True)
    if proc.returncode != 0:
        die(f"git cat-file failed: {proc.stderr.decode(errors='replace').strip()}")
    out, pos, blobs = proc.stdout, 0, {}
    for p in paths:
        end = out.index(b"\n", pos)
        header = out[pos:end].decode()
        pos = end + 1
        if header.endswith(" missing"):
            continue
        size = int(header.split()[2])
        blobs[p] = out[pos:pos + size].decode("utf-8", errors="replace")
        pos += size + 1
    return blobs


def is_ecosia_path(path):
    return path.startswith(ECOSIA_DIRS)


def _main():
    """For shell scripts: `upgrade_common.py base [<ref>]` prints the upstream base (or <ref>
    resolved), `upgrade_common.py ref <ref>` prints <ref> resolved."""
    if len(sys.argv) >= 2 and sys.argv[1] in ("base", "ref"):
        root = repo_root()
        arg = sys.argv[2] if len(sys.argv) > 2 else None
        if sys.argv[1] == "base":
            print(base_ref(arg, root))
            return OK
        if arg:
            print(resolve_ref(arg, root))
            return OK
    die("usage: upgrade_common.py base [<ref>] | ref <ref>", USAGE)


if __name__ == "__main__":
    sys.exit(_main())
