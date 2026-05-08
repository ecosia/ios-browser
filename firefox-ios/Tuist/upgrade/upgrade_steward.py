#!/usr/bin/env python3
"""
Upgrade Steward demo orchestrator.

Compares Firefox refs, rescans Ecosia customization markers in the tree,
intersects upstream diffs with those files, scores risk areas, and writes:
  - upgrade-steward-report.json
  - upgrade-steward-report.html
  - upgrade-steward-presentation.html

Stdlib only; designed for quick demos and pre-upgrade review.
"""

from __future__ import annotations

import argparse
import contextlib
import html
import importlib.util
import io
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[3]
UPGRADE_DIR = Path(__file__).resolve().parent
CATALOG_SCRIPT = UPGRADE_DIR / "ecosia-customizations-catalog.py"
DEFAULT_REMOTE = "firefox-origin"


@dataclass(frozen=True)
class RiskArea:
    name: str
    description: str
    prefixes: tuple[str, ...]
    review_views: tuple[str, ...]
    weight: int


RISK_AREAS: tuple[RiskArea, ...] = (
    RiskArea(
        name="Homepage",
        description="Homepage layout, top sites, wallpaper, onboarding-adjacent discovery surfaces.",
        prefixes=(
            "firefox-ios/Client/Frontend/Home/",
            "firefox-ios/Client/Ecosia/Frontend/Home/",
        ),
        review_views=("Homepage", "Top sites", "Wallpaper states"),
        weight=5,
    ),
    RiskArea(
        name="Native Components UI",
        description="Address bar, toolbars, menus, tabs, and browser-level native interface around web content.",
        prefixes=(
            "firefox-ios/Client/Frontend/Browser/",
            "firefox-ios/Client/Ecosia/Extensions/BrowserViewController+Ecosia.swift",
            "firefox-ios/Client/Ecosia/UI/PageAction/",
        ),
        review_views=("Browser main screen", "Address bar", "Main menu", "Tab tray"),
        weight=5,
    ),
    RiskArea(
        name="Application Lifecycle",
        description="App launch, scene setup, startup coordination, and early initialization behavior.",
        prefixes=(
            "firefox-ios/Client/Application/",
            "firefox-ios/Client/Coordinators/Launch",
            "firefox-ios/Client/Coordinators/Scene/",
            "firefox-ios/Client/IntroScreenManager.swift",
        ),
        review_views=("Launch flow", "First run", "Scene restore"),
        weight=4,
    ),
    RiskArea(
        name="Settings And Preferences",
        description="Search defaults, settings surfaces, Ecosia-specific preferences, and user-visible toggles.",
        prefixes=(
            "firefox-ios/Client/Frontend/Settings/",
            "firefox-ios/Client/Ecosia/Settings/",
        ),
        review_views=("Settings", "Search provider settings", "Ecosia settings"),
        weight=4,
    ),
    RiskArea(
        name="Telemetry And Analytics",
        description="Analytics wrappers, telemetry plumbing, and Ecosia instrumentation touch points.",
        prefixes=(
            "firefox-ios/Client/Telemetry/",
            "firefox-ios/Client/Frontend/Share/ShareTelemetry.swift",
            "firefox-ios/Ecosia/",
        ),
        review_views=("Analytics smoke flow", "Search event flow", "Settings events"),
        weight=4,
    ),
    RiskArea(
        name="Account And Sync",
        description="Auth flows, sync integration, and account-related state transitions.",
        prefixes=(
            "firefox-ios/Account/",
            "firefox-ios/Providers/RustSyncManager.swift",
            "firefox-ios/Client/Ecosia/Account/",
        ),
        review_views=("Sign-in", "Sync status", "Account recovery"),
        weight=3,
    ),
    RiskArea(
        name="Storage And Search Defaults",
        description="Search provider defaults, suggested sites, autofill, logins, and persistence-sensitive changes.",
        prefixes=(
            "firefox-ios/Storage/",
            "firefox-ios/Client/Frontend/Browser/Search",
            "firefox-ios/Client/Frontend/Browser/SearchEngines/",
        ),
        review_views=("Search defaults", "Suggested sites", "Autofill/login smoke"),
        weight=3,
    ),
    RiskArea(
        name="Tests And Fixtures",
        description="High-signal tests that document or enforce Ecosia behavior during upgrades.",
        prefixes=(
            "firefox-ios/firefox-ios-tests/",
            "firefox-ios/EcosiaTests/",
        ),
        review_views=("Snapshot test review", "Focused smoke tests"),
        weight=2,
    ),
)


def run_git(args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def load_catalog_module():
    spec = importlib.util.spec_from_file_location("ecosia_catalog", CATALOG_SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load catalog module from {CATALOG_SCRIPT}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_version_token(ref_name: str) -> tuple[int, ...]:
    match = re.search(r"v(\d+(?:\.\d+)*)", ref_name)
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("."))


def format_version(version: Iterable[int]) -> str:
    parts = list(version)
    return ".".join(str(part) for part in parts) if parts else "unknown"


def list_release_refs(remote: str) -> list[str]:
    output = run_git(["for-each-ref", "--format=%(refname)", f"refs/remotes/{remote}/release"])
    return [line for line in output.splitlines() if line]


def list_local_firefox_bases() -> list[str]:
    output = run_git(["for-each-ref", "--format=%(refname)", "refs/heads"])
    return [line for line in output.splitlines() if line.startswith("refs/heads/firefox-v")]


def short_ref(ref_name: str) -> str:
    if ref_name.startswith("refs/heads/"):
        return ref_name.removeprefix("refs/heads/")
    if ref_name.startswith("refs/remotes/"):
        return ref_name.removeprefix("refs/remotes/")
    return ref_name


def is_ancestor(branch: str, ref: str) -> bool:
    result = subprocess.run(
        ["git", "merge-base", "--is-ancestor", branch, ref],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def merge_base(left: str, right: str) -> str:
    return run_git(["merge-base", left, right])


def distance_from_merge_base(branch: str, ref: str) -> int:
    base = merge_base(branch, ref)
    return int(run_git(["rev-list", "--count", f"{base}..{branch}"]))


def infer_current_base_ref(current_ref: str) -> str:
    candidates = []
    for branch in list_local_firefox_bases():
        if is_ancestor(branch, current_ref):
            candidates.append((parse_version_token(branch), branch))
    if candidates:
        return short_ref(sorted(candidates)[-1][1])

    fallback_candidates = []
    for branch in list_local_firefox_bases():
        fallback_candidates.append(
            (distance_from_merge_base(branch, current_ref), parse_version_token(branch), branch)
        )
    if not fallback_candidates:
        raise RuntimeError("Could not infer current Firefox base. Pass --base-ref explicitly.")
    return short_ref(sorted(fallback_candidates)[0][2])


def infer_latest_release_ref(remote: str) -> str:
    refs = list_release_refs(remote)
    if not refs:
        raise RuntimeError(f"Could not find release refs under remote '{remote}'.")
    return short_ref(sorted(((parse_version_token(ref), ref) for ref in refs))[-1][1])


def build_catalog(scan_dir: Path) -> dict[str, Any]:
    module = load_catalog_module()
    with contextlib.redirect_stdout(io.StringIO()):
        customizations, base_path = module.scan_directory(scan_dir)
    for custom in customizations:
        try:
            custom.file_path = str(Path(custom.file_path).relative_to(base_path))
        except Exception:
            pass
        if not str(custom.file_path).startswith("firefox-ios/"):
            custom.file_path = f"firefox-ios/{custom.file_path}"
    return module.generate_catalog(customizations)


def changed_files_between(base_ref: str, target_ref: str) -> list[str]:
    output = run_git(["diff", "--name-only", f"{base_ref}..{target_ref}"])
    return sorted(line for line in output.splitlines() if line)


def classify_risk_areas(file_path: str) -> list[RiskArea]:
    matched = []
    for area in RISK_AREAS:
        if any(file_path.startswith(prefix) for prefix in area.prefixes):
            matched.append(area)
    return matched


def risk_label(score: int) -> str:
    if score >= 12:
        return "high"
    if score >= 7:
        return "medium"
    return "low"


def recommendation_for(
    impacted_count: int, high_count: int, total_changed: int
) -> tuple[str, str, int]:
    if high_count >= 8 or impacted_count >= 35:
        return (
            "Blocked For Human Review",
            "This upgrade touches too many Ecosia-sensitive files to treat as low-touch. "
            "A steward can still focus attention, but this should not auto-merge.",
            28,
        )
    if high_count >= 3 or impacted_count >= 10:
        return (
            "Review Required",
            "The steward narrows the review surface, but humans should validate "
            "native components UI, homepage, and lifecycle changes.",
            56,
        )
    if impacted_count > 0:
        return (
            "Probably Safe After Focused Checks",
            "Limited Ecosia-sensitive changes. Focused validation and screenshots "
            "before merging should be enough.",
            74,
        )
    if total_changed > 0:
        return (
            "Low-Touch Upgrade Candidate",
            "No tracked Ecosia customizations in the changed file set. Standard validation "
            "may be enough once build and smoke checks are green.",
            88,
        )
    return (
        "No Upgrade Delta Detected",
        "The chosen refs do not differ.",
        95,
    )


def build_follow_up_questions(top_areas: list[dict[str, Any]]) -> list[str]:
    questions = []
    for area in top_areas[:4]:
        area_name = area["name"]
        if area_name == "Homepage":
            questions.append(
                "Are we OK adopting upstream homepage changes as-is, or keep the current Ecosia layout?"
            )
        elif area_name == "Native Components UI":
            questions.append(
                "Do upstream native components UI changes clash with Ecosia menus, toolbar, or tabs?"
            )
        elif area_name == "Application Lifecycle":
            questions.append(
                "Are launch and scene changes safe for Ecosia startup and first-run behavior?"
            )
        elif area_name == "Settings And Preferences":
            questions.append(
                "Did upstream settings change Ecosia defaults, search prefs, or visible toggles?"
            )
        elif area_name == "Telemetry And Analytics":
            questions.append(
                "Do telemetry changes keep Ecosia analytics semantics, or need a manual pass?"
            )
        elif area_name == "Account And Sync":
            questions.append(
                "Are sign-in and sync changes compatible with Ecosia account flows?"
            )
    if not questions:
        questions.append(
            "No high-risk areas flagged. Is a low-touch upgrade OK after build and smoke validation?"
        )
    return questions


def html_list(items: list[str], empty: str = "None") -> str:
    if not items:
        return f"<p>{html.escape(empty)}</p>"
    return "<ul>" + "".join(f"<li>{html.escape(item)}</li>" for item in items) + "</ul>"


def render_report_html(report: dict[str, Any]) -> str:
    area_cards = []
    for area in report["top_impacted_areas"]:
        views = ", ".join(area["review_views"])
        area_cards.append(
            f"""
            <div class="card">
              <h3>{html.escape(area['name'])}</h3>
              <p>{html.escape(area['description'])}</p>
              <p><strong>Changed files:</strong> {area['changed_files']}</p>
              <p><strong>Ecosia-sensitive files:</strong> {area['impacted_customized_files']}</p>
              <p><strong>Suggested review views:</strong> {html.escape(views)}</p>
            </div>
            """
        )

    file_rows = []
    for file_info in report["top_impacted_files"]:
        areas = ", ".join(file_info["areas"]) or "General"
        reasons = "; ".join(file_info["reasons"])
        file_rows.append(
            f"""
            <tr>
              <td><code>{html.escape(file_info['path'])}</code></td>
              <td>{html.escape(file_info['risk'])}</td>
              <td>{file_info['customization_count']}</td>
              <td>{html.escape(areas)}</td>
              <td>{html.escape(reasons)}</td>
            </tr>
            """
        )

    status_color = (
        "var(--danger)"
        if report["recommendation"]["status"].startswith("Blocked")
        else "var(--warn)"
        if "Review" in report["recommendation"]["status"]
        else "var(--accent-2)"
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Upgrade Steward Report</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #0b1020;
      --muted: #8fa0c0;
      --text: #eef4ff;
      --accent: #70d6ff;
      --accent-2: #5ee37b;
      --warn: #ffcc66;
      --danger: #ff7a90;
      --border: #24304d;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: linear-gradient(180deg, #0b1020 0%, #09111d 100%);
      color: var(--text);
    }}
    .container {{ max-width: 1180px; margin: 0 auto; padding: 32px 24px 64px; }}
    h1, h2, h3 {{ margin: 0 0 12px; }}
    p {{ color: var(--muted); line-height: 1.5; }}
    .hero {{
      display: grid;
      gap: 18px;
      margin-bottom: 28px;
      padding: 28px;
      border: 1px solid var(--border);
      border-radius: 20px;
      background: rgba(19, 26, 43, 0.95);
    }}
    .badge {{
      display: inline-flex;
      width: fit-content;
      padding: 6px 10px;
      border-radius: 999px;
      background: rgba(112, 214, 255, 0.12);
      color: var(--accent);
      font-weight: 700;
      letter-spacing: 0.02em;
      text-transform: uppercase;
      font-size: 12px;
    }}
    .metrics {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
      margin: 24px 0;
    }}
    .metric, .card {{
      padding: 18px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(19, 26, 43, 0.92);
    }}
    .metric strong {{
      display: block;
      font-size: 28px;
      color: var(--text);
      margin-bottom: 6px;
    }}
    .section {{ margin-top: 28px; }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 16px;
      background: rgba(19, 26, 43, 0.92);
      border: 1px solid var(--border);
      border-radius: 18px;
      overflow: hidden;
    }}
    th, td {{
      text-align: left;
      padding: 14px 16px;
      border-bottom: 1px solid var(--border);
      vertical-align: top;
    }}
    th {{ color: var(--accent); font-size: 13px; text-transform: uppercase; letter-spacing: 0.04em; }}
    code {{
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      color: #d9e8ff;
      word-break: break-word;
    }}
    .status {{
      color: {status_color};
      font-weight: 800;
    }}
    .note {{
      padding: 18px;
      border-left: 3px solid var(--accent);
      background: rgba(112, 214, 255, 0.08);
      border-radius: 14px;
      color: var(--text);
    }}
  </style>
</head>
<body>
  <div class="container">
    <section class="hero">
      <span class="badge">Upgrade Steward</span>
      <div>
        <h1>Firefox upgrade review</h1>
        <p>
          Compares <code>{html.escape(report['base_ref'])}</code> with
          <code>{html.escape(report['target_ref'])}</code>, intersects upstream changes with
          the current Ecosia customization scan, and surfaces where review matters.
        </p>
      </div>
      <div class="note">
        <strong class="status">{html.escape(report['recommendation']['status'])}</strong><br />
        {html.escape(report['recommendation']['summary'])}
      </div>
    </section>

    <section class="metrics">
      <div class="metric"><strong>{report['summary']['total_upstream_changed_files']}</strong>upstream changed files</div>
      <div class="metric"><strong>{report['summary']['catalog_customizations']}</strong>tracked Ecosia customizations</div>
      <div class="metric"><strong>{report['summary']['impacted_customized_files']}</strong>Ecosia-sensitive files impacted</div>
      <div class="metric"><strong>{report['summary']['high_risk_impacted_files']}</strong>high-risk files</div>
      <div class="metric"><strong>{report['recommendation']['confidence']}</strong>confidence / 100</div>
    </section>

    <section class="section">
      <h2>🔥 Top impacted areas</h2>
      <div class="grid">
        {''.join(area_cards) if area_cards else '<p>No impacted areas found.</p>'}
      </div>
    </section>

    <section class="section">
      <h2>📸 Suggested screenshots for the demo</h2>
      {html_list(report["suggested_screenshots"], "No suggested screenshots yet.")}
    </section>

    <section class="section">
      <h2>❓ Follow-up questions the steward would ask</h2>
      {html_list(report["follow_up_questions"], "No follow-up questions.")}
    </section>

    <section class="section">
      <h2>🧭 Most impacted Ecosia-sensitive files</h2>
      <table>
        <thead>
          <tr>
            <th>File</th>
            <th>Risk</th>
            <th>Customizations</th>
            <th>Areas</th>
            <th>Why it matters</th>
          </tr>
        </thead>
        <tbody>
          {''.join(file_rows) if file_rows else '<tr><td colspan="5">No impacted customized files found.</td></tr>'}
        </tbody>
      </table>
    </section>

    <section class="section">
      <h2>✨ What this demo does today</h2>
      <div class="grid">
        <div class="card"><h3>Release-aware</h3><p>Uses git refs for base and target Firefox releases.</p></div>
        <div class="card"><h3>Intent-aware</h3><p>Rebuilds the customization catalog from the current tree.</p></div>
        <div class="card"><h3>Review-aware</h3><p>Maps files to Ecosia-sensitive areas and screenshot hints.</p></div>
        <div class="card"><h3>Presentation-ready</h3><p>Writes JSON, HTML report, and HTML deck.</p></div>
      </div>
    </section>

    <section class="section">
      <p>Generated at {html.escape(report['generated_at'])} from branch <code>{html.escape(report['current_branch'])}</code>.</p>
    </section>
  </div>
</body>
</html>
"""


def render_presentation_html(report: dict[str, Any]) -> str:
    area_names = ", ".join(area["name"] for area in report["top_impacted_areas"][:4]) or "No high-risk areas"
    screenshot_names = ", ".join(report["suggested_screenshots"][:6]) or "Focused smoke screenshots"
    question_names = report["follow_up_questions"][:3]

    file_cards = "".join(
        f"""
        <div class="file-card">
          <div class="file-risk file-risk-{html.escape(file_info['risk'])}">{html.escape(file_info['risk'])}</div>
          <code>{html.escape(file_info['path'])}</code>
          <p>{html.escape(', '.join(file_info['areas']) or 'General')}</p>
        </div>
        """
        for file_info in report["top_impacted_files"][:5]
    ) or '<div class="file-card"><p>No impacted customized files.</p></div>'

    slides = [
        (
            "Upgrade Steward",
            f"""
            <p class="eyebrow">Native Apps 2026 Spring Event Hackathon</p>
            <h1>Upgrade Steward</h1>
            <p>
              We used this hackathon to rethink Firefox upgrades.
              The goal is simple: spend less time on upgrade work and more time on Ecosia product work.
            </p>
            <p class="meta">
              Our idea: an agent that keeps up with Firefox, points out what matters for Ecosia,
              and asks for help only when product judgement is needed.
            </p>
            """,
        ),
        (
            "The Problem",
            """
            <h2>🧩 The problem we wanted to solve</h2>
            <ul>
              <li>Firefox upgrades are not hard only because of conflicts.</li>
              <li>The bigger problem is knowing what might break on the Ecosia side.</li>
              <li>People still read a lot of code to figure out what deserves attention.</li>
            </ul>
            """,
        ),
        (
            "What We Learned",
            f"""
            <h2>🔎 What we learned from the tools we already had</h2>
            <ul>
              <li>Tuist and the conflict helper already make upgrades easier.</li>
              <li>We also have <strong>{report['summary']['catalog_customizations']}</strong> tracked Firefox-side Ecosia customizations in the current tree.</li>
              <li>Those tools mostly help during the rebase, not before or after it.</li>
              <li>The missing piece is a steward that gives us confidence.</li>
            </ul>
            """,
        ),
        (
            "The Idea",
            """
            <h2>💡 Our idea for the hackathon</h2>
            <p>
              We changed the goal from “resolve upgrade conflicts” to
              “reduce how much the team has to think about upgrades”.
            </p>
            <div class="pipeline">
              <div>Detect release</div>
              <div>Map Ecosia impact</div>
              <div>Score risk</div>
              <div>Show what to check</div>
              <div>Ask clear questions</div>
              <div>Guide merge decision</div>
            </div>
            """,
        ),
        (
            "What We Built",
            f"""
            <h2>🛠️ What we built in a few hours</h2>
            <ul>
              <li>A working steward prototype on top of the current upgrade tools.</li>
              <li>It compares a Firefox base with a target release.</li>
              <li>It refreshes the current Ecosia customization map from the repo.</li>
              <li>It highlights the product areas that matter most and gives a review recommendation.</li>
            </ul>
            """,
        ),
        (
            "What The Prototype Shows",
            f"""
            <h2>📊 What the prototype shows on this repo</h2>
            <ul>
              <li><strong>{report['summary']['total_upstream_changed_files']}</strong> upstream changed files in the selected upgrade path.</li>
              <li><strong>{report['summary']['impacted_customized_files']}</strong> Ecosia-sensitive files touched by that change.</li>
              <li>The main review areas are <strong>{html.escape(area_names)}</strong>.</li>
              <li>Instead of a full manual sweep, the steward narrows the review surface.</li>
            </ul>
            """,
        ),
        (
            "Screenshots And Questions",
            f"""
            <h2>🎯 How the steward reduces review effort</h2>
            <p><strong>Suggested screenshots:</strong> {html.escape(screenshot_names)}</p>
            <ul>
              {''.join(f'<li>{html.escape(question)}</li>' for question in question_names)}
            </ul>
            """,
        ),
        (
            "High-Signal Files",
            f"""
            <h2>👀 Where the team should look first</h2>
            <p>These are the files the steward would put at the top of the review list.</p>
            <div class="file-grid">{file_cards}</div>
            """,
        ),
        (
            "Why It Matters",
            f"""
            <h2>✅ Why this matters</h2>
            <ul>
              <li>The agent does the sorting and the team does the product decisions.</li>
              <li>Upgrade work becomes smaller, clearer, and easier to review.</li>
              <li>The long-term goal is a background workflow that keeps Ecosia close to Firefox without constant manual effort.</li>
            </ul>
            """,
        ),
        (
            "Takeaway",
            f"""
            <h2>🚀 What we worked out in this hackathon</h2>
            <ul>
              <li>The right direction is an <strong>Upgrade Steward</strong>, not just more upgrade scripts.</li>
              <li>It tells us which Ecosia areas need attention first.</li>
              <li>It can grow into a background workflow with build checks, screenshots, and merge guidance.</li>
            </ul>
            <h3>Next step</h3>
            <p class="meta"><a class="report-link" href="upgrade-steward-report.html">Open the steward report and walk through one real upgrade path.</a></p>
            """,
        ),
    ]

    slide_markup = []
    for title, body in slides:
        slide_markup.append(
            f"""
            <section class="slide">
              <div class="frame">
                {body}
                <div class="footer">{html.escape(title)}</div>
              </div>
            </section>
            """
        )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Upgrade Steward Presentation</title>
  <style>
    :root {{
      color-scheme: dark;
      --border: #223550;
      --text: #eef4ff;
      --muted: #9fb0cb;
      --accent: #70d6ff;
      --accent-2: #9df4a7;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      overflow: hidden;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: radial-gradient(circle at top left, #0c1f38, #07111e 55%);
      color: var(--text);
    }}
    .deck {{
      display: flex;
      width: 100vw;
      height: 100vh;
      transition: transform 220ms ease;
    }}
    .slide {{
      min-width: 100vw;
      height: 100vh;
      padding: 36px;
    }}
    .frame {{
      width: 100%;
      height: 100%;
      border-radius: 28px;
      border: 1px solid var(--border);
      background: linear-gradient(180deg, rgba(16, 28, 47, 0.98), rgba(11, 20, 35, 0.96));
      padding: 56px 64px;
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 22px;
      position: relative;
      box-shadow: 0 30px 80px rgba(0, 0, 0, 0.28);
    }}
    h1 {{
      font-size: clamp(42px, 6vw, 74px);
      line-height: 1.03;
      margin: 0;
    }}
    h2 {{
      font-size: clamp(34px, 4vw, 56px);
      margin: 0;
    }}
    h3 {{
      font-size: clamp(24px, 2.5vw, 34px);
      margin: 6px 0 0;
    }}
    p, li {{
      font-size: clamp(20px, 2.1vw, 30px);
      line-height: 1.45;
      color: var(--muted);
    }}
    ul {{
      margin: 0;
      padding-left: 28px;
      display: grid;
      gap: 12px;
    }}
    strong {{ color: var(--text); }}
    code {{
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      color: var(--accent);
      overflow-wrap: anywhere;
      word-break: break-word;
    }}
    .eyebrow {{
      text-transform: uppercase;
      letter-spacing: 0.08em;
      font-weight: 800;
      color: var(--accent);
      font-size: 15px;
      margin-bottom: 8px;
    }}
    .meta {{ color: var(--accent-2); }}
    .pipeline {{
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 18px;
    }}
    .pipeline div {{
      padding: 20px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(112, 214, 255, 0.08);
      font-size: 24px;
      font-weight: 700;
      text-align: center;
    }}
    .file-grid {{
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 16px;
    }}
    .file-card {{
      padding: 18px 20px;
      border-radius: 18px;
      border: 1px solid var(--border);
      background: rgba(112, 214, 255, 0.07);
      display: grid;
      gap: 10px;
      align-content: start;
      min-height: 150px;
    }}
    .file-card code {{ font-size: 18px; line-height: 1.4; }}
    .file-card p {{ margin: 0; font-size: 18px; line-height: 1.35; }}
    .file-risk {{
      width: fit-content;
      padding: 6px 10px;
      border-radius: 999px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-size: 13px;
      font-weight: 800;
      color: var(--text);
      background: rgba(112, 214, 255, 0.12);
    }}
    .file-risk-high {{ background: rgba(255, 122, 144, 0.18); }}
    .file-risk-medium {{ background: rgba(255, 204, 102, 0.18); }}
    .file-risk-low {{ background: rgba(157, 244, 167, 0.18); }}
    .footer {{
      position: absolute;
      right: 28px;
      bottom: 22px;
      color: var(--muted);
      font-size: 14px;
      letter-spacing: 0.05em;
      text-transform: uppercase;
    }}
    .controls {{
      position: fixed;
      right: 18px;
      bottom: 18px;
      display: flex;
      gap: 10px;
      z-index: 20;
    }}
    button {{
      border: 1px solid var(--border);
      background: rgba(16, 28, 47, 0.94);
      color: var(--text);
      padding: 10px 14px;
      border-radius: 12px;
      font-size: 14px;
      cursor: pointer;
    }}
    .counter {{
      position: fixed;
      left: 18px;
      bottom: 18px;
      color: var(--muted);
      font-size: 14px;
    }}
    .report-link {{
      color: var(--accent-2);
      text-decoration: none;
      border-bottom: 1px solid rgba(157, 244, 167, 0.45);
      padding-bottom: 2px;
    }}
    .report-link:hover {{
      color: var(--text);
      border-bottom-color: rgba(238, 244, 255, 0.7);
    }}
  </style>
</head>
<body>
  <div class="deck" id="deck">
    {''.join(slide_markup)}
  </div>
  <div class="controls">
    <button id="prev">Prev</button>
    <button id="next">Next</button>
  </div>
  <div class="counter" id="counter"></div>
  <script>
    const deck = document.getElementById("deck");
    const slides = Array.from(document.querySelectorAll(".slide"));
    const counter = document.getElementById("counter");
    let index = 0;
    function render() {{
      deck.style.transform = `translateX(${{-index * 100}}vw)`;
      counter.textContent = `Slide ${{index + 1}} / ${{slides.length}}`;
    }}
    function next() {{
      index = Math.min(index + 1, slides.length - 1);
      render();
    }}
    function prev() {{
      index = Math.max(index - 1, 0);
      render();
    }}
    document.getElementById("next").addEventListener("click", next);
    document.getElementById("prev").addEventListener("click", prev);
    window.addEventListener("keydown", (event) => {{
      if (event.key === "ArrowRight" || event.key === " ") next();
      if (event.key === "ArrowLeft") prev();
    }});
    render();
  </script>
</body>
</html>
"""


def build_report(base_ref: str, target_ref: str, current_ref: str, remote: str) -> dict[str, Any]:
    catalog = build_catalog(ROOT / "firefox-ios")
    changed_files = changed_files_between(base_ref, target_ref)
    customized_by_file: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for customization in catalog["customizations"]:
        customized_by_file[customization["file"]].append(customization)

    impacted_files = []
    area_rollup: dict[str, dict[str, Any]] = {}
    screenshot_candidates: set[str] = set()

    for changed_file in changed_files:
        areas = classify_risk_areas(changed_file)
        customizations = customized_by_file.get(changed_file, [])

        for area in areas:
            bucket = area_rollup.setdefault(
                area.name,
                {
                    "name": area.name,
                    "description": area.description,
                    "changed_files": 0,
                    "impacted_customized_files": 0,
                    "review_views": list(area.review_views),
                    "weight": area.weight,
                },
            )
            bucket["changed_files"] += 1
            if customizations:
                bucket["impacted_customized_files"] += 1

        if not customizations:
            continue

        type_counts = Counter(customization["type"] for customization in customizations)
        score = sum(area.weight for area in areas)
        reasons = []
        if areas:
            reasons.append("touches high-signal product area")
            screenshot_candidates.update(view for area in areas for view in area.review_views)
        if len(customizations) >= 10:
            score += 5
            reasons.append("many Ecosia customizations in one file")
        elif len(customizations) >= 4:
            score += 3
            reasons.append("multiple Ecosia customizations in one file")
        if type_counts.get("substitution", 0):
            score += 2
            reasons.append("contains substitution-style overrides")
        if type_counts.get("removal", 0) >= 3:
            score += 1
            reasons.append("contains several Firefox removals")

        impacted_files.append(
            {
                "path": changed_file,
                "customization_count": len(customizations),
                "dominant_customization_type": type_counts.most_common(1)[0][0],
                "areas": [area.name for area in areas],
                "risk": risk_label(score),
                "score": score,
                "reasons": reasons or ["tracked Ecosia customization"],
            }
        )

    impacted_files.sort(key=lambda item: (item["score"], item["customization_count"]), reverse=True)
    top_areas = sorted(
        area_rollup.values(),
        key=lambda item: (item["impacted_customized_files"], item["changed_files"], item["weight"]),
        reverse=True,
    )
    high_risk_count = len([f for f in impacted_files if f["risk"] == "high"])
    status, summary, confidence = recommendation_for(len(impacted_files), high_risk_count, len(changed_files))

    if not screenshot_candidates:
        screenshot_candidates = {"Homepage", "Browser main screen", "Address bar", "Settings"}

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "current_branch": run_git(["branch", "--show-current"]),
        "current_ref": current_ref,
        "base_ref": base_ref,
        "base_version": format_version(parse_version_token(base_ref)),
        "target_ref": target_ref,
        "target_version": format_version(parse_version_token(target_ref)),
        "remote": remote,
        "summary": {
            "total_upstream_changed_files": len(changed_files),
            "catalog_customizations": catalog["summary"]["total"],
            "catalog_files_affected": catalog["summary"]["files_affected"],
            "impacted_customized_files": len(impacted_files),
            "high_risk_impacted_files": high_risk_count,
        },
        "recommendation": {
            "status": status,
            "summary": summary,
            "confidence": confidence,
        },
        "top_impacted_areas": top_areas[:6],
        "top_impacted_files": impacted_files[:12],
        "suggested_screenshots": sorted(screenshot_candidates),
        "follow_up_questions": build_follow_up_questions(top_areas),
        "raw": {
            "changed_files": changed_files,
            "impacted_customized_files": impacted_files,
        },
    }
    return report


def write_outputs(report: dict[str, Any], output_dir: Path) -> dict[str, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "upgrade-steward-report.json"
    html_path = output_dir / "upgrade-steward-report.html"
    slides_path = output_dir / "upgrade-steward-presentation.html"

    json_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    html_path.write_text(render_report_html(report), encoding="utf-8")
    slides_path.write_text(render_presentation_html(report), encoding="utf-8")

    return {"json": json_path, "report_html": html_path, "presentation_html": slides_path}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate upgrade steward report and presentation.")
    parser.add_argument("--base-ref", help="Firefox base ref (auto-inferred if omitted).")
    parser.add_argument("--target-ref", help="Target Firefox release ref (auto-inferred if omitted).")
    parser.add_argument("--current-ref", default="HEAD", help="Ref for inference context (default HEAD).")
    parser.add_argument("--remote", default=DEFAULT_REMOTE, help=f"Upstream remote (default {DEFAULT_REMOTE}).")
    parser.add_argument(
        "--output-dir",
        default=str(UPGRADE_DIR / "demo-output"),
        help="Output directory for artifacts.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        base_ref = args.base_ref or infer_current_base_ref(args.current_ref)
        target_ref = args.target_ref or infer_latest_release_ref(args.remote)
        report = build_report(base_ref, target_ref, args.current_ref, args.remote)
        output_paths = write_outputs(report, Path(args.output_dir))
    except subprocess.CalledProcessError as error:
        stderr = error.stderr.strip() if error.stderr else "No stderr."
        print(f"Git command failed: {stderr}", file=sys.stderr)
        return 1
    except Exception as error:
        print(f"Upgrade steward failed: {error}", file=sys.stderr)
        return 1

    print("Upgrade steward artifacts generated:")
    for name, path in output_paths.items():
        print(f"  - {name}: {path}")
    print("")
    print("Headline:")
    print(f"  {report['recommendation']['status']} ({report['recommendation']['confidence']}/100 confidence)")
    print(f"  Base:   {report['base_ref']}")
    print(f"  Target: {report['target_ref']}")
    print(f"  Impacted Ecosia-sensitive files: {report['summary']['impacted_customized_files']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
