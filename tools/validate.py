#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "README.md",
    "recipe.yaml",
    "server.cfg",
    "config/resources.cfg",
    "config/security.cfg",
    "config/secrets.example.cfg",
    "database/000_sp_base.sql",
    "resources/[sp_core]/sp_bootstrap/fxmanifest.lua",
]

SECRET_PATTERNS = {
    "Cfx.re license key": re.compile(r"cfxk_[A-Za-z0-9_-]{20,}"),
    "MySQL password in URI": re.compile(r"mysql://[^\s:]+:[^\s@{]+@", re.IGNORECASE),
    "Discord bot token": re.compile(r"[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{20,}"),
}

TEXT_SUFFIXES = {".cfg", ".json", ".lua", ".md", ".py", ".sql", ".yaml", ".yml"}


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def main() -> int:
    errors = 0

    for relative in REQUIRED:
        if not (ROOT / relative).exists():
            fail(f"ficheiro obrigatório em falta: {relative}")
            errors += 1

    resources_path = ROOT / "config/resources.cfg"
    if resources_path.exists():
        resources_cfg = resources_path.read_text(encoding="utf-8")
        ordered = ["ensure oxmysql", "ensure es_extended", "ensure [core]", "ensure [sp_core]"]
        positions = [resources_cfg.find(item) for item in ordered]
        if any(position < 0 for position in positions) or positions != sorted(positions):
            fail("ordem de arranque inválida em config/resources.cfg")
            errors += 1

    recipe_path = ROOT / "recipe.yaml"
    if recipe_path.exists():
        recipe = recipe_path.read_text(encoding="utf-8")
        for source in (
            "esx-framework/esx-core",
            "esx-framework/ESX-Legacy-Addons",
            "overextended/oxmysql",
        ):
            if source not in recipe:
                fail(f"dependência ausente da recipe: {source}")
                errors += 1

    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        if path.name == "secrets.example.cfg":
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(content):
                fail(f"possível {label} em {path.relative_to(ROOT)}")
                errors += 1

    if errors:
        print(f"\nValidação terminou com {errors} erro(s).")
        return 1

    print("[OK] Estrutura, ordem de arranque e segredos validados.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
