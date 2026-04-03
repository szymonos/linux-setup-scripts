"""
Validate internal consistency of scope definitions in scopes.json.

Checks:
- valid_scopes and install_order contain the same scopes
- all dependency rule triggers and targets exist in valid_scopes

# :example
python3 -m tests.hooks.validate_scopes
"""

import json
import sys
from pathlib import Path

SCOPES_JSON = Path(__file__).resolve().parents[2] / ".assets" / "lib" / "scopes.json"


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
                errors.append(f"dependency rule target '{target}' (from '{trigger}') not in valid_scopes")

    if errors:
        print("Scope definition errors in scopes.json:", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(validate())
