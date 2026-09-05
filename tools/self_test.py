#!/usr/bin/env python3
from pathlib import Path
import ast
import sys

root = Path(__file__).resolve().parents[1]

required = [
    "bootstrap.sh",
    "bootstrap.ps1",
    "tools/install_overlay.py",
    "tools/self_test.py",
    "drylands/game.tscn",
    "drylands/game.gd",
    "drylands/drylands_state.gd",
    "drylands/hud.gd",
    "drylands/mobile_controls.gd",
    "drylands/export_presets.cfg",
    ".github/workflows/static.yml",
    "THIRD_PARTY_NOTICES.md",
    "BROWSER_TEST_CHECKLIST.md",
]

print("Drylands browser overlay preflight")
print(f"Repository root: {root}")

missing = [p for p in required if not (root / p).is_file()]
if missing:
    print("ERROR: required files are missing:", file=sys.stderr)
    for item in missing:
        print(f"  - {item}", file=sys.stderr)
    if (root / "drylands/export_presents.cfg").exists():
        print("NOTE: found drylands/export_presents.cfg; the correct filename is export_presets.cfg", file=sys.stderr)
    raise SystemExit(1)

# Only validate syntax/essential browser preset fields here. Do not make the
# CI preflight depend on exact implementation strings in the installer/workflow.
ast.parse((root / "tools/install_overlay.py").read_text(encoding="utf-8"))

preset = (root / "drylands/export_presets.cfg").read_text(encoding="utf-8")
required_preset_lines = [
    'name="Web"',
    'platform="Web"',
    'export_path="build/web/index.html"',
    'variant/thread_support=false',
]
for line in required_preset_lines:
    if line not in preset:
        raise SystemExit(f"ERROR: drylands/export_presets.cfg is missing: {line}")

if 'platform="Android"' in preset:
    raise SystemExit("ERROR: browser preview export_presets.cfg should not contain an Android preset")

print("Preflight passed. Files, Python syntax, and Web preset are valid.")
