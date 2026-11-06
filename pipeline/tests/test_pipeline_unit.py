"""Builder logic on a hand-written mini SDE (no network, no 100 MB download)."""

from __future__ import annotations

import gzip
import hashlib
import json
import sqlite3
from pathlib import Path

import pytest

from conftest import MINI_SDE, write_sde_zip
from sde_pipeline import SCHEMA_VERSION
from sde_pipeline.archive import MissingFilesError, SdeArchive
from sde_pipeline.builder import build_database
from sde_pipeline.manifest import gzip_file, make_manifest, needs_build, read_manifest, write_manifest
from sde_pipeline.sources import parse_latest
from sde_pipeline.stations import roman


def test_roman_numerals():
    assert [roman(n) for n in (1, 4, 9, 14, 40, 90, 400, 1994)] == [
        "I", "IV", "IX", "XIV", "XL", "XC", "CD", "MCMXCIV"]
    with pytest.raises(ValueError):
        roman(0)


def test_parse_latest_picks_sde_record():
    text = '{"_key": "other", "buildNumber": 1}\n{"_key": "sde", "buildNumber": 3670638, "releaseDate": "x"}\n'
    assert parse_latest(text)["buildNumber"] == 3670638
    with pytest.raises(ValueError):
        parse_latest('{"_key": "nope"}\n')


def test_missing_file_is_reported_with_real_listing(tmp_path: Path):
    files = dict(MINI_SDE)
    files.pop("typeDogma.jsonl")
    path = write_sde_zip(tmp_path / "broken.zip", files)
    with SdeArchive(path) as archive:
        with pytest.raises(MissingFilesError) as err:
            archive.check_required()
    assert err.value.missing == ["typeDogma.jsonl"]
    assert "types.jsonl" in err.value.available


def test_files_inside_a_folder_are_found(tmp_path: Path):
    path = write_sde_zip(tmp_path / "nested.zip", MINI_SDE, prefix="sde/")
    with SdeArchive(path) as archive:
        archive.check_required()
        assert archive.build_info()["buildNumber"] == 123


def test_only_published_types_are_kept(mini_db: sqlite3.Connection):
    ids = {row[0] for row in mini_db.execute("SELECT type_id FROM inv_types")}
    assert ids == {587, 2048, 3327}
    assert mini_db.execute("SELECT COUNT(*) FROM dgm_type_attributes WHERE type_id = 588").fetchone()[0] == 0


def test_names_keep_english_and_chinese(mini_db: sqlite3.Connection):
    row = mini_db.execute("SELECT name_en, name_zh, category_id FROM inv_types WHERE type_id = 587").fetchone()
    assert row == ("Rifter", "裂谷级", 6)
    cols = [r[1] for r in mini_db.execute("PRAGMA table_info(inv_types)")]
    assert "description" not in " ".join(cols)


def test_unused_groups_and_categories_are_dropped(mini_db: sqlite3.Connection):
    assert {r[0] for r in mini_db.execute("SELECT group_id FROM inv_groups")} == {25, 60, 257}
    assert {r[0] for r in mini_db.execute("SELECT category_id FROM inv_categories")} == {6, 7, 16}


def test_type_fields_become_dogma_attributes(mini_db: sqlite3.Connection):
    attrs = dict(mini_db.execute("SELECT attribute_id, value FROM dgm_type_attributes WHERE type_id = 587"))
    assert attrs[4] == 1067000.0  # mass came from the type record
    assert attrs[161] == 27289.0  # volume
    assert attrs[162] == 31.0  # radius
    assert attrs[38] == 135.0  # typeDogma wins over the type record (140) when both exist
    assert attrs[14] == 3.0 and attrs[13] == 3.0 and attrs[12] == 4.0


def test_effect_modifiers_are_normalised(mini_db: sqlite3.Connection):
    rows = mini_db.execute(
        "SELECT effect_id, position, func, domain, modified_attribute_id, modifying_attribute_id, operation, "
        "skill_type_id, stopped_effect_id FROM dgm_effect_modifiers ORDER BY effect_id").fetchall()
    assert rows == [
        (7248, 0, "LocationRequiredSkillModifier", "shipID", 51, 460, 6, 3302, None),
        (9999, 0, "EffectStopper", "target", None, None, None, None, 16),
    ]
    stack = mini_db.execute("SELECT stackable, max_attribute_id FROM dgm_attributes WHERE attribute_id = 109").fetchone()
    assert stack == (0, 2770)


def test_station_names_are_composed(mini_db: sqlite3.Connection):
    names = {r[0]: r[1:] for r in mini_db.execute("SELECT station_id, name_en, name_zh FROM sta_stations")}
    assert names[60003760] == ("Jita IV - Moon 4 - Caldari Navy Assembly Plant", "吉他 IV - 卫星 4 - 加达里海军 组装车间")
    # planet with a unique name, operation name not used
    assert names[60000001] == ("Jita VIII (Example) - Caldari Navy", "吉他 VIII (例子) - 加达里海军")


def test_meta_and_user_version(mini_db: sqlite3.Connection):
    meta = dict(mini_db.execute("SELECT key, value FROM meta"))
    assert meta["buildNumber"] == "123"
    assert meta["releaseDate"] == "2026-01-02T03:04:05Z"
    assert meta["schemaVersion"] == str(SCHEMA_VERSION)
    assert mini_db.execute("PRAGMA user_version").fetchone()[0] == SCHEMA_VERSION


def test_manifest_hash_and_size_match_the_gz(tmp_path: Path, mini_zip: Path):
    db = tmp_path / "x.sqlite"
    with SdeArchive(mini_zip) as archive:
        build_database(archive, db, log=lambda _m: None)
    gz = gzip_file(db, tmp_path / "x.sqlite.gz")
    manifest = make_manifest(123, "2026-01-02T03:04:05Z", "https://example.invalid/x.sqlite.gz", gz, db)
    assert manifest["sha256"] == hashlib.sha256(gz.read_bytes()).hexdigest()
    assert manifest["size"] == gz.stat().st_size
    assert manifest["uncompressedSha256"] == hashlib.sha256(db.read_bytes()).hexdigest()
    assert gzip.decompress(gz.read_bytes()) == db.read_bytes()
    assert set(manifest) >= {"buildNumber", "releaseDate", "url", "sha256", "size"}
    path = write_manifest(manifest, tmp_path / "manifest.json")
    assert read_manifest(str(path)) == json.loads(path.read_text(encoding="utf-8"))


def test_gzip_is_deterministic(tmp_path: Path):
    src = tmp_path / "a.bin"
    src.write_bytes(b"x" * 10000)
    first = gzip_file(src, tmp_path / "1.gz").read_bytes()
    second = gzip_file(src, tmp_path / "2.gz").read_bytes()
    assert first == second


def test_needs_build_decision():
    previous = {"buildNumber": 100, "schemaVersion": SCHEMA_VERSION}
    assert needs_build(100, previous) is False
    assert needs_build(101, previous) is True
    assert needs_build(100, None) is True
    assert needs_build(100, previous, force=True) is True
    assert needs_build(100, {"buildNumber": 100, "schemaVersion": SCHEMA_VERSION - 1}) is True
    assert read_manifest("does/not/exist.json") is None
