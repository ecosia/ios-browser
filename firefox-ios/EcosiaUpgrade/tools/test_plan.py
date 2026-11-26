#!/usr/bin/env python3
"""Check, map and select the flows of the upgrade test plan (firefox-ios/EcosiaUpgrade/test-plan).

Usage: test_plan.py --check | --map | --affected <rev-range> | --todo <release>

  --check     every flow is well formed, ids are unique and in their file's Mermaid diagram, Covers
              paths exist, every required area has a file, every `automated:` test exists, every
              +Ecosia extension file is covered or listed in uncovered.allow, map.md is current.
              Prints the agent / automated / human counts.
  --map       rewrites test-plan/map.md from the area and target files.
  --affected  prints the flows whose file's Covers paths a git revision range changed (and the flows
              of plan files it changed), one "<id><TAB><file>" per line.
  --todo      prints a run sheet: every flow of the area files plus targets/<release>.md.

The format is in test-plan/README.md.
Exit codes: 0 ok, 1 --check found problems, 2 could not run, 64 usage error.
"""
import argparse
import glob
import os
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import upgrade_common as uc  # noqa: E402

PLAN_DIR = "firefox-ios/EcosiaUpgrade/test-plan"

# Areas MOB-5044 requires: one file each.
REQUIRED_AREAS = (
    "accounts", "ai-features", "homepage", "launch", "library", "menu", "removed-features",
    "search", "settings", "toolbar", "tracking-protection", "update-paths",
)

# Ecosia extensions of Firefox (or shared) types: each needs a flow or a reason in uncovered.allow.
EXTENSION_GLOBS = (
    "firefox-ios/Client/Ecosia/Extensions/*+Ecosia*.swift",
    "firefox-ios/Ecosia/**/*+Ecosia*.swift",
    "firefox-ios/Storage/**/*+Ecosia*.swift",
)

# Where `automated:` tests live.
TEST_DIRS = ("firefox-ios/EcosiaTests", "firefox-ios/firefox-ios-tests/Tests")

FLOW_ID = re.compile(r"^[a-z0-9][a-z0-9-]*(\.[a-z0-9][a-z0-9.-]*)+$")
PRIORITY = re.compile(r"^p[123]$")
# Level-2 headings that aren't flows; every other `##` heading must be a valid flow id.
SECTION_HEADINGS = frozenset({"Intended changes", "Migrations"})
META_FIELD = re.compile(r"^(origin(?=\s)|automated:|human:)(.*)$")
STEP = re.compile(r"^\d+\.\s+\S")


class Flow:
    def __init__(self, fid, path, line):
        self.id, self.path, self.line = fid, path, line
        self.meta = None
        self.priority = None
        self.origin = None
        self.automated = None
        self.human = None
        self.summary = ""
        self.setup = None
        self.steps = 0
        self.expect = None
        self.problems = []

    @property
    def runner(self):
        if self.automated:
            return "automated"
        if self.human:
            return "human"
        return "agent"


class PlanFile:
    def __init__(self, path, title, covers, diagram, flows, problems=()):
        self.path, self.title, self.covers, self.diagram, self.flows = path, title, covers, diagram, flows
        self.problems = list(problems)  # "<line>: <text>" for the file as a whole


def parse_meta(flow, text):
    flow.meta = text
    fields = [f.strip() for f in text.split(" · ")]
    if not fields or not PRIORITY.match(fields[0]):
        flow.problems.append(f"metadata line must start with p1, p2 or p3: {text!r}")
    else:
        flow.priority = fields[0]
    for field in fields[1:]:
        m = META_FIELD.match(field)
        if not m:
            flow.problems.append(f"unknown metadata field {field!r}")
            continue
        key, value = m.group(1).rstrip(":"), m.group(2).strip()
        if key == "origin":
            flow.origin = value
        elif key == "automated":
            flow.automated = value
        elif key == "human":
            flow.human = value
        if not value:
            flow.problems.append(f"{key} needs a value")
    if flow.automated is not None and flow.human is not None:
        flow.problems.append("a flow is either automated or human, not both")


def parse_file(path):
    """PlanFile from a Markdown area or target file."""
    lines = Path(path).read_text().splitlines()
    title, covers, diagram, flows, problems = None, [], [], [], []
    in_covers = in_mermaid = in_fence = False
    flow, expect_meta = None, False
    for n, raw in enumerate(lines, 1):
        line = raw.rstrip()
        if in_mermaid:
            if line.startswith("```"):
                in_mermaid = False
            else:
                diagram.append(line)
            continue
        if line.startswith("````"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line.startswith("```mermaid"):
            in_mermaid, in_covers = True, False
            continue
        if line.startswith("# ") and title is None:
            title = line[2:].strip()
            continue
        if line == "Covers:":
            in_covers = True
            continue
        if in_covers:
            m = re.match(r"^- `([^`]+)`", line)
            if m:
                covers.append(m.group(1))
                continue
            if line:
                in_covers = False
        if line.startswith("## "):
            heading = line[3:].strip()
            flow = None
            if FLOW_ID.match(heading):
                flow = Flow(heading, path, n)
                flows.append(flow)
                expect_meta = True
            elif heading not in SECTION_HEADINGS:
                problems.append(f"{n}: '## {heading}' is neither a flow id (<area>.<slug>, lowercase "
                                f"and dashes) nor a section ({', '.join(sorted(SECTION_HEADINGS))})")
            continue
        if flow is None:
            continue
        if expect_meta:
            if line:
                parse_meta(flow, line)
                expect_meta = False
            continue
        if line.startswith("**Setup:**"):
            flow.setup = line[len("**Setup:**"):].strip()
        elif line.startswith("**Expect:**"):
            flow.expect = line[len("**Expect:**"):].strip()
        elif STEP.match(line):
            flow.steps += 1
        elif line and not flow.summary and flow.setup is None:
            flow.summary = line
    for f in flows:
        if not f.setup:
            f.problems.append("no **Setup:** line")
        if not f.steps:
            f.problems.append("no numbered steps")
        if not f.expect:
            f.problems.append("no **Expect:** line")
        if not f.summary:
            f.problems.append("no one-line summary")
    return PlanFile(path, title, covers, "\n".join(diagram), flows, problems)


def plan_files(plan_dir):
    paths = sorted(glob.glob(os.path.join(plan_dir, "areas", "*.md")))
    paths += sorted(glob.glob(os.path.join(plan_dir, "targets", "*.md")))
    return [parse_file(p) for p in paths]


def covered(path, covers):
    return any(path == c or (c.endswith("/") and path.startswith(c)) for c in covers)


def read_allow(plan_dir):
    allow = {}
    path = os.path.join(plan_dir, "uncovered.allow")
    if os.path.exists(path):
        for line in Path(path).read_text().splitlines():
            if line.strip() and not line.startswith("#"):
                p, _, reason = line.partition("\t")
                allow[p.strip()] = reason.strip()
    return allow


def test_exists(repo, name):
    cls, _, method = name.partition("/")
    for d in TEST_DIRS:
        for path in glob.glob(os.path.join(repo, d, "**", "*.swift"), recursive=True):
            text = Path(path).read_text(errors="replace")
            if re.search(rf"\bclass {re.escape(cls)}\b", text):
                return not method or re.search(rf"\bfunc {re.escape(method)}\s*\(", text) is not None
    return False


def check(repo, plan_dir):
    """Problems as "<file>:<line>: <text>" strings, and the plan files."""
    files = plan_files(plan_dir)
    problems = []
    rel = lambda p: os.path.relpath(p, repo)  # noqa: E731
    seen = {}
    for pf in files:
        problems.extend(f"{rel(pf.path)}:{p}" for p in pf.problems)
        if not pf.title:
            problems.append(f"{rel(pf.path)}:1: no '# Title' line")
        if not pf.flows:
            problems.append(f"{rel(pf.path)}:1: no flows (## <area>.<slug>)")
        if not pf.diagram:
            problems.append(f"{rel(pf.path)}:1: no mermaid diagram")
        nodes = set(re.findall(r"[A-Za-z0-9][A-Za-z0-9.-]*", pf.diagram))
        for c in pf.covers:
            if not os.path.exists(os.path.join(repo, c.rstrip("/"))):
                problems.append(f"{rel(pf.path)}:1: Covers path does not exist: {c}")
        for f in pf.flows:
            where = f"{rel(f.path)}:{f.line}: {f.id}"
            problems.extend(f"{where}: {p}" for p in f.problems)
            if f.id in seen:
                problems.append(f"{where}: id already used in {rel(seen[f.id])}")
            seen[f.id] = f.path
            if f.id not in nodes:
                problems.append(f"{where}: not in the file's mermaid diagram")
            if f.automated and not test_exists(repo, f.automated):
                problems.append(f"{where}: automated test not found: {f.automated}")
    present = {Path(pf.path).stem for pf in files if os.path.dirname(pf.path).endswith("areas")}
    for area in REQUIRED_AREAS:
        if area not in present:
            problems.append(f"{rel(plan_dir)}/areas/{area}.md: required area has no file")
    all_covers = [c for pf in files for c in pf.covers]
    allow = read_allow(plan_dir)
    extensions = sorted({rel(p) for g in EXTENSION_GLOBS
                         for p in glob.glob(os.path.join(repo, g), recursive=True)})
    for ext in extensions:
        if not covered(ext, all_covers) and ext not in allow:
            problems.append(f"{ext}: +Ecosia extension with no flow; add it to an area's Covers "
                            "or to uncovered.allow with a reason")
    for p, reason in allow.items():
        if not reason:
            problems.append(f"{rel(plan_dir)}/uncovered.allow: {p}: needs a reason")
        if p not in extensions:
            problems.append(f"{rel(plan_dir)}/uncovered.allow: {p}: not an extension file any more")
        elif covered(p, all_covers):
            problems.append(f"{rel(plan_dir)}/uncovered.allow: {p}: covered by an area, remove it")
    map_path = os.path.join(plan_dir, "map.md")
    if not os.path.exists(map_path) or Path(map_path).read_text() != render_map(files, plan_dir):
        problems.append(f"{rel(map_path)}: out of date; run test_plan.py --map")
    return problems, files


def counts(files):
    flows = [f for pf in files for f in pf.flows]
    by = {r: sum(1 for f in flows if f.runner == r) for r in ("agent", "automated", "human")}
    return f"{len(flows)} flows: {by['agent']} agent · {by['automated']} automated · {by['human']} human"


def node(fid):
    return re.sub(r"[^A-Za-z0-9]", "_", fid)


def render_map(files, plan_dir):
    out = ["# Test plan map", "",
           "Generated by `tools/test_plan.py --map` from `areas/` and `targets/`; don't edit by hand.", "",
           counts(files) + ".", "",
           "```mermaid", "flowchart LR",
           "  classDef agent fill:#e3f2e1,stroke:#2e7d32,color:#1b5e20",
           "  classDef automated fill:#e3ecfa,stroke:#1565c0,color:#0d47a1",
           "  classDef human fill:#fdecea,stroke:#c62828,color:#b71c1c",
           "  plan((Upgrade test plan))"]
    for pf in files:
        stem = Path(pf.path).stem
        kind = "target" if os.path.basename(os.path.dirname(pf.path)) == "targets" else "area"
        area = node(f"{kind}_{stem}")
        out.append(f'  plan --> {area}["{pf.title}"]')
        for f in pf.flows:
            out.append(f'  {area} --> {node(f.id)}["{f.id}"]:::{f.runner}')
    out += ["```", "", "Green: agent · blue: automated · red: human.", "",
            "| File | Flows | Agent | Automated | Human |", "| --- | --- | --- | --- | --- |"]
    for pf in files:
        r = [f.runner for f in pf.flows]
        link = os.path.relpath(pf.path, plan_dir)
        out.append(f"| [{pf.title}]({link}) | {len(r)} | {r.count('agent')} | "
                   f"{r.count('automated')} | {r.count('human')} |")
    return "\n".join(out) + "\n"


def affected(repo, plan_dir, rev_range):
    changed = uc.git("diff", "--name-only", rev_range, cwd=repo).split()
    files = plan_files(plan_dir)
    hits = []
    for pf in files:
        relpath = os.path.relpath(pf.path, repo)
        if relpath in changed or any(covered(c, pf.covers) for c in changed):
            hits += [(f.id, relpath) for f in pf.flows]
    return hits


def todo(files, release):
    out = [f"# Run: {release}, <YYYY-MM-DD>, <agent: model | name>, <device> iOS <x>, <locale>", "",
           "**Upgrade build:** `<branch>` at `<commit>` · **Main build:** `main` at `<commit>`", "",
           counts(files) + ". Results: pass, fail, blocked, not run.", "",
           "| Flow | Priority | Runner | Result | Note | Evidence |",
           "| --- | --- | --- | --- | --- | --- |"]
    for pf in files:
        for f in pf.flows:
            result = "automated (CI)" if f.automated else ""
            runner = f"human: {f.human}" if f.human else f.runner
            out.append(f"| `{f.id}` | {f.priority or ''} | {runner} | {result} |  |  |")
    return "\n".join(out) + "\n"


def main(argv):
    parser = uc.Parser(description=__doc__.splitlines()[0])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--check", action="store_true")
    group.add_argument("--map", action="store_true")
    group.add_argument("--affected", metavar="REV_RANGE")
    group.add_argument("--todo", metavar="RELEASE")
    parser.add_argument("--repo", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    repo = args.repo or str(uc.repo_root())
    plan_dir = os.path.join(repo, PLAN_DIR)
    if not os.path.isdir(plan_dir):
        uc.die(f"no test plan at {plan_dir}", uc.ERROR)
    if args.check:
        problems, files = check(repo, plan_dir)
        for p in problems:
            print(p)
        print(counts(files) + (f"; {len(problems)} problems" if problems else ""), file=sys.stderr)
        return uc.FAILED if problems else uc.OK
    if args.map:
        Path(plan_dir, "map.md").write_text(render_map(plan_files(plan_dir), plan_dir))
        return uc.OK
    if args.affected:
        for fid, path in affected(repo, plan_dir, args.affected):
            print(f"{fid}\t{path}")
        return uc.OK
    areas = [pf for pf in plan_files(plan_dir) if os.path.basename(os.path.dirname(pf.path)) == "areas"]
    target = os.path.join(plan_dir, "targets", f"{args.todo}.md")
    if not os.path.exists(target):
        uc.die(f"no target file targets/{args.todo}.md", uc.ERROR)
    sys.stdout.write(todo(areas + [parse_file(target)], args.todo))
    return uc.OK


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
