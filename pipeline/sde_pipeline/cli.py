"""Command line entry points used by the GitHub Actions workflow (and by hand).

  python -m sde_pipeline latest
  python -m sde_pipeline check --previous <manifest url or path> [--force] [--github-output]
  python -m sde_pipeline download --build N --dest DIR
  python -m sde_pipeline list --zip FILE
  python -m sde_pipeline build --zip FILE --out-dir DIR --url-template TEMPLATE
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from . import SCHEMA_VERSION
from .archive import SdeArchive
from .builder import build_database
from .manifest import gzip_file, make_manifest, needs_build, read_manifest, write_manifest
from .sources import ZIP_URL_TEMPLATE, download, fetch_latest


def _github_output(values: dict) -> None:
    path = os.environ.get("GITHUB_OUTPUT")
    if not path:
        return
    with open(path, "a", encoding="utf-8") as f:
        for key, value in values.items():
            f.write(f"{key}={value}\n")


def cmd_latest(_args) -> int:
    print(json.dumps(fetch_latest()))
    return 0


def cmd_check(args) -> int:
    latest = fetch_latest()
    previous = read_manifest(args.previous)
    changed = needs_build(latest["buildNumber"], previous, force=args.force)
    result = {
        "build": latest["buildNumber"],
        "release_date": latest.get("releaseDate", ""),
        "previous": previous.get("buildNumber") if previous else "",
        "changed": "true" if changed else "false",
    }
    print(json.dumps(result))
    if args.github_output:
        _github_output(result)
    return 0


def cmd_download(args) -> int:
    dest = Path(args.dest) / f"eve-online-static-data-{args.build}-jsonl.zip"
    download(ZIP_URL_TEMPLATE.format(build=args.build), dest)
    print(dest)
    return 0


def cmd_list(args) -> int:
    with SdeArchive(args.zip) as archive:
        for name, size in archive.list_files():
            print(f"{size:>12}  {name}")
    return 0


def cmd_build(args) -> int:
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    with SdeArchive(args.zip) as archive:
        print("files in archive:")
        for name, size in archive.list_files():
            print(f"  {size:>12}  {name}")
        archive.check_required()
        build = archive.build_info()["buildNumber"]
        db_path = out_dir / f"eve-sde-{build}.sqlite"
        result = build_database(archive, db_path)
    gz_path = gzip_file(db_path, out_dir / f"{db_path.name}.gz")
    url = args.url_template.format(build=build, file=gz_path.name)
    manifest = make_manifest(build, result.get("releaseDate") or "", url, gz_path, db_path)
    write_manifest(manifest, out_dir / "manifest.json")
    (out_dir / "build-stats.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    _github_output({"db": str(db_path), "gz": str(gz_path), "manifest": str(out_dir / "manifest.json"),
                    "build": build, "schema_version": SCHEMA_VERSION})
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="sde_pipeline")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("latest", help="print the latest SDE build record").set_defaults(func=cmd_latest)

    p = sub.add_parser("check", help="compare the latest build with the previous manifest")
    p.add_argument("--previous", help="URL or path of the previously published manifest.json")
    p.add_argument("--force", action="store_true")
    p.add_argument("--github-output", action="store_true")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("download", help="download one SDE build")
    p.add_argument("--build", type=int, required=True)
    p.add_argument("--dest", required=True)
    p.set_defaults(func=cmd_download)

    p = sub.add_parser("list", help="list files inside an SDE zip")
    p.add_argument("--zip", required=True)
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("build", help="build sqlite + gzip + manifest.json")
    p.add_argument("--zip", required=True)
    p.add_argument("--out-dir", required=True)
    p.add_argument(
        "--url-template",
        default="https://github.com/Alooswr/pocket-hangar/releases/download/sde-{build}/{file}",
        help="download URL written into manifest.json; {build} and {file} are filled in",
    )
    p.set_defaults(func=cmd_build)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
