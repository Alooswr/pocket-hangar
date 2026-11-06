"""Compress the database and describe it in manifest.json.

manifest.json fields (the first five are what the app relies on):
  buildNumber, releaseDate, url, sha256, size   -- sha256/size are of the downloaded (.gz) file
  schemaVersion                                  -- app refuses databases it cannot read
  compression, uncompressedSize, uncompressedSha256
"""

from __future__ import annotations

import gzip
import hashlib
import json
import os
import shutil
from pathlib import Path

from . import SCHEMA_VERSION


def sha256_file(path: Path | str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def gzip_file(src: Path | str, dest: Path | str) -> Path:
    """Deterministic gzip (no file name, mtime 0) so identical input gives identical bytes."""
    dest = Path(dest)
    tmp = dest.with_name(dest.name + ".part")
    with open(src, "rb") as fin, open(tmp, "wb") as raw:
        with gzip.GzipFile(filename="", mode="wb", fileobj=raw, compresslevel=9, mtime=0) as gz:
            shutil.copyfileobj(fin, gz, length=1 << 20)
    os.replace(tmp, dest)
    return dest


def make_manifest(build_number: int, release_date: str, url: str, gz_path: Path | str, db_path: Path | str) -> dict:
    gz_path = Path(gz_path)
    db_path = Path(db_path)
    return {
        "buildNumber": int(build_number),
        "releaseDate": release_date,
        "url": url,
        "sha256": sha256_file(gz_path),
        "size": gz_path.stat().st_size,
        "schemaVersion": SCHEMA_VERSION,
        "compression": "gzip",
        "uncompressedSize": db_path.stat().st_size,
        "uncompressedSha256": sha256_file(db_path),
    }


def write_manifest(manifest: dict, path: Path | str) -> Path:
    path = Path(path)
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return path


def read_manifest(source: str | None, timeout: float = 30) -> dict | None:
    """Read a manifest from a path or URL. Missing (404 / no file) returns None."""
    if not source:
        return None
    if source.startswith(("http://", "https://")):
        import urllib.error
        import urllib.request

        from .sources import USER_AGENT

        try:
            req = urllib.request.Request(source, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return None
            raise
    path = Path(source)
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def needs_build(latest_build: int, previous: dict | None, force: bool = False) -> bool:
    if force or previous is None:
        return True
    if previous.get("schemaVersion") != SCHEMA_VERSION:
        # The pipeline's schema changed since the last release: rebuild even on the same SDE build.
        return True
    return int(previous.get("buildNumber", -1)) != int(latest_build)
