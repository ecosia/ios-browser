#!/usr/bin/env python3
"""Tests for source_scan.py, swallowed_declarations.py and conflict_risk.py.

Run: python3 -I firefox-ios/EcosiaUpgrade/tools/tools.test.py
"""

import subprocess
import sys
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import conflict_risk  # noqa: E402
import source_scan as ss  # noqa: E402
import swallowed_declarations  # noqa: E402

BOOKMARKS = "firefox-ios/Client/Frontend/Library/Bookmarks/BookmarksViewController.swift"


def kinds_of(text, needle, syntax="swift"):
    """The classification of each character of the first `needle` in `text`."""
    start = text.index(needle)
    return set(ss.classify(text, syntax)[start:start + len(needle)])


class SwiftClassifyTests(unittest.TestCase):
    def test_line_comment(self):
        text = 'let a = 1 // Ecosia: note\nlet b = 2\n'
        self.assertEqual(kinds_of(text, "Ecosia: note"), {ss.COMMENT})
        self.assertEqual(kinds_of(text, "let b"), {ss.CODE})

    def test_nested_block_comment(self):
        text = "/* Ecosia: outer\n/* inner */\nfunc hidden() {}\n*/\nfunc live() {}\n"
        self.assertEqual(kinds_of(text, "func hidden"), {ss.COMMENT})
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_comment_markers_inside_string_are_string(self):
        text = 'let s = "/* not a comment // Ecosia: no"\nfunc live() {}\n'
        self.assertEqual(kinds_of(text, "Ecosia: no"), {ss.STRING})
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_escaped_quote(self):
        text = 'let s = "a \\" /* b"\nfunc live() {}\n'
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_multiline_string(self):
        text = 'let s = """\n// Ecosia: in string\n"quoted"\n"""\nfunc live() {}\n'
        self.assertEqual(kinds_of(text, "Ecosia: in string"), {ss.STRING})
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_raw_string(self):
        text = 'let s = #"a "quoted" \\(x) /* b"#\nfunc live() {}\n'
        self.assertEqual(kinds_of(text, "/* b"), {ss.STRING})
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_interpolation_is_code(self):
        text = 'let s = "a \\(foo.bar("x")) b"\n'
        self.assertEqual(kinds_of(text, "foo.bar"), {ss.CODE})
        self.assertEqual(kinds_of(text, " b"), {ss.STRING})

    def test_unterminated_string_stops_at_line_end(self):
        text = 'let s = "oops\nfunc live() {}\n'
        self.assertEqual(kinds_of(text, "func live"), {ss.CODE})

    def test_code_only_keeps_lines(self):
        text = "a /* x\ny */ b // z\nc\n"
        self.assertEqual(ss.code_only(text), "a     \n     b     \nc\n")


class OtherSyntaxTests(unittest.TestCase):
    def test_syntax_for(self):
        self.assertEqual(ss.syntax_for("a/B.swift"), "swift")
        self.assertEqual(ss.syntax_for("a/en.lproj/Localizable.strings"), "c")
        self.assertEqual(ss.syntax_for("a/Common.xcconfig"), "slash")
        self.assertEqual(ss.syntax_for("a/b.yml"), "hash")
        self.assertEqual(ss.syntax_for(".githooks/pre-push", "#!/bin/bash\n"), "hash")
        self.assertEqual(ss.syntax_for("Gemfile"), "hash")
        self.assertEqual(ss.syntax_for("a/Info.plist"), "xml")
        self.assertEqual(ss.syntax_for("a/blob.bin"), "plain")

    def test_hash_comment_needs_whitespace_and_no_quote(self):
        text = 'x: "a # Ecosia: in string"\ny: ${#n} # Ecosia: comment\n'
        self.assertEqual(kinds_of(text, "Ecosia: in string", "hash"), {ss.STRING})
        self.assertEqual(kinds_of(text, "#n", "hash"), {ss.CODE})
        self.assertEqual(kinds_of(text, "Ecosia: comment", "hash"), {ss.COMMENT})

    def test_xcconfig_slashes_are_comments(self):
        text = "A = https://example\n// Ecosia: note\n"
        self.assertEqual(kinds_of(text, "Ecosia: note", "slash"), {ss.COMMENT})

    def test_xml_comment(self):
        text = "<key>a</key><!-- Ecosia: note --><string>Ecosia: value</string>\n"
        self.assertEqual(kinds_of(text, "Ecosia: note", "xml"), {ss.COMMENT})
        self.assertEqual(kinds_of(text, "Ecosia: value", "xml"), {ss.CODE})


class MarkerTests(unittest.TestCase):
    def test_markers_in_comments_only(self):
        text = ('// Ecosia: one\n'
                'let s = "Ecosia: not a marker"\n'
                '/* Ecosia: two\n'
                'old()\n'
                '*/\n')
        self.assertEqual(ss.marker_lines(text, "A.swift"), [1, 3])

    def test_no_marker(self):
        self.assertEqual(ss.marker_lines('let s = "Ecosia: x"\n', "A.swift"), [])


class SwallowedDeclarationTests(unittest.TestCase):
    def test_finds_call_to_function_declared_in_comment(self):
        text = ("func viewDidLoad() {\n"
                "    setupLayout()\n"
                "}\n"
                "/* Ecosia: replace setup\n"
                "func setupLayout() {}\n"
                "func setupEmptyStateView() {}\n"
                "*/\n")
        self.assertEqual(swallowed_declarations.check("A.swift", text), [(2, "setupLayout", 5)])

    def test_live_redeclaration_is_fine(self):
        text = ("/* Ecosia: replace\n"
                "func setup() { old() }\n"
                "*/\n"
                "func setup() { new() }\n"
                "func run() { self.setup() }\n")
        self.assertEqual(swallowed_declarations.check("A.swift", text), [])

    def test_calls_on_other_objects_and_in_comments_are_ignored(self):
        text = ("/* Ecosia: removed\n"
                "func reload() {}\n"
                "*/\n"
                "func run() { tableView.reload(); /* reload() */ }\n")
        self.assertEqual(swallowed_declarations.check("A.swift", text), [])

    def test_bookmarks_merge_defect(self):
        """The 155.1 experiment's defect, rebuilt from today's file: move the `/* Ecosia:` opener back
        above the three methods 155.1 added, where the merge left it."""
        root = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                                   text=True, check=True).stdout.strip())
        text = (root / BOOKMARKS).read_text()
        opener = "    /* Ecosia: Replace Firefox empty state setup with Ecosia empty bookmarks view."
        self.assertEqual(swallowed_declarations.check(BOOKMARKS, text), [])
        start = text.index(opener)
        end = text.index("\n", text.index("where this block used to open.", start)) + 1
        block_opener = text[start:end]
        text = text[:start] + text[end:]
        anchor = text.index("    // MARK: - UI Setup\n    private func setupLayout()")
        broken = text[:anchor] + block_opener + text[anchor:]
        names = {name for _, name, _ in swallowed_declarations.check(BOOKMARKS, broken)}
        self.assertEqual(names, {"setupLayout", "updateLayoutForKeyboard", "updateBottomSearchBarLayout"})


class ConflictRiskTests(unittest.TestCase):
    def test_numstat_counts_added_and_removed_and_binary_as_zero(self):
        text = "3\t2\tA.swift\0-\t-\tlogo.pdf\0"
        self.assertEqual(conflict_risk.parse_numstat(text), {"A.swift": 5, "logo.pdf": 0})

    def test_commit_counts_count_each_commit_once_per_file(self):
        text = "\x01\0\nA.swift\0B.swift\0\x01\0\nA.swift\0"
        self.assertEqual(conflict_risk.parse_commit_counts(text), {"A.swift": 2, "B.swift": 1})

    def test_conflicts_skip_the_tree(self):
        text = "0123abcd\0A.swift\0dir/B.swift\0"
        self.assertEqual(conflict_risk.parse_conflicts(text), {"A.swift", "dir/B.swift"})

    def test_risk(self):
        lines = {"B.swift": 4, "logo.pdf": 0}
        self.assertEqual(conflict_risk.risk_of("A.swift", {"A.swift"}, lines), "conflict")
        self.assertEqual(conflict_risk.risk_of("B.swift", set(), lines), "silent")
        self.assertEqual(conflict_risk.risk_of("logo.pdf", set(), lines), "silent")
        self.assertEqual(conflict_risk.risk_of("C.swift", set(), lines), "none")

    def test_rank_orders_by_risk_then_churn_then_commits(self):
        def row(name, risk, lines, commits):
            return {"file": name, "risk": risk, "upstream_lines": lines, "upstream_commits": commits}
        rows = [row("none", "none", 0, 0), row("small", "silent", 5, 9), row("big", "silent", 50, 1),
                row("busy", "silent", 50, 3), row("conflict", "conflict", 1, 1)]
        self.assertEqual([r["file"] for r in conflict_risk.rank(rows)],
                         ["conflict", "busy", "big", "small", "none"])


if __name__ == "__main__":
    unittest.main()
