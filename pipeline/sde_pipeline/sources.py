"""Where the SDE lives and how to fetch it.

URLs follow https://developers.eveonline.com/docs/services/static-data/ (checked 2026-11-06):
- latest build number: tranquility/latest.jsonl, record with _key == "sde"
- per-build archive:   tranquility/eve-online-static-data-<build>-jsonl.zip
"""

from __future__ import annotations

import json
import os
import shutil
import time
import urllib.error
import urllib.request
from pathlib import Path

BASE = "https://developers.eveonline.com/static-data/tranquility"
LATEST_URL = f"{BASE}/latest.jsonl"
ZIP_URL_TEMPLATE = BASE + "/eve-online-static-data-{build}-jsonl.zip"

USER_AGENT = os.environ.get(
    "SDE_USER_AGENT",
    "PocketHangar-SDE-Pipeline/1.0 (+https://github.com/Alooswr/pocket-hangar)",
)


def _request(url: str) -> urllib.request.Request:
    return urllib.request.Request(url, headers={"User-Agent": USER_AGENT})


def parse_latest(text: str) -> dict:
    """Return the record with _key == "sde" from latest.jsonl content."""
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        record = json.loads(line)
        if record.get("_key") == "sde":
            if not isinstance(record.get("buildNumber"), int):
                raise ValueError(f"latest.jsonl has no integer buildNumber: {record}")
            return record
    raise ValueError("latest.jsonl has no record with _key == 'sde'")


def fetch_latest(timeout: float = 30) -> dict:
    with urllib.request.urlopen(_request(LATEST_URL), timeout=timeout) as resp:
        return parse_latest(resp.read().decode("utf-8"))


def download(url: str, dest: Path, attempts: int = 4, timeout: float = 120) -> Path:
    """Stream url to dest (via a .part file) with simple exponential backoff."""
    dest = Path(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    part = dest.with_suffix(dest.suffix + ".part")
    last_error: Exception | None = None
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(_request(url), timeout=timeout) as resp, open(part, "wb") as out:
                shutil.copyfileobj(resp, out, length=1 << 20)
            os.replace(part, dest)
            return dest
        except (urllib.error.URLError, TimeoutError, ConnectionError) as exc:
            last_error = exc
            time.sleep(2 ** attempt * 5)
    raise RuntimeError(f"download failed after {attempts} attempts: {url}: {last_error}")
