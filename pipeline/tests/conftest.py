"""Fixtures.

mini_sde: a tiny hand-written SDE zip, so the builder logic is tested without the 100 MB download.
real_zip / real_db: the real SDE. Set SDE_ZIP (and optionally SDE_DB, to test an already built
artifact). Tests that need them are skipped when SDE_ZIP is not set.
"""

from __future__ import annotations

import json
import os
import sqlite3
import sys
import zipfile
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sde_pipeline.archive import REQUIRED_FILES, SdeArchive  # noqa: E402
from sde_pipeline.builder import build_database  # noqa: E402


def _n(en: str, zh: str) -> dict:
    return {"en": en, "zh": zh, "de": en}


MINI_SDE = {
    "_sde.jsonl": [{"_key": "sde", "buildNumber": 123, "releaseDate": "2026-01-02T03:04:05Z"}],
    "categories.jsonl": [
        {"_key": 6, "name": _n("Ship", "舰船"), "published": True},
        {"_key": 7, "name": _n("Module", "装备"), "published": True},
        {"_key": 16, "name": _n("Skill", "技能"), "published": True},
        {"_key": 99, "name": _n("Unused", "未用"), "published": True},
    ],
    "groups.jsonl": [
        {"_key": 25, "categoryID": 6, "name": _n("Frigate", "护卫舰"), "published": True},
        {"_key": 60, "categoryID": 7, "name": _n("Damage Control", "损伤控制"), "published": True},
        {"_key": 257, "categoryID": 16, "name": _n("Spaceship Command", "舰船操控"), "published": True},
        {"_key": 999, "categoryID": 99, "name": _n("Unused group", "未用"), "published": True},
    ],
    "types.jsonl": [
        {"_key": 587, "groupID": 25, "name": _n("Rifter", "裂谷级"), "published": True, "mass": 1067000.0,
         "volume": 27289.0, "capacity": 140.0, "radius": 31.0, "marketGroupID": 64, "metaGroupID": 1,
         "portionSize": 1, "description": {"en": "long text that must not be stored"}},
        {"_key": 588, "groupID": 25, "name": _n("Unpublished Hull", "未发布"), "published": False, "mass": 1.0},
        {"_key": 2048, "groupID": 60, "name": _n("Damage Control II", "损伤控制 II"), "published": True,
         "mass": 5000.0, "volume": 5.0},
        {"_key": 3327, "groupID": 257, "name": _n("Spaceship Command", "舰船操控"), "published": True, "volume": 0.01},
    ],
    "typeDogma.jsonl": [
        {"_key": 587, "dogmaAttributes": [
            {"attributeID": 14, "value": 3.0}, {"attributeID": 13, "value": 3.0}, {"attributeID": 12, "value": 4.0},
            {"attributeID": 1137, "value": 3.0}, {"attributeID": 48, "value": 130.0}, {"attributeID": 11, "value": 41.0},
            {"attributeID": 38, "value": 135.0}],
         "dogmaEffects": [{"effectID": 7248, "isDefault": False}]},
        {"_key": 588, "dogmaAttributes": [{"attributeID": 14, "value": 8.0}], "dogmaEffects": []},
        {"_key": 2048, "dogmaAttributes": [{"attributeID": 50, "value": 30.0}],
         "dogmaEffects": [{"effectID": 16, "isDefault": False}]},
    ],
    "dogmaAttributes.jsonl": [
        {"_key": 4, "name": "mass", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 11, "name": "powerOutput", "defaultValue": 0.0, "stackable": True, "highIsGood": True,
         "published": True, "displayName": _n("Powergrid Output", "能量栅格输出"), "unitID": 103},
        {"_key": 12, "name": "lowSlots", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 13, "name": "medSlots", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 14, "name": "hiSlots", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 38, "name": "capacity", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 48, "name": "cpuOutput", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 50, "name": "cpu", "defaultValue": 0.0, "stackable": True, "highIsGood": False, "published": True},
        {"_key": 109, "name": "kineticDamageResonance", "defaultValue": 1.0, "stackable": False,
         "highIsGood": False, "published": True, "maxAttributeID": 2770},
        {"_key": 161, "name": "volume", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 162, "name": "radius", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
        {"_key": 1137, "name": "rigSlots", "defaultValue": 0.0, "stackable": True, "highIsGood": True, "published": True},
    ],
    "dogmaEffects.jsonl": [
        {"_key": 16, "name": "online", "effectCategoryID": 4, "isOffensive": False, "isAssistance": False,
         "published": False},
        {"_key": 7248, "name": "shipPBonusROFMF", "effectCategoryID": 0, "isOffensive": False,
         "isAssistance": False, "published": True,
         "modifierInfo": [{"domain": "shipID", "func": "LocationRequiredSkillModifier", "modifiedAttributeID": 51,
                           "modifyingAttributeID": 460, "operation": 6, "skillTypeID": 3302}]},
        {"_key": 9999, "name": "stopper", "effectCategoryID": 0, "isOffensive": False, "isAssistance": False,
         "published": False, "modifierInfo": [{"domain": "target", "func": "EffectStopper", "effectID": 16}]},
    ],
    "dogmaUnits.jsonl": [{"_key": 103, "name": "Powergrid", "displayName": _n("MW", "MW")}],
    "marketGroups.jsonl": [
        {"_key": 4, "name": _n("Ships", "舰船"), "hasTypes": False},
        {"_key": 64, "parentGroupID": 4, "name": _n("Standard Frigates", "标准护卫舰"), "hasTypes": True},
    ],
    "metaGroups.jsonl": [{"_key": 1, "name": _n("Tech I", "一级科技")}],
    "mapRegions.jsonl": [{"_key": 10000002, "name": _n("The Forge", "伏尔戈")}],
    "mapConstellations.jsonl": [{"_key": 20000020, "regionID": 10000002, "name": _n("Kimotoro", "木本道")}],
    "mapSolarSystems.jsonl": [
        {"_key": 30000142, "constellationID": 20000020, "regionID": 10000002, "name": _n("Jita", "吉他"),
         "securityStatus": 0.945913},
    ],
    "mapPlanets.jsonl": [
        {"_key": 40009086, "celestialIndex": 4, "solarSystemID": 30000142},
        {"_key": 40009100, "celestialIndex": 8, "solarSystemID": 30000142,
         "uniqueName": _n("Jita VIII (Example)", "吉他 VIII (例子)")},
    ],
    "mapMoons.jsonl": [
        {"_key": 40009087, "orbitID": 40009086, "orbitIndex": 4, "solarSystemID": 30000142},
        {"_key": 40009088, "orbitID": 40009086, "orbitIndex": 5, "solarSystemID": 30000142},
    ],
    "npcStations.jsonl": [
        {"_key": 60003760, "celestialIndex": 4, "operationID": 14, "orbitID": 40009087, "orbitIndex": 4,
         "ownerID": 1000035, "solarSystemID": 30000142, "typeID": 52678, "useOperationName": True},
        {"_key": 60000001, "celestialIndex": 8, "operationID": 14, "orbitID": 40009100, "ownerID": 1000035,
         "solarSystemID": 30000142, "typeID": 1, "useOperationName": False},
    ],
    "npcCorporations.jsonl": [{"_key": 1000035, "name": _n("Caldari Navy", "加达里海军")}],
    "stationOperations.jsonl": [{"_key": 14, "operationName": _n("Assembly Plant", "组装车间")}],
}


def write_sde_zip(path: Path, files: dict[str, list[dict]], prefix: str = "") -> Path:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for name, records in files.items():
            z.writestr(prefix + name, "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in records))
    return path


@pytest.fixture
def mini_zip(tmp_path: Path) -> Path:
    assert set(MINI_SDE) == set(REQUIRED_FILES.values())
    return write_sde_zip(tmp_path / "mini.zip", MINI_SDE)


@pytest.fixture
def mini_db(tmp_path: Path, mini_zip: Path) -> sqlite3.Connection:
    out = tmp_path / "mini.sqlite"
    with SdeArchive(mini_zip) as archive:
        build_database(archive, out, log=lambda _msg: None)
    con = sqlite3.connect(out)
    yield con
    con.close()


@pytest.fixture(scope="session")
def real_zip() -> Path:
    value = os.environ.get("SDE_ZIP")
    if not value:
        pytest.skip("SDE_ZIP not set; real-data tests skipped")
    return Path(value)


@pytest.fixture(scope="session")
def real_db(real_zip: Path, tmp_path_factory) -> sqlite3.Connection:
    built = os.environ.get("SDE_DB")
    if built:
        path = Path(built)
    else:
        path = tmp_path_factory.mktemp("sde") / "real.sqlite"
        with SdeArchive(real_zip) as archive:
            build_database(archive, path, log=lambda _msg: None)
    con = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    yield con
    con.close()


@pytest.fixture(scope="session")
def raw(real_zip: Path):
    """Raw SDE records the tests compare against, loaded once."""
    with SdeArchive(real_zip) as archive:
        groups = {r["_key"]: r for r in archive.iter_records("groups")}
        types = {r["_key"]: r for r in archive.iter_records("types")}
        dogma = {r["_key"]: r for r in archive.iter_records("type_dogma")}
        stations = {r["_key"]: r for r in archive.iter_records("npc_stations")}
        modifier_count = sum(len(e.get("modifierInfo") or []) for e in archive.iter_records("dogma_effects"))
        attributes = {r["name"]: r["_key"] for r in archive.iter_records("dogma_attributes")}
    return {
        "groups": groups,
        "types": types,
        "dogma": dogma,
        "stations": stations,
        "modifier_count": modifier_count,
        "attribute_ids": attributes,
    }
