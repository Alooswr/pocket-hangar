"""Builds test/fixtures/sde_test.sqlite, a small slice of a built SDE database for the app's tests.

It keeps every dogma definition (attributes, effects, modifiers, units), every skill, and the
handful of ships, modules, charges and drones the tests fit, plus Jita for station names.

    python pipeline/tools/make_test_fixture.py --db <eve-sde-NNN.sqlite> --out test/fixtures/sde_test.sqlite

The data is CCP's (see the README); regenerate it after a schema change.
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import sys

TYPE_NAMES = [
    # ships
    "Rifter",
    "Merlin",
    "Punisher",
    "Legion",
    # modules
    "1MN Afterburner II",
    "5MN Microwarpdrive II",
    "Damage Control II",
    "Medium Shield Extender II",
    "Small Ancillary Current Router I",
    "Reactive Armor Hardener",
    "200mm AutoCannon II",
    "125mm Gatling AutoCannon II",
    "Small Armor Repairer II",
    "Gyrostabilizer II",
    "Overdrive Injector System II",
    "Small Capacitor Booster II",
    "Warp Scrambler II",
    "Stasis Webifier II",
    "Multispectrum Shield Hardener II",
    "Light Missile Launcher II",
    "200mm Steel Plates II",
    "Small Core Defense Field Extender I",
    "Nanofiber Internal Structure II",
    "Co-Processor II",
    # charges
    "EMP S",
    "Phased Plasma S",
    "Fusion S",
    "Navy Cap Booster 100",
    "Cap Booster 100",
    "Scourge Light Missile",
    # drones
    "Warrior II",
    "Hobgoblin II",
]

FULL_TABLES = [
    "meta",
    "inv_categories",
    "inv_groups",
    "inv_market_groups",
    "inv_meta_groups",
    "dgm_units",
    "dgm_attributes",
    "dgm_effects",
    "dgm_effect_modifiers",
]

JITA_SYSTEM = 30000142
JITA_44 = 60003760
SKILL_CATEGORY = 16
SUBSYSTEM_CATEGORY = 32


def build(src_path: str, out_path: str) -> dict[str, int]:
    if os.path.exists(out_path):
        os.remove(out_path)
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    src = sqlite3.connect(f"file:{src_path}?mode=ro", uri=True)
    dst = sqlite3.connect(out_path)
    for (sql,) in src.execute("SELECT sql FROM sqlite_master WHERE type IN ('table', 'index') AND sql IS NOT NULL"):
        dst.execute(sql)

    def copy(table: str, where: str = "", args: tuple = ()) -> int:
        rows = src.execute(f"SELECT * FROM {table} {where}", args).fetchall()
        if rows:
            marks = ",".join("?" * len(rows[0]))
            dst.executemany(f"INSERT INTO {table} VALUES ({marks})", rows)
        return len(rows)

    counts = {t: copy(t) for t in FULL_TABLES}

    type_ids: set[int] = set()
    missing = []
    for name in TYPE_NAMES:
        row = src.execute("SELECT type_id FROM inv_types WHERE name_en = ?", (name,)).fetchone()
        if row is None:
            missing.append(name)
        else:
            type_ids.add(row[0])
    if missing:
        raise SystemExit(f"types not found in {src_path}: {missing}")
    type_ids.update(r[0] for r in src.execute("SELECT type_id FROM inv_types WHERE category_id = ?", (SKILL_CATEGORY,)))
    type_ids.update(
        r[0]
        for r in src.execute(
            "SELECT type_id FROM inv_types WHERE category_id = ? AND name_en LIKE 'Legion %'", (SUBSYSTEM_CATEGORY,)
        )
    )
    id_list = ",".join(str(i) for i in sorted(type_ids))
    counts["inv_types"] = copy("inv_types", f"WHERE type_id IN ({id_list})")
    counts["dgm_type_attributes"] = copy("dgm_type_attributes", f"WHERE type_id IN ({id_list})")
    counts["dgm_type_effects"] = copy("dgm_type_effects", f"WHERE type_id IN ({id_list})")

    system = src.execute(
        "SELECT constellation_id, region_id FROM map_solar_systems WHERE solar_system_id = ?", (JITA_SYSTEM,)
    ).fetchone()
    counts["map_regions"] = copy("map_regions", "WHERE region_id = ?", (system[1],))
    counts["map_constellations"] = copy("map_constellations", "WHERE constellation_id = ?", (system[0],))
    counts["map_solar_systems"] = copy("map_solar_systems", "WHERE solar_system_id = ?", (JITA_SYSTEM,))
    counts["sta_stations"] = copy("sta_stations", "WHERE station_id = ?", (JITA_44,))

    (user_version,) = src.execute("PRAGMA user_version").fetchone()
    dst.execute(f"PRAGMA user_version = {int(user_version)}")
    dst.commit()
    dst.execute("VACUUM")
    dst.close()
    src.close()
    return counts


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--db", required=True, help="built SDE sqlite (pipeline output)")
    parser.add_argument("--out", default="test/fixtures/sde_test.sqlite")
    args = parser.parse_args(argv)
    counts = build(args.db, args.out)
    for table, n in counts.items():
        print(f"{table:24} {n}")
    print(f"{args.out}: {os.path.getsize(args.out)} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
