"""
Validate internal consistency of scope definitions.

Checks:
- valid_scopes and install_order contain the same scopes (scopes.json)
- all dependency rule triggers and targets exist in valid_scopes
- every scope in valid_scopes has a matching .nix file
- every scope .nix file has a '# bins:' comment

# :example
python3 -m tests.hooks.validate_scopes
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCOPES_JSON = REPO_ROOT / ".assets" / "lib" / "scopes.json"
SCOPES_DIR = REPO_ROOT / "nix" / "scopes"

BINS_RE = re.compile(r"^# bins:\s+\S", re.MULTILINE)


def validate() -> int:
    if not SCOPES_JSON.exists():
        print(f"ERROR: {SCOPES_JSON} not found", file=sys.stderr)
        return 1

    data = json.loads(SCOPES_JSON.read_text())
    errors: list[str] = []

    valid = set(data["valid_scopes"])
    order = set(data["install_order"])

    # valid_scopes and install_order must contain the same scopes
    if valid != order:
        only_valid = sorted(valid - order)
        only_order = sorted(order - valid)
        msg = "valid_scopes and install_order differ"
        if only_valid:
            msg += f"\n  in valid_scopes only: {' '.join(only_valid)}"
        if only_order:
            msg += f"\n  in install_order only: {' '.join(only_order)}"
        errors.append(msg)

    # check for duplicates
    if len(data["valid_scopes"]) != len(valid):
        errors.append("valid_scopes contains duplicates")
    if len(data["install_order"]) != len(order):
        errors.append("install_order contains duplicates")

    # dependency rules: all triggers and targets must be valid scopes
    for rule in data["dependency_rules"]:
        trigger = rule["if"]
        if trigger not in valid:
            errors.append(f"dependency rule trigger '{trigger}' not in valid_scopes")
        for target in rule["add"]:
            if target not in valid:
                errors.append(
                    f"dependency rule target '{target}' (from '{trigger}') not in valid_scopes"
                )

    # every scope must have a .nix file with a '# bins:' comment
    for scope in sorted(valid):
        nix_file = SCOPES_DIR / f"{scope}.nix"
        if not nix_file.exists():
            errors.append(f"scope '{scope}' has no matching {nix_file.name}")
            continue
        content = nix_file.read_text()
        if not BINS_RE.search(content):
            errors.append(f"{nix_file.name} missing '# bins:' comment")

    if errors:
        print("Scope definition errors:", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(validate())
