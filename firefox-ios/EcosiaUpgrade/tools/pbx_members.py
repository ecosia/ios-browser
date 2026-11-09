#!/usr/bin/env python3
"""List what each target of an Xcode project compiles and copies.

Usage: pbx_members.py <project.pbxproj | project.json> [<synced-folder-listing>]
       pbx_members.py --dependencies <project.pbxproj | project.json>

  <project>  a project.pbxproj (converted with `plutil -convert json`) or its JSON form
  <synced-folder-listing>  `git ls-tree -r --name-only <ref> firefox-ios/` of the project's
             commit, used to expand Xcode 16 synchronized folders (PBXFileSystemSynchronizedRootGroup)
             into files. Leave out for a project without them (the Tuist-generated one).

Prints one line per member: <target>\t<sources|resources|copy>\t<repo-relative path>.
Paths are relative to the repository root (the project lives in firefox-ios/).
With --dependencies, prints <target>\t<module> for every framework or library a target depends on
directly (app extensions a target embeds are not modules it imports).
Exits 0, or 2 when the project cannot be read.
"""

import json
import posixpath
import subprocess
import sys
from pathlib import Path, PurePosixPath

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import upgrade_common as uc  # noqa: E402

PROJECT_DIR = "firefox-ios"
COMPILED = {".swift", ".m", ".mm", ".c", ".cpp", ".h"}
PHASES = {
    "PBXSourcesBuildPhase": "sources",
    "PBXResourcesBuildPhase": "resources",
    "PBXCopyFilesBuildPhase": "copy",
}


def load_project(path):
    """The project as a dict, from a .pbxproj (through plutil) or a JSON file."""
    if str(path).endswith(".pbxproj"):
        result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(path)],
                                capture_output=True, text=True)
        if result.returncode != 0:
            uc.die(f"plutil could not read {path}: {result.stderr.strip()}")
        return json.loads(result.stdout)
    try:
        return json.load(open(path))
    except (OSError, ValueError) as e:
        uc.die(f"cannot read {path}: {e}")


def members(doc, listing=()):
    """Sorted (target, phase, repo-relative path) tuples."""
    objs = doc["objects"]
    parent = {}
    for oid, o in objs.items():
        for child in o.get("children", []):
            parent[child] = oid
    root_group = objs[doc["rootObject"]]["mainGroup"]

    def resolve(oid):
        """Repo-relative path of a file reference or group, or None when it isn't in the source tree."""
        o = objs[oid]
        tree = o.get("sourceTree", "<group>")
        own = o.get("path", "")
        if tree == "SOURCE_ROOT":
            return str(PurePosixPath(PROJECT_DIR) / own)
        if tree == "<absolute>":
            return own
        if tree != "<group>":
            return None
        if oid == root_group or oid not in parent:
            base = PROJECT_DIR
        else:
            base = resolve(parent[oid])
            if base is None:
                return None
        return str(PurePosixPath(base) / own) if own else base

    def members_of_ref(ref):
        o = objs[ref]
        if o["isa"] == "PBXVariantGroup":
            return [p for c in o.get("children", []) if (p := resolve(c))]
        p = resolve(ref)
        return [p] if p else []

    out = set()
    for oid, o in objs.items():
        if o["isa"] != "PBXNativeTarget":
            continue
        name = o["name"]
        for ph in o.get("buildPhases", []):
            phase = objs[ph]
            kind = PHASES.get(phase["isa"])
            if not kind:
                continue
            for bf in phase.get("files", []):
                ref = objs[bf].get("fileRef")
                if not ref:
                    continue
                for p in members_of_ref(ref):
                    out.add((name, kind, p))
        for g in o.get("fileSystemSynchronizedGroups", []):
            folder = resolve(g)
            excluded = set()
            for ex in objs[g].get("exceptions", []):
                exo = objs[ex]
                if exo.get("target") == oid:
                    excluded |= {f"{folder}/{m}" for m in exo.get("membershipExceptions", [])}
            for f in listing:
                if f.startswith(folder + "/") and f not in excluded:
                    kind = "sources" if PurePosixPath(f).suffix in COMPILED else "resources"
                    out.add((name, kind, f))

    return sorted({(t, k, posixpath.normpath(p)) for t, k, p in out})


def module_dependencies(doc):
    """{target: names of the framework and library targets it depends on directly}."""
    objs = doc["objects"]
    deps = {}
    for o in objs.values():
        if o["isa"] != "PBXNativeTarget":
            continue
        names = set()
        for d in o.get("dependencies", []):
            target = objs[d].get("target")
            if target and ("framework" in objs[target].get("productType", "")
                           or "library" in objs[target].get("productType", "")):
                names.add(objs[target]["name"])
        deps[o["name"]] = names
    return deps


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--dependencies":
        for target, names in sorted(module_dependencies(load_project(sys.argv[2])).items()):
            for name in sorted(names):
                print(f"{target}\t{name}")
        return uc.OK
    if len(sys.argv) not in (2, 3):
        uc.die("usage: pbx_members.py <project.pbxproj | project.json> [<synced-folder-listing>]",
               uc.USAGE)
    doc = load_project(sys.argv[1])
    listing = []
    if len(sys.argv) == 3:
        listing = [l.strip() for l in open(sys.argv[2]) if l.strip()]
    for t, k, p in members(doc, listing):
        print(f"{t}\t{k}\t{p}")
    return uc.OK


if __name__ == "__main__":
    sys.exit(main())
