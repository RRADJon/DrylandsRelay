#!/usr/bin/env python3
from pathlib import Path
import ast

root = Path(__file__).resolve().parents[1]
required = [
    "bootstrap.sh",
    "bootstrap.ps1",
    "tools/install_overlay.py",
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
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit("Missing files: " + ", ".join(missing))

ast.parse((root / "tools/install_overlay.py").read_text(encoding="utf-8"))

installer = (root / "tools/install_overlay.py").read_text(encoding="utf-8")
if 'renderer/rendering_method.web="gl_compatibility"' not in installer:
    raise SystemExit("Web Compatibility renderer override is missing")

presets = (root / "drylands/export_presets.cfg").read_text(encoding="utf-8")
for expected in ['name="Web"', 'platform="Web"', 'variant/thread_support=false', 'export_path="build/web/index.html"']:
    if expected not in presets:
        raise SystemExit(f"Web export preset missing: {expected}")

workflow = (root / ".github/workflows/static.yml").read_text(encoding="utf-8")
for expected in ['--export-release "Web"', 'actions/upload-pages-artifact@v4', 'actions/deploy-pages@v4']:
    if expected not in workflow:
        raise SystemExit(f"Pages workflow missing: {expected}")

for gd in (root / "drylands").glob("*.gd"):
    text = gd.read_text(encoding="utf-8")
    if "Typeface.BLACK" in text:
        raise SystemExit(f"Legacy Android artifact leaked into {gd}")
    if "Filament" in text:
        raise SystemExit(f"Legacy Filament dependency leaked into {gd}")

print("Browser-first overlay self-test passed.")
