#!/usr/bin/env python3
"""
Fail CI when any public symbol in Sources/SwiftBaseball lacks a DocC `///`
comment.

Scope: top-level types (struct / class / enum / protocol / actor / typealias),
top-level public functions and properties, and — inside type bodies — public
methods, initializers, subscripts, and computed properties. Stored properties
inside an already-documented type are exempt; their meaning derives from the
parent type's docs (this matches Apple's own DocC corpus).

A symbol is "public" when its declaration line, after stripping leading
whitespace, modifier tokens (`open`, `final`, `static`, `class`, `override`,
`nonisolated`), and single-line attributes (`@available(...)` etc.), starts
with `public `. We require that one of the lines immediately above (skipping
blank lines and attribute-only lines) starts with `///`.

Exempt:

- `public extension Foo { ... }` — DocC does not render extension declarations
  as standalone symbols.
- `public init(from decoder:)` — Codable boilerplate.
- Stored `public let` / `public var` *inside* a type body. (Top-level globals
  and computed properties — those followed by `{` — are still checked.)

Exits 0 with a clean report on success, or 1 with a per-symbol list when any
violation is found.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "Sources" / "SwiftBaseball"

# Strips leading whitespace plus any sequence of modifier tokens that may
# precede `public`. Each modifier ends in required whitespace, then we loop;
# the next iteration's leading `\s*` consumes any whitespace before the next
# token.
LEADING_MODS = re.compile(
    r"^\s*(?:(?:open|final|static|class|override|nonisolated|@\w+(?:\([^)]*\))?)\s+)*"
)
# Type-introducing keywords (always require docs).
TYPE_KEYWORDS = ("class", "struct", "enum", "protocol", "actor", "typealias")
TYPE_RE = re.compile(r"^public\s+(?:" + "|".join(TYPE_KEYWORDS) + r")\b")
# Function / init / subscript (always require docs).
FUNC_RE = re.compile(r"^public\s+(?:func|init|subscript)\b")
# Property declaration. We need to distinguish stored from computed: stored
# end the line with `: Type` (no `{`); computed introduce `{` on the same
# line or a line below. The simplest heuristic: if the line ends with `{`
# (or `{ get` / `{ get set`), it's computed and we require docs. Otherwise
# we treat it as stored and exempt it inside a type body (depth > 0).
PROPERTY_RE = re.compile(r"^public\s+(?:let|var)\b")
# Lines we should ignore when scanning backwards for a doc comment.
ATTRIBUTE_LINE_RE = re.compile(r"^\s*@\w+(?:\([^)]*\))?\s*$")
# Exemptions.
EXTENSION_RE = re.compile(r"^public\s+extension\b")
CODABLE_INIT_RE = re.compile(r"^public\s+init\s*\(\s*from\s+\w+\s*:")


def is_documented_at(lines: list[str], idx: int) -> bool:
    """Walk backwards from `idx-1` skipping blank and attribute-only lines.
    Return True if the first preceding meaningful line starts with `///`.
    """
    j = idx - 1
    while j >= 0:
        line = lines[j].rstrip("\n")
        if not line.strip():
            j -= 1
            continue
        if ATTRIBUTE_LINE_RE.match(line):
            j -= 1
            continue
        return line.lstrip().startswith("///")
    return False


def looks_computed(line: str) -> bool:
    """A property is computed if its declaration line ends with `{` (possibly
    followed by `get` / `get set`). Stored properties end at `: Type` or
    `= value`."""
    stripped = line.rstrip()
    # Strip trailing comment
    if "//" in stripped:
        stripped = stripped.split("//", 1)[0].rstrip()
    return stripped.endswith("{") or stripped.endswith("{ get") or stripped.endswith("{ get set")


def strip_string_and_comment(line: str) -> str:
    """Remove string literals and line comments from a Swift line so we can
    count braces without being fooled by `"{"` or `// {`."""
    out: list[str] = []
    i = 0
    in_string = False
    while i < len(line):
        ch = line[i]
        if not in_string and line[i : i + 2] == "//":
            break
        if ch == '"':
            in_string = not in_string
            i += 1
            continue
        if not in_string:
            out.append(ch)
        i += 1
    return "".join(out)


def check_file(path: Path) -> list[tuple[int, str]]:
    """Return a list of (line_no, declaration) pairs that lack doc comments."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    violations: list[tuple[int, str]] = []
    depth = 0
    for i, raw in enumerate(lines):
        # Update brace depth before checking — a declaration on this line is
        # at the *current* depth. We update depth from the line content but
        # only after considering whether the symbol is at the pre-update depth.
        symbol_depth = depth
        stripped = LEADING_MODS.sub("", raw)

        is_violation = False
        if EXTENSION_RE.match(stripped) or CODABLE_INIT_RE.match(stripped):
            pass  # exempt
        elif TYPE_RE.match(stripped) or FUNC_RE.match(stripped):
            if not is_documented_at(lines, i):
                is_violation = True
        elif PROPERTY_RE.match(stripped):
            # Stored properties inside a type body are exempt; computed
            # properties (and top-level globals) must be doc'd.
            if symbol_depth == 0 or looks_computed(raw):
                if not is_documented_at(lines, i):
                    is_violation = True

        if is_violation:
            violations.append((i + 1, raw.strip()))

        # Track brace depth (string-literal aware).
        scrubbed = strip_string_and_comment(raw)
        depth += scrubbed.count("{") - scrubbed.count("}")

    return violations


def main() -> int:
    if not SOURCES.is_dir():
        print(f"error: source directory not found at {SOURCES}", file=sys.stderr)
        return 2

    total_violations: list[tuple[Path, int, str]] = []
    files_scanned = 0
    for swift_file in sorted(SOURCES.rglob("*.swift")):
        if ".docc" in swift_file.parts:
            continue
        files_scanned += 1
        for line_no, decl in check_file(swift_file):
            total_violations.append((swift_file, line_no, decl))

    if total_violations:
        print(
            f"DocC coverage check FAILED — {len(total_violations)} undocumented "
            f"public symbol(s) in {files_scanned} file(s):\n"
        )
        for path, line_no, decl in total_violations:
            rel = path.relative_to(ROOT)
            print(f"  {rel}:{line_no}: {decl}")
        print(
            "\nEvery public type, function, computed property, initializer, "
            "and subscript in SwiftBaseball must have a `///` doc comment "
            "immediately above it. Stored properties inside an already-"
            "documented type are exempt. Add a doc comment, then re-run."
        )
        return 1

    print(
        f"DocC coverage check passed — every public top-level / function / "
        f"computed-property / initializer in {files_scanned} file(s) has a "
        f"`///` doc comment."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
