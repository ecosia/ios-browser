"""Comment- and string-aware reading of source files, shared by the upgrade tools.

A plain grep cannot tell a live declaration from one inside an `/* Ecosia: */` block, or a marker
in a comment from the same text in a string literal. This module splits a file into code, comment
and string characters, so the tools can look at one of them only.

Supported comment syntaxes, chosen by file name (see `syntax_for`):
  swift   `//`, nested `/* */`; strings "...", \"\"\"...\"\"\", raw #"..."#, interpolation \\( ... )
  c       `//`, `/* */` (not nested); strings "..." and '...'   (.m, .h, .c, .js, .strings, ...)
  slash   `//` only, no strings                                  (.xcconfig)
  hash    `#` at the start of a line or after whitespace, outside '...' and "..."  (.sh, .yml, .py, ...)
  xml     `<!-- -->`                                             (.plist, .xml, .html, .md, ...)
  plain   no comment syntax known: the whole file counts as comment (markers are a plain match)

Not a parser: Swift regex literals and Python triple-quoted strings are not recognised.
"""

import os
import re

CODE, COMMENT, STRING = "c", "m", "s"

MARKER = "Ecosia:"

_SWIFT = {".swift"}
_C = {".m", ".mm", ".h", ".c", ".cpp", ".js", ".ts", ".strings", ".stringsdict", ".kt", ".java",
      ".gradle", ".css", ".scss", ".swiftinterface"}
_SLASH = {".xcconfig"}
_HASH = {".sh", ".bash", ".zsh", ".yml", ".yaml", ".py", ".rb", ".toml", ".cfg", ".ini", ".txt",
         ".gitignore", ".gitattributes", ".gitmodules", ".podspec", ".properties", ".env"}
_HASH_NAMES = {"Gemfile", "Podfile", "Fastfile", "Appfile", "Matchfile", "Dangerfile", "Makefile",
               "Brewfile", "Pluginfile", "CODEOWNERS", ".gitignore", ".gitattributes",
               ".gitmodules", ".swiftlint.yml", ".swift-version", ".python-version"}
_XML = {".plist", ".xml", ".html", ".htm", ".xib", ".storyboard", ".md", ".entitlements",
        ".xcscheme", ".xcworkspacedata", ".svg"}


def syntax_for(path, text=""):
    """The comment syntax for `path`; `text` lets a shebang decide for files without an extension."""
    name = os.path.basename(path)
    ext = os.path.splitext(name)[1].lower()
    if ext in _SWIFT:
        return "swift"
    if ext in _C:
        return "c"
    if ext in _SLASH:
        return "slash"
    if ext in _XML:
        return "xml"
    if ext in _HASH or name in _HASH_NAMES or text.startswith("#!"):
        return "hash"
    return "plain"


def classify(text, syntax="swift"):
    """A string as long as `text`: each character is CODE, COMMENT or STRING."""
    if syntax == "swift":
        return _classify_c_like(text, nested=True, swift_strings=True)
    if syntax == "c":
        return _classify_c_like(text, nested=False, swift_strings=False)
    if syntax == "slash":
        return _classify_slash(text)
    if syntax == "hash":
        return _classify_hash(text)
    if syntax == "xml":
        return _classify_xml(text)
    return COMMENT * len(text)


def _classify_c_like(text, nested, swift_strings):
    n = len(text)
    kinds = bytearray(CODE * n, "ascii")
    if swift_strings:
        opener = re.compile(r'//|/\*|(#*)("""|")|[()]')
    else:
        opener = re.compile(r'//|/\*|(["\'])|[()]')
    # Stack of contexts. ("code", depth): depth is None at top level, otherwise the number of open
    # parentheses inside a string interpolation. ("string", quote, hashes, multiline).
    stack = [("code", None)]
    i = 0

    def mark(start, end, kind):
        kinds[start:end] = kind.encode() * (end - start)

    while i < n:
        top = stack[-1]
        if top[0] == "code":
            m = opener.search(text, i)
            if not m:
                break
            tok = m.group(0)
            start = m.start()
            if tok == "//":
                end = text.find("\n", start)
                end = n if end < 0 else end
                mark(start, end, COMMENT)
                i = end
            elif tok == "/*":
                depth, j = 1, start + 2
                while j < n and depth:
                    if nested and text.startswith("/*", j):
                        depth += 1
                        j += 2
                    elif text.startswith("*/", j):
                        depth -= 1
                        j += 2
                    else:
                        j += 1
                mark(start, j, COMMENT)
                i = j
            elif tok in "()":
                depth = top[1]
                if depth is not None:
                    depth += 1 if tok == "(" else -1
                    if depth == 0:
                        stack.pop()
                        mark(start, start + 1, STRING)
                    else:
                        stack[-1] = ("code", depth)
                i = start + 1
            else:
                if swift_strings:
                    hashes = len(m.group(1))
                    multiline = m.group(2) == '"""'
                    quote = '"'
                else:
                    hashes, multiline, quote = 0, False, m.group(1)
                mark(start, m.end(), STRING)
                stack.append(("string", quote, hashes, multiline))
                i = m.end()
        else:
            _, quote, hashes, multiline = top
            closer = (quote * 3 if multiline else quote) + "#" * hashes
            escape = "\\" + "#" * hashes
            if text.startswith(closer, i):
                mark(i, i + len(closer), STRING)
                i += len(closer)
                stack.pop()
            elif text.startswith(escape, i):
                k = i + len(escape)
                if swift_strings and k < n and text[k] == "(":
                    mark(i, k + 1, STRING)
                    stack.append(("code", 1))
                    i = k + 1
                else:
                    mark(i, min(k + 1, n), STRING)
                    i = k + 1
            elif text[i] == "\n" and not multiline:
                stack.pop()  # unterminated single-line string: stop at the end of the line
                i += 1
            else:
                mark(i, i + 1, STRING)
                i += 1
    return kinds.decode("ascii")


def _classify_slash(text):
    kinds = bytearray(CODE * len(text), "ascii")
    for m in re.finditer(r"//[^\n]*", text):
        kinds[m.start():m.end()] = COMMENT.encode() * (m.end() - m.start())
    return kinds.decode("ascii")


def _classify_hash(text):
    out = []
    for line in text.splitlines(keepends=True):
        kinds = [CODE] * len(line)
        quote = None
        for i, ch in enumerate(line):
            if quote:
                kinds[i] = STRING
                if ch == quote and (quote == "'" or line[i - 1] != "\\"):
                    quote = None
            elif ch in "'\"":
                quote = ch
                kinds[i] = STRING
            elif ch == "#" and (i == 0 or line[i - 1] in " \t"):
                end = len(line.rstrip("\n"))
                kinds[i:end] = [COMMENT] * (end - i)
                break
        out.append("".join(kinds))
    return "".join(out)


def _classify_xml(text):
    kinds = bytearray(CODE * len(text), "ascii")
    for m in re.finditer(r"<!--.*?(?:-->|\Z)", text, re.S):
        kinds[m.start():m.end()] = COMMENT.encode() * (m.end() - m.start())
    return kinds.decode("ascii")


def keep(text, kinds, kind):
    """`text` with every character not of `kind` replaced by a space (newlines are kept)."""
    return "".join(ch if k == kind or ch == "\n" else " " for ch, k in zip(text, kinds))


def code_only(text, syntax="swift"):
    """`text` with comments and string literals blanked out, line numbers unchanged."""
    return keep(text, classify(text, syntax), CODE)


def comments_only(text, syntax="swift"):
    """`text` with everything but comments blanked out, line numbers unchanged."""
    return keep(text, classify(text, syntax), COMMENT)


def marker_lines(text, path, marker=MARKER):
    """1-based line numbers where `marker` appears inside a comment."""
    if marker not in text:
        return []
    kinds = classify(text, syntax_for(path, text))
    lines = []
    for m in re.finditer(re.escape(marker), text):
        if kinds[m.start()] == COMMENT:
            lines.append(text.count("\n", 0, m.start()) + 1)
    return lines
