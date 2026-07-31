#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VALIDATOR_PATH = Path(__file__).resolve()

REQUIRED = [
    "README.md",
    "recipe.yaml",
    "server.cfg",
    "config/resources.cfg",
    "config/security.cfg",
    "config/voice.cfg",
    "config/secrets.example.cfg",
    "database/000_sp_base.sql",
    "database/005_sp_essential_items.sql",
    "database/010_sp_phone.sql",
    "database/015_sp_starterpack.sql",
    "database/020_sp_jobs_pt.sql",
    "resources/[sp_core]/sp_bootstrap/fxmanifest.lua",
    "resources/[sp_core]/sp_radio/fxmanifest.lua",
    "resources/[sp_core]/sp_radio/config.lua",
    "resources/[sp_core]/sp_radio/client/main.lua",
    "resources/[sp_core]/sp_radio/server/main.lua",
    "resources/[sp_core]/sp_starterpack/fxmanifest.lua",
    "resources/[sp_core]/sp_starterpack/config.lua",
    "resources/[sp_core]/sp_starterpack/server/main.lua",
    "resources/[sp_ui]/sp_phone/fxmanifest.lua",
    "resources/[sp_ui]/sp_phone/config.lua",
    "resources/[sp_ui]/sp_phone/client/main.lua",
    "resources/[sp_ui]/sp_phone/server/main.lua",
    "resources/[sp_ui]/sp_phone/html/index.html",
    "resources/[sp_ui]/sp_phone/html/style.css",
    "resources/[sp_ui]/sp_phone/html/app.js",
]

RECIPE_SOURCES = (
    "esx-framework/esx_core",
    "esx-framework/ESX-Legacy-Addons",
    "AvarianKnight/pma-voice",
    "overextended/oxmysql",
)

RECIPE_EXTERNAL_SQL = (
    "esx_addonaccount/esx_addonaccount.sql",
    "esx_addoninventory/esx_addoninventory.sql",
    "esx_datastore/esx_datastore.sql",
    "esx_society/esx_society.sql",
    "esx_billing/esx_billing.sql",
    "esx_license/esx_license.sql",
    "esx_banking/banking.sql",
    "esx_jobs/esx_jobs.sql",
    "esx_policejob/esx_policejob.sql",
    "esx_ambulancejob/esx_ambulancejob.sql",
    "esx_mechanicjob/esx_mechanicjob.sql",
    "esx_taxijob/esx_taxijob.sql",
    "esx_vehicleshop/esx_vehicleshop.sql",
    "esx_garage/esx_garage.sql",
)

START_ORDER = (
    "ensure oxmysql",
    "ensure pma-voice",
    "ensure es_extended",
    "ensure [core]",
    "ensure [esx_addons]",
    "ensure [sp_core]",
    "ensure [sp_ui]",
)

SECRET_PATTERNS = {
    "Cfx.re license key": re.compile(r"cfxk_[A-Za-z0-9_-]{20,}"),
    "MySQL password in URI": re.compile(r"mysql://[^\s:]+:[^\s@{]+@", re.IGNORECASE),
    "Discord bot token": re.compile(r"[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{6,}\.[A-Za-z0-9_-]{20,}"),
}

TEXT_SUFFIXES = {
    ".cfg",
    ".css",
    ".html",
    ".js",
    ".json",
    ".lua",
    ".md",
    ".py",
    ".sql",
    ".yaml",
    ".yml",
}


def fail(message: str) -> None:
    print(f"[FAIL] {message}")


def validate_required_files() -> int:
    errors = 0
    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            fail(f"ficheiro obrigatório em falta: {relative}")
            errors += 1
    return errors


def validate_resource_order() -> int:
    path = ROOT / "config/resources.cfg"
    if not path.exists():
        return 0

    content = path.read_text(encoding="utf-8")
    positions = [content.find(item) for item in START_ORDER]
    if any(position < 0 for position in positions) or positions != sorted(positions):
        fail("ordem de arranque inválida em config/resources.cfg")
        return 1
    return 0


def validate_recipe() -> int:
    path = ROOT / "recipe.yaml"
    if not path.exists():
        return 0

    content = path.read_text(encoding="utf-8")
    errors = 0

    for source in RECIPE_SOURCES:
        if source not in content:
            fail(f"dependência ausente da recipe: {source}")
            errors += 1

    for sql_path in RECIPE_EXTERNAL_SQL:
        if sql_path not in content:
            fail(f"SQL oficial não importado pela recipe: {sql_path}")
            errors += 1

    for migration in sorted((ROOT / "database").glob("*.sql")):
        expected = f"./tmp/sp-base/database/{migration.name}"
        if expected not in content:
            fail(f"migração própria não importada pela recipe: {migration.name}")
            errors += 1

    return errors


def validate_manifests() -> int:
    errors = 0
    for manifest in ROOT.glob("resources/**/fxmanifest.lua"):
        if not manifest.parent.name.startswith("sp_"):
            continue

        content = manifest.read_text(encoding="utf-8")
        if "fx_version" not in content or "game" not in content:
            fail(f"manifest incompleto: {manifest.relative_to(ROOT)}")
            errors += 1

        for relative in re.findall(r"['\"]([^'\"]+\.(?:lua|js|html|css))['\"]", content):
            if relative.startswith("@") or "*" in relative:
                continue
            target = manifest.parent / relative
            if not target.is_file():
                fail(
                    "ficheiro referenciado pelo manifest não existe: "
                    f"{target.relative_to(ROOT)}"
                )
                errors += 1
    return errors


def validate_secrets() -> int:
    errors = 0
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        if path.resolve() == VALIDATOR_PATH or path.name == "secrets.example.cfg":
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(content):
                fail(f"possível {label} em {path.relative_to(ROOT)}")
                errors += 1
    return errors


def main() -> int:
    errors = 0
    errors += validate_required_files()
    errors += validate_resource_order()
    errors += validate_recipe()
    errors += validate_manifests()
    errors += validate_secrets()

    if errors:
        print(f"\nValidação terminou com {errors} erro(s).")
        return 1

    print("[OK] Estrutura, recipe, manifests, ordem de arranque e segredos validados.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
