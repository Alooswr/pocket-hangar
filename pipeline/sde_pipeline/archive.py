"""Read the SDE zip without unpacking it to disk.

The file list is read from the archive itself and checked against REQUIRED_FILES; a missing
file stops the build with the real list printed, instead of guessing at a renamed file.
"""

from __future__ import annotations

import io
import json
import zipfile
from pathlib import Path, PurePosixPath
from typing import Iterator

# Logical name -> file name inside the archive. Every name here was taken from the listing of
# eve-online-static-data-3670638-jsonl.zip (2026-11-04), not from memory.
REQUIRED_FILES = {
    "sde": "_sde.jsonl",
    "types": "types.jsonl",
    "groups": "groups.jsonl",
    "categories": "categories.jsonl",
    "dogma_attributes": "dogmaAttributes.jsonl",
    "dogma_effects": "dogmaEffects.jsonl",
    "dogma_units": "dogmaUnits.jsonl",
    "type_dogma": "typeDogma.jsonl",
    "market_groups": "marketGroups.jsonl",
    "meta_groups": "metaGroups.jsonl",
    "regions": "mapRegions.jsonl",
    "constellations": "mapConstellations.jsonl",
    "solar_systems": "mapSolarSystems.jsonl",
    "npc_stations": "npcStations.jsonl",
    # Only used to compose NPC station names (the SDE has no name field for stations).
    "npc_corporations": "npcCorporations.jsonl",
    "station_operations": "stationOperations.jsonl",
    "planets": "mapPlanets.jsonl",
    "moons": "mapMoons.jsonl",
}


class MissingFilesError(RuntimeError):
    def __init__(self, missing: list[str], available: list[str]):
        self.missing = missing
        self.available = available
        super().__init__(
            "SDE archive is missing required files: "
            + ", ".join(missing)
            + "\nFiles in archive:\n  "
            + "\n  ".join(available)
        )


class SdeArchive:
    def __init__(self, path: Path | str):
        self.path = Path(path)
        self._zip = zipfile.ZipFile(self.path)
        # Map bare file name -> member path, so a top-level folder inside the zip does not matter.
        self._members: dict[str, str] = {}
        for info in self._zip.infolist():
            if info.is_dir():
                continue
            self._members[PurePosixPath(info.filename).name] = info.filename

    def close(self) -> None:
        self._zip.close()

    def __enter__(self) -> "SdeArchive":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    def list_files(self) -> list[tuple[str, int]]:
        """(member name, uncompressed size) for every file, sorted by name."""
        return sorted(
            (info.filename, info.file_size) for info in self._zip.infolist() if not info.is_dir()
        )

    def check_required(self) -> None:
        missing = [name for name in REQUIRED_FILES.values() if name not in self._members]
        if missing:
            raise MissingFilesError(missing, [name for name, _ in self.list_files()])

    def iter_records(self, logical_name: str) -> Iterator[dict]:
        file_name = REQUIRED_FILES[logical_name]
        member = self._members.get(file_name)
        if member is None:
            raise MissingFilesError([file_name], [name for name, _ in self.list_files()])
        with self._zip.open(member) as raw:
            for line in io.TextIOWrapper(raw, encoding="utf-8"):
                line = line.strip()
                if line:
                    yield json.loads(line)

    def build_info(self) -> dict:
        for record in self.iter_records("sde"):
            if record.get("_key") == "sde":
                return record
        raise ValueError("_sde.jsonl has no record with _key == 'sde'")
