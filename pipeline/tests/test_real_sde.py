"""Checks against the real SDE: the built database must say exactly what the SDE says.

Run with:  SDE_ZIP=path/to/eve-online-static-data-<build>-jsonl.zip [SDE_DB=built.sqlite] pytest
"""

from __future__ import annotations

import sqlite3

import pytest

# The attributes the fitting screen reads first. IDs are resolved from the SDE by name, so a test
# failure here means the data changed, not that this file guessed an ID.
FITTING_ATTRIBUTES = ["hiSlots", "medSlots", "lowSlots", "rigSlots", "cpuOutput", "powerOutput",
                      "upgradeCapacity", "turretSlotsLeft", "launcherSlotsLeft"]

SPOT_CHECK_SHIPS = ["Merlin", "Punisher", "Tristan", "Drake", "Raven", "Machariel", "Tengu", "Venture"]


def _raw_attrs(raw, type_id: int) -> dict[int, float]:
    return {a["attributeID"]: a["value"] for a in raw["dogma"][type_id].get("dogmaAttributes", [])}


def _db_attrs(db: sqlite3.Connection, type_id: int) -> dict[int, float]:
    return dict(db.execute("SELECT attribute_id, value FROM dgm_type_attributes WHERE type_id = ?", (type_id,)))


def _assert_same_fitting(db, raw, type_id: int):
    raw_attrs = _raw_attrs(raw, type_id)
    db_attrs = _db_attrs(db, type_id)
    for name in FITTING_ATTRIBUTES:
        attribute_id = raw["attribute_ids"][name]
        assert db_attrs.get(attribute_id) == raw_attrs.get(attribute_id), (type_id, name)


def test_rifter_587(real_db, raw):
    row = real_db.execute(
        "SELECT t.name_en, t.name_zh, c.name_en FROM inv_types t JOIN inv_categories c USING (category_id) "
        "WHERE t.type_id = 587").fetchone()
    assert row == ("Rifter", raw["types"][587]["name"]["zh"], "Ship")
    _assert_same_fitting(real_db, raw, 587)
    ids = raw["attribute_ids"]
    db_attrs = _db_attrs(real_db, 587)
    # The values themselves, so a broken lookup cannot make both sides None and still pass.
    assert db_attrs[ids["hiSlots"]] >= 1 and db_attrs[ids["lowSlots"]] >= 1
    assert db_attrs[ids["cpuOutput"]] > 0 and db_attrs[ids["powerOutput"]] > 0
    assert db_attrs[4] == raw["types"][587]["mass"]


@pytest.mark.parametrize("name", SPOT_CHECK_SHIPS)
def test_spot_check_ships(real_db, raw, name):
    matches = [k for k, t in raw["types"].items() if t.get("published") and t["name"].get("en") == name]
    assert len(matches) == 1, name
    _assert_same_fitting(real_db, raw, matches[0])


def test_every_published_ship_has_the_same_fitting_numbers(real_db, raw):
    ship_groups = {gid for gid, g in raw["groups"].items() if g["categoryID"] == 6}
    ships = [k for k, t in raw["types"].items() if t.get("published") and t["groupID"] in ship_groups]
    assert len(ships) > 300
    for type_id in ships:
        if type_id in raw["dogma"]:
            _assert_same_fitting(real_db, raw, type_id)


def test_only_published_types(real_db, raw):
    published = {k for k, t in raw["types"].items() if t.get("published")}
    in_db = {r[0] for r in real_db.execute("SELECT type_id FROM inv_types")}
    assert in_db == published


def test_all_effect_modifiers_kept(real_db, raw):
    assert real_db.execute("SELECT COUNT(*) FROM dgm_effect_modifiers").fetchone()[0] == raw["modifier_count"]


def test_npc_stations(real_db, raw):
    assert real_db.execute("SELECT COUNT(*) FROM sta_stations").fetchone()[0] == len(raw["stations"])
    jita = real_db.execute("SELECT name_en, solar_system_id FROM sta_stations WHERE station_id = 60003760").fetchone()
    assert jita == ("Jita IV - Moon 4 - Caldari Navy Assembly Plant", 30000142)
    amarr = real_db.execute("SELECT name_en FROM sta_stations WHERE station_id = 60008494").fetchone()[0]
    assert amarr == "Amarr VIII (Oris) - Emperor Family Academy"


def test_the_forge_and_jita(real_db):
    assert real_db.execute("SELECT name_en, name_zh FROM map_regions WHERE region_id = 10000002").fetchone() == (
        "The Forge", "伏尔戈")
    assert real_db.execute(
        "SELECT region_id FROM map_solar_systems WHERE solar_system_id = 30000142").fetchone()[0] == 10000002
