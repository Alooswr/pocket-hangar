"""Build the trimmed SQLite database the app ships with.

What is kept:
- types: published only, English + Chinese names, plus the columns the app shows or the fitting
  engine needs (mass, volume, capacity, radius ...)
- the groups / categories those types belong to, the whole market group tree, meta groups
- all dogma attribute and effect definitions (small) and the modifier list of every effect
- dogma attributes and effects of every kept type
- regions, constellations, solar systems and NPC stations (station names are composed, see stations.py)
"""

from __future__ import annotations

import os
import re
import sqlite3
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from . import SCHEMA_VERSION
from .archive import SdeArchive
from .stations import StationNamer

LANGS = ("en", "zh")

# Fields the JSONL SDE keeps on the type record but the dogma engine reads as attributes.
# IDs are the dogma attribute IDs named mass / capacity / volume / radius in dogmaAttributes.jsonl.
TYPE_FIELD_ATTRIBUTES = {"mass": 4, "capacity": 38, "volume": 161, "radius": 162}

KNOWN_MODIFIER_FUNCS = {
    "ItemModifier",
    "LocationModifier",
    "LocationGroupModifier",
    "LocationRequiredSkillModifier",
    "OwnerRequiredSkillModifier",
    "EffectStopper",
}

SCHEMA = """
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE inv_categories (
  category_id INTEGER PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_zh TEXT,
  published INTEGER NOT NULL
);

CREATE TABLE inv_groups (
  group_id INTEGER PRIMARY KEY,
  category_id INTEGER NOT NULL,
  name_en TEXT NOT NULL,
  name_zh TEXT,
  published INTEGER NOT NULL
);

CREATE TABLE inv_market_groups (
  market_group_id INTEGER PRIMARY KEY,
  parent_group_id INTEGER,
  name_en TEXT NOT NULL,
  name_zh TEXT,
  has_types INTEGER NOT NULL,
  icon_id INTEGER
);

CREATE TABLE inv_meta_groups (
  meta_group_id INTEGER PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_zh TEXT
);

CREATE TABLE inv_types (
  type_id INTEGER PRIMARY KEY,
  group_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  market_group_id INTEGER,
  meta_group_id INTEGER,
  meta_level INTEGER,
  tech_level INTEGER,
  race_id INTEGER,
  faction_id INTEGER,
  variation_parent_type_id INTEGER,
  name_en TEXT NOT NULL,
  name_zh TEXT,
  mass REAL,
  volume REAL,
  packaged_volume REAL,
  capacity REAL,
  radius REAL,
  portion_size INTEGER,
  base_price REAL,
  icon_id INTEGER
);
CREATE INDEX idx_inv_types_group ON inv_types(group_id);
CREATE INDEX idx_inv_types_category ON inv_types(category_id);
CREATE INDEX idx_inv_types_market_group ON inv_types(market_group_id);

CREATE TABLE dgm_units (
  unit_id INTEGER PRIMARY KEY,
  name TEXT,
  display_name_en TEXT,
  display_name_zh TEXT
);

CREATE TABLE dgm_attributes (
  attribute_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  display_name_en TEXT,
  display_name_zh TEXT,
  default_value REAL NOT NULL,
  stackable INTEGER NOT NULL,
  high_is_good INTEGER NOT NULL,
  published INTEGER NOT NULL,
  unit_id INTEGER,
  category_id INTEGER,
  data_type INTEGER,
  max_attribute_id INTEGER,
  min_attribute_id INTEGER
);

CREATE TABLE dgm_effects (
  effect_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  duration_attribute_id INTEGER,
  discharge_attribute_id INTEGER,
  range_attribute_id INTEGER,
  falloff_attribute_id INTEGER,
  tracking_speed_attribute_id INTEGER,
  resistance_attribute_id INTEGER,
  is_offensive INTEGER NOT NULL,
  is_assistance INTEGER NOT NULL,
  published INTEGER NOT NULL
);

CREATE TABLE dgm_effect_modifiers (
  effect_id INTEGER NOT NULL,
  position INTEGER NOT NULL,
  func TEXT NOT NULL,
  domain TEXT,
  modified_attribute_id INTEGER,
  modifying_attribute_id INTEGER,
  operation INTEGER,
  group_id INTEGER,
  skill_type_id INTEGER,
  stopped_effect_id INTEGER,
  PRIMARY KEY (effect_id, position)
) WITHOUT ROWID;

CREATE TABLE dgm_type_attributes (
  type_id INTEGER NOT NULL,
  attribute_id INTEGER NOT NULL,
  value REAL NOT NULL,
  PRIMARY KEY (type_id, attribute_id)
) WITHOUT ROWID;

CREATE TABLE dgm_type_effects (
  type_id INTEGER NOT NULL,
  effect_id INTEGER NOT NULL,
  is_default INTEGER NOT NULL,
  PRIMARY KEY (type_id, effect_id)
) WITHOUT ROWID;

CREATE TABLE map_regions (
  region_id INTEGER PRIMARY KEY,
  name_en TEXT NOT NULL,
  name_zh TEXT
);

CREATE TABLE map_constellations (
  constellation_id INTEGER PRIMARY KEY,
  region_id INTEGER NOT NULL,
  name_en TEXT NOT NULL,
  name_zh TEXT
);

CREATE TABLE map_solar_systems (
  solar_system_id INTEGER PRIMARY KEY,
  constellation_id INTEGER NOT NULL,
  region_id INTEGER NOT NULL,
  name_en TEXT NOT NULL,
  name_zh TEXT,
  security_status REAL
);

CREATE TABLE sta_stations (
  station_id INTEGER PRIMARY KEY,
  solar_system_id INTEGER NOT NULL,
  type_id INTEGER,
  owner_id INTEGER,
  name_en TEXT NOT NULL,
  name_zh TEXT
);
CREATE INDEX idx_sta_stations_system ON sta_stations(solar_system_id);
"""

_KEY_PREFIX = re.compile(r'^\{"_key":\s*(-?\d+)')


def _names(record: dict, field: str = "name") -> tuple[str | None, str | None]:
    value = record.get(field)
    if isinstance(value, str):
        return value, None
    if not isinstance(value, dict):
        return None, None
    return value.get("en"), value.get("zh")


def _bool(value) -> int:
    return 1 if value else 0


def _iter_filtered(archive: SdeArchive, logical_name: str, wanted: set[int]):
    """Like iter_records, but skips lines whose _key is not wanted before parsing them.

    mapMoons.jsonl is ~220 MB and we only need the few thousand moons that host a station.
    """
    import io
    import json

    file_name = archive_member(archive, logical_name)
    with archive._zip.open(file_name) as raw:  # noqa: SLF001 - same package
        for line in io.TextIOWrapper(raw, encoding="utf-8"):
            match = _KEY_PREFIX.match(line)
            if match and int(match.group(1)) not in wanted:
                continue
            line = line.strip()
            if line:
                record = json.loads(line)
                if record.get("_key") in wanted:
                    yield record


def archive_member(archive: SdeArchive, logical_name: str) -> str:
    from .archive import REQUIRED_FILES, MissingFilesError

    member = archive._members.get(REQUIRED_FILES[logical_name])  # noqa: SLF001
    if member is None:
        raise MissingFilesError([REQUIRED_FILES[logical_name]], [n for n, _ in archive.list_files()])
    return member


def build_database(archive: SdeArchive, out_path: Path | str, log: Callable[[str], None] = print) -> dict:
    """Build the database at out_path (atomically) and return row counts and build info."""
    started = time.monotonic()
    archive.check_required()
    info = archive.build_info()
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = out_path.with_name(out_path.name + ".building")
    if tmp_path.exists():
        tmp_path.unlink()

    con = sqlite3.connect(tmp_path)
    try:
        con.execute("PRAGMA page_size = 4096")
        con.execute("PRAGMA journal_mode = OFF")
        con.execute("PRAGMA synchronous = OFF")
        con.executescript(SCHEMA)
        counts: dict[str, int] = {}
        with con:
            counts.update(_build_inventory(archive, con, log))
            counts.update(_build_dogma(archive, con, log))
            counts.update(_build_map(archive, con, log))
            meta = {
                "buildNumber": str(info["buildNumber"]),
                "releaseDate": str(info.get("releaseDate", "")),
                "schemaVersion": str(SCHEMA_VERSION),
                "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "languages": ",".join(LANGS),
            }
            con.executemany("INSERT INTO meta(key, value) VALUES (?, ?)", sorted(meta.items()))
        con.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
        con.execute("VACUUM")
    finally:
        con.close()
    os.replace(tmp_path, out_path)
    log(f"database written: {out_path} ({out_path.stat().st_size / 1e6:.1f} MB) in {time.monotonic() - started:.1f}s")
    return {"buildNumber": info["buildNumber"], "releaseDate": info.get("releaseDate"), "counts": counts}


def _build_inventory(archive: SdeArchive, con: sqlite3.Connection, log) -> dict[str, int]:
    categories = {r["_key"]: r for r in archive.iter_records("categories")}
    groups = {r["_key"]: r for r in archive.iter_records("groups")}

    type_rows = []
    used_groups: set[int] = set()
    for t in archive.iter_records("types"):
        if not t.get("published"):
            continue
        group = groups.get(t["groupID"])
        if group is None:
            raise ValueError(f"type {t['_key']} references unknown group {t['groupID']}")
        name_en, name_zh = _names(t)
        if not name_en:
            raise ValueError(f"published type {t['_key']} has no English name")
        used_groups.add(t["groupID"])
        type_rows.append((
            t["_key"], t["groupID"], group["categoryID"], t.get("marketGroupID"), t.get("metaGroupID"),
            t.get("metaLevel"), t.get("techLevel"), t.get("raceID"), t.get("factionID"),
            t.get("variationParentTypeID"), name_en, name_zh, t.get("mass"), t.get("volume"),
            t.get("packagedVolume"), t.get("capacity"), t.get("radius"), t.get("portionSize"),
            t.get("basePrice"), t.get("iconID"),
        ))
    con.executemany(f"INSERT INTO inv_types VALUES ({','.join('?' * 20)})", type_rows)

    used_categories = {groups[g]["categoryID"] for g in used_groups}
    group_rows = []
    for gid in sorted(used_groups):
        g = groups[gid]
        en, zh = _names(g)
        group_rows.append((gid, g["categoryID"], en or str(gid), zh, _bool(g.get("published"))))
    con.executemany("INSERT INTO inv_groups VALUES (?,?,?,?,?)", group_rows)

    category_rows = []
    for cid in sorted(used_categories):
        c = categories[cid]
        en, zh = _names(c)
        category_rows.append((cid, en or str(cid), zh, _bool(c.get("published"))))
    con.executemany("INSERT INTO inv_categories VALUES (?,?,?,?)", category_rows)

    market_rows = []
    for m in archive.iter_records("market_groups"):
        en, zh = _names(m)
        market_rows.append((m["_key"], m.get("parentGroupID"), en or str(m["_key"]), zh,
                            _bool(m.get("hasTypes")), m.get("iconID")))
    con.executemany("INSERT INTO inv_market_groups VALUES (?,?,?,?,?,?)", market_rows)

    meta_rows = []
    for m in archive.iter_records("meta_groups"):
        en, zh = _names(m)
        meta_rows.append((m["_key"], en or str(m["_key"]), zh))
    con.executemany("INSERT INTO inv_meta_groups VALUES (?,?,?)", meta_rows)

    log(f"inventory: {len(type_rows)} published types, {len(group_rows)} groups, "
        f"{len(category_rows)} categories, {len(market_rows)} market groups")
    return {
        "types": len(type_rows),
        "groups": len(group_rows),
        "categories": len(category_rows),
        "market_groups": len(market_rows),
        "meta_groups": len(meta_rows),
    }


def _build_dogma(archive: SdeArchive, con: sqlite3.Connection, log) -> dict[str, int]:
    unit_rows = []
    for u in archive.iter_records("dogma_units"):
        en, zh = _names(u, "displayName")
        unit_rows.append((u["_key"], u.get("name"), en, zh))
    con.executemany("INSERT INTO dgm_units VALUES (?,?,?,?)", unit_rows)

    attribute_rows = []
    for a in archive.iter_records("dogma_attributes"):
        en, zh = _names(a, "displayName")
        attribute_rows.append((
            a["_key"], a["name"], en, zh, float(a.get("defaultValue", 0.0)), _bool(a.get("stackable")),
            _bool(a.get("highIsGood")), _bool(a.get("published")), a.get("unitID"),
            a.get("attributeCategoryID"), a.get("dataType"), a.get("maxAttributeID"), a.get("minAttributeID"),
        ))
    con.executemany(f"INSERT INTO dgm_attributes VALUES ({','.join('?' * 13)})", attribute_rows)

    effect_rows = []
    modifier_rows = []
    unknown_funcs: set[str] = set()
    for e in archive.iter_records("dogma_effects"):
        effect_rows.append((
            e["_key"], e["name"], e.get("effectCategoryID", 0), e.get("durationAttributeID"),
            e.get("dischargeAttributeID"), e.get("rangeAttributeID"), e.get("falloffAttributeID"),
            e.get("trackingSpeedAttributeID"), e.get("resistanceAttributeID"), _bool(e.get("isOffensive")),
            _bool(e.get("isAssistance")), _bool(e.get("published")),
        ))
        for position, m in enumerate(e.get("modifierInfo") or []):
            if m.get("func") not in KNOWN_MODIFIER_FUNCS:
                unknown_funcs.add(str(m.get("func")))
            modifier_rows.append((
                e["_key"], position, m.get("func"), m.get("domain"), m.get("modifiedAttributeID"),
                m.get("modifyingAttributeID"), m.get("operation"), m.get("groupID"), m.get("skillTypeID"),
                m.get("effectID"),
            ))
    if unknown_funcs:
        # Not fatal: the app skips modifiers it does not understand. Make it visible in the CI log though.
        log(f"WARNING: unknown modifier funcs in SDE: {sorted(unknown_funcs)}")
    con.executemany(f"INSERT INTO dgm_effects VALUES ({','.join('?' * 12)})", effect_rows)
    con.executemany(f"INSERT INTO dgm_effect_modifiers VALUES ({','.join('?' * 10)})", modifier_rows)

    kept = {row[0]: row for row in con.execute("SELECT type_id, mass, capacity, volume, radius FROM inv_types")}
    attr_rows = []
    effect_link_rows = []
    seen_attr: dict[int, set[int]] = {}
    for td in archive.iter_records("type_dogma"):
        type_id = td["_key"]
        if type_id not in kept:
            continue
        ids = seen_attr.setdefault(type_id, set())
        for a in td.get("dogmaAttributes") or []:
            ids.add(a["attributeID"])
            attr_rows.append((type_id, a["attributeID"], float(a["value"])))
        for ef in td.get("dogmaEffects") or []:
            effect_link_rows.append((type_id, ef["effectID"], _bool(ef.get("isDefault"))))
    # mass / capacity / volume / radius live on the type record; expose them as dogma attributes too.
    field_index = {"mass": 1, "capacity": 2, "volume": 3, "radius": 4}
    for type_id, row in kept.items():
        ids = seen_attr.get(type_id, set())
        for field, attribute_id in TYPE_FIELD_ATTRIBUTES.items():
            value = row[field_index[field]]
            if value is not None and attribute_id not in ids:
                attr_rows.append((type_id, attribute_id, float(value)))
    con.executemany("INSERT INTO dgm_type_attributes VALUES (?,?,?)", attr_rows)
    con.executemany("INSERT INTO dgm_type_effects VALUES (?,?,?)", effect_link_rows)

    log(f"dogma: {len(attribute_rows)} attributes, {len(effect_rows)} effects, {len(modifier_rows)} modifiers, "
        f"{len(attr_rows)} type attributes, {len(effect_link_rows)} type effects")
    return {
        "units": len(unit_rows),
        "attributes": len(attribute_rows),
        "effects": len(effect_rows),
        "effect_modifiers": len(modifier_rows),
        "type_attributes": len(attr_rows),
        "type_effects": len(effect_link_rows),
    }


def _build_map(archive: SdeArchive, con: sqlite3.Connection, log) -> dict[str, int]:
    region_rows = []
    for r in archive.iter_records("regions"):
        en, zh = _names(r)
        region_rows.append((r["_key"], en or str(r["_key"]), zh))
    con.executemany("INSERT INTO map_regions VALUES (?,?,?)", region_rows)

    constellation_rows = []
    for c in archive.iter_records("constellations"):
        en, zh = _names(c)
        constellation_rows.append((c["_key"], c["regionID"], en or str(c["_key"]), zh))
    con.executemany("INSERT INTO map_constellations VALUES (?,?,?,?)", constellation_rows)

    system_rows = []
    system_names: dict[int, dict] = {}
    for s in archive.iter_records("solar_systems"):
        en, zh = _names(s)
        system_names[s["_key"]] = s.get("name") or {}
        system_rows.append((s["_key"], s["constellationID"], s["regionID"], en or str(s["_key"]), zh,
                            s.get("securityStatus")))
    con.executemany("INSERT INTO map_solar_systems VALUES (?,?,?,?,?,?)", system_rows)

    stations = list(archive.iter_records("npc_stations"))
    orbit_ids = {s.get("orbitID") for s in stations if s.get("orbitID") is not None}
    planets = {
        p["_key"]: {"celestialIndex": p.get("celestialIndex"), "uniqueName": p.get("uniqueName")}
        for p in archive.iter_records("planets")
    }
    moons = {
        m["_key"]: {"orbitID": m.get("orbitID"), "orbitIndex": m.get("orbitIndex"), "uniqueName": m.get("uniqueName")}
        for m in _iter_filtered(archive, "moons", orbit_ids - set(planets))
    }
    corporations = {c["_key"]: c.get("name") or {} for c in archive.iter_records("npc_corporations")}
    operations = {o["_key"]: o.get("operationName") or {} for o in archive.iter_records("station_operations")}
    namer = StationNamer(system_names, planets, moons, corporations, operations)

    station_rows = []
    for s in stations:
        station_rows.append((s["_key"], s["solarSystemID"], s.get("typeID"), s.get("ownerID"),
                             namer.name(s, "en"), namer.name(s, "zh")))
    con.executemany("INSERT INTO sta_stations VALUES (?,?,?,?,?,?)", station_rows)

    log(f"map: {len(region_rows)} regions, {len(constellation_rows)} constellations, "
        f"{len(system_rows)} systems, {len(station_rows)} NPC stations")
    return {
        "regions": len(region_rows),
        "constellations": len(constellation_rows),
        "solar_systems": len(system_rows),
        "stations": len(station_rows),
    }
