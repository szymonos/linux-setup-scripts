#!/usr/bin/env python3
"""
Review brief management for the /second-opinion skill.

Three subcommands:
  check    - verify REVIEW-BRIEF.md repo tag matches current repo
  discover - scan repo for context to generate/update the brief
  parse    - parse Copilot's raw output into structured JSON findings

Usage:
    python3 scripts/review_brief.py check
    python3 scripts/review_brief.py discover
    python3 scripts/review_brief.py parse <raw-output-file>
    echo "<copilot output>" | python3 scripts/review_brief.py parse -
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

BRIEF_FILENAME = "REVIEW-BRIEF.md"
CONTEXT_FILES = [
    ("claude_md", "CLAUDE.md"),
    ("agents_md", "AGENTS.md"),
    ("architecture_md", "ARCHITECTURE.md"),
    ("readme", "README.md"),
    ("contributing", "CONTRIBUTING.md"),
]
SKIP_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    "target",
    ".venv",
    "venv",
    "vendor",
    "__pycache__",
    "site",
}
MAX_CONTEXT_LINES = 80


def _find_brief(start: Path | None = None) -> Path | None:
    """Walk up from start to find REVIEW-BRIEF.md."""
    if start is None:
        start = Path(__file__).resolve().parent.parent
    brief = start / BRIEF_FILENAME
    if brief.exists():
        return brief
    for parent in start.parents:
        candidate = parent / ".claude" / "skills" / "second-opinion" / BRIEF_FILENAME
        if candidate.exists():
            return candidate
    return None


def _read_frontmatter(path: Path) -> dict[str, str]:
    """Extract YAML frontmatter key-value pairs from a markdown file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fm = text[4:end]
    result: dict[str, str] = {}
    for line in fm.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def _get_current_repo() -> str | None:
    """Get current repo's nameWithOwner via gh CLI."""
    try:
        result = subprocess.run(
            ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None


def _read_head(path: Path, max_lines: int = MAX_CONTEXT_LINES) -> str | None:
    """Read up to max_lines from a file, or None if it doesn't exist."""
    if not path.exists():
        return None
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        return "\n".join(lines[:max_lines])
    except OSError:
        return None


def _detect_stacks(root: Path) -> list[str]:
    """Quick stack detection (subset of bootstrap-hooks/detect_stack.py)."""
    stacks: list[str] = []
    markers = {
        "python": ["pyproject.toml", "requirements.txt", "setup.py"],
        "javascript": ["package.json"],
        "go": ["go.mod"],
        "rust": ["Cargo.toml"],
        "java": ["pom.xml", "build.gradle"],
        "ruby": ["Gemfile"],
        "docker": ["Dockerfile", "docker-compose.yml"],
        "terraform": [],
        "mkdocs": ["mkdocs.yml", "mkdocs.yaml"],
    }
    for stack, files in markers.items():
        for f in files:
            if (root / f).exists():
                stacks.append(stack)
                break

    if any(root.rglob("*.tf")):
        stacks.append("terraform")
    if any(root.rglob("*.sh")):
        stacks.append("shell")
    if (root / ".obsidian").exists() or any(
        (root / "docs").rglob(".obsidian") if (root / "docs").exists() else []
    ):
        stacks.append("obsidian")
    if (root / "docs").exists() and any((root / "docs").rglob("*.md")):
        stacks.append("markdown-docs")
    if (root / ".github" / "workflows").exists():
        stacks.append("github-actions")
    if (root / ".gitlab-ci.yml").exists():
        stacks.append("gitlab-ci")

    return sorted(set(stacks))


# -- Subcommands --------------------------------------------------------------


def cmd_check(args: argparse.Namespace) -> int:
    """Check if REVIEW-BRIEF.md repo tag matches current repo."""
    root = Path(args.repo_root).resolve()
    brief_path = _find_brief(root / ".claude" / "skills" / "second-opinion")

    result: dict = {
        "brief_exists": brief_path is not None and brief_path.exists(),
        "brief_repo": None,
        "current_repo": None,
        "match": False,
        "needs_update": False,
    }

    if not result["brief_exists"]:
        result["needs_update"] = True
        result["reason"] = "REVIEW-BRIEF.md not found"
        json.dump(result, sys.stdout, indent=2)
        print()
        return 1

    fm = _read_frontmatter(brief_path)
    result["brief_repo"] = fm.get("repo")
    result["current_repo"] = _get_current_repo()

    if result["brief_repo"] is None:
        result["needs_update"] = True
        result["reason"] = "No repo: tag in REVIEW-BRIEF.md frontmatter"
    elif result["current_repo"] is None:
        result["needs_update"] = False
        result["reason"] = "Could not determine current repo (gh CLI unavailable?)"
    elif result["brief_repo"] == result["current_repo"]:
        result["match"] = True
    else:
        result["needs_update"] = True
        brief = result["brief_repo"]
        current = result["current_repo"]
        result["reason"] = (
            f"Repo mismatch: brief targets '{brief}', current is '{current}'"
        )

    json.dump(result, sys.stdout, indent=2)
    print()
    return 0 if result["match"] else 1


def cmd_discover(args: argparse.Namespace) -> int:
    """Scan repo for context to generate/update the brief."""
    root = Path(args.repo_root).resolve()

    context_files: dict[str, str | None] = {}
    for key, filename in CONTEXT_FILES:
        context_files[key] = _read_head(root / filename)

    stacks = _detect_stacks(root)
    current_repo = _get_current_repo()

    brief_path = _find_brief(root / ".claude" / "skills" / "second-opinion")
    existing_brief = None
    if brief_path and brief_path.exists():
        existing_brief = brief_path.read_text(encoding="utf-8", errors="replace")

    result = {
        "repo": current_repo,
        "root": str(root),
        "stacks": stacks,
        "context_files": {k: v for k, v in context_files.items() if v is not None},
        "existing_brief": existing_brief,
    }

    json.dump(result, sys.stdout, indent=2)
    print()
    return 0


def cmd_parse(args: argparse.Namespace) -> int:
    """Parse Copilot's raw markdown output into structured JSON findings."""
    if args.input == "-":
        raw = sys.stdin.read()
    else:
        raw = Path(args.input).read_text(encoding="utf-8", errors="replace")

    if "No findings." in raw and "### F-" not in raw:
        json.dump({"findings": [], "count": 0}, sys.stdout, indent=2)
        print()
        return 0

    finding_re = re.compile(
        r"###\s+(F-\d+)\s*-\s*(bug|warning|nit)\s*-\s*(.+?)(?::(\d+))?\s*\n"
        r"(.*?)(?=\n###\s+F-|\n##\s|\Z)",
        re.DOTALL,
    )

    findings: list[dict] = []
    for m in finding_re.finditer(raw):
        body = m.group(5).strip()

        suggestion = None
        suggestion_match = re.search(
            r"\*\*Suggestion:\*\*\s*(.+?)(?=\n\n|\n###|\Z)", body, re.DOTALL
        )
        if suggestion_match:
            suggestion = suggestion_match.group(1).strip()
            description = body[: suggestion_match.start()].strip()
        else:
            description = body

        finding: dict = {
            "id": m.group(1),
            "severity": m.group(2),
            "file": m.group(3).strip(),
            "description": description,
        }
        if m.group(4):
            finding["line"] = int(m.group(4))
        if suggestion:
            finding["suggestion"] = suggestion

        findings.append(finding)

    json.dump({"findings": findings, "count": len(findings)}, sys.stdout, indent=2)
    print()
    return 0


def main() -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Review brief management")
    parser.add_argument(
        "--repo-root", default=".", help="Repository root (default: cwd)"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="Verify REVIEW-BRIEF.md repo tag matches current repo")
    sub.add_parser(
        "discover", help="Scan repo for context to generate/update the brief"
    )

    parse_p = sub.add_parser("parse", help="Parse Copilot output into JSON findings")
    parse_p.add_argument("input", help="Path to raw output file, or '-' for stdin")

    args = parser.parse_args()

    commands = {
        "check": cmd_check,
        "discover": cmd_discover,
        "parse": cmd_parse,
    }
    return commands[args.command](args)


if __name__ == "__main__":
    raise SystemExit(main())
