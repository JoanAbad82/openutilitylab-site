#!/usr/bin/env python3
"""Bounded read-only bridge from the canonical public GitHub Portfolio Pulse."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone, timedelta
import json
from pathlib import Path
import re
from urllib.request import Request, urlopen
from urllib.parse import urlsplit

import jsonschema

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = ROOT / "schemas" / "profile-pulse.v1.schema.json"
SNAPSHOT = ROOT / "data" / "profile-pulse.json"
SOURCE = "https://raw.githubusercontent.com/JoanAbad82/JoanAbad82/main/profile-pulse.json"
MAX_BYTES = 96 * 1024
RECORD_GROUPS = ("accepted_upstream", "accepted_inbound", "external_inbound", "contribution_tasks")


class PulseValidationError(ValueError):
    pass


def validate_snapshot(document: object, schema_path: Path = SCHEMA) -> dict:
    """Validate published JSON Schema plus referential/temporal constraints."""
    if not isinstance(document, dict):
        raise PulseValidationError("snapshot is not an object")
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    jsonschema.Draft202012Validator.check_schema(schema)
    errors = sorted(
        jsonschema.Draft202012Validator(
            schema, format_checker=jsonschema.FormatChecker()
        ).iter_errors(document),
        key=lambda error: tuple(str(part) for part in error.path),
    )
    if errors:
        raise PulseValidationError("profile-pulse schema: " + errors[0].message)
    stamp = document.get("generated_at")
    if not isinstance(stamp, str):
        raise PulseValidationError("generated_at is required by this bridge")
    try:
        instant = datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=timezone.utc
        )
    except ValueError as exc:
        raise PulseValidationError("invalid generated_at") from exc
    if instant > datetime.now(timezone.utc) + timedelta(minutes=10):
        raise PulseValidationError("generated_at is in the future")

    for group in RECORD_GROUPS:
        for item in document[group]:
            expected_kind = "issues" if group == "contribution_tasks" else "pull"
            expected = f"https://github.com/{item['repo']}/{expected_kind}/{item['number']}"
            if item["url"] != expected:
                raise PulseValidationError(f"{group} repository/number mismatch")
            # Author is an attributed public profile name; never an instruction.
            if not re.fullmatch(r"[A-Za-z0-9-]{1,39}", item["author"]):
                raise PulseValidationError(f"{group} invalid author")
            parts = urlsplit(item["url"])
            if parts.username or parts.password or parts.query or parts.fragment:
                raise PulseValidationError(f"{group} URL must be canonical")
    return document


def load_local(snapshot: Path = SNAPSHOT, schema_path: Path = SCHEMA) -> dict:
    if snapshot.stat().st_size > MAX_BYTES:
        raise PulseValidationError("local snapshot exceeds byte budget")
    return validate_snapshot(json.loads(snapshot.read_text(encoding="utf-8")), schema_path)


def fetch_source(url: str = SOURCE) -> dict:
    # URL is a constant, not supplied by user input or external metadata.
    request = Request(url, headers={"User-Agent": "OpenUtilityLab-PulseBridge/1.0", "Accept": "application/json"})
    with urlopen(request, timeout=12) as response:
        if response.status != 200 or response.url != SOURCE:
            raise PulseValidationError("unexpected source response or redirect")
        payload = response.read(MAX_BYTES + 1)
    if len(payload) > MAX_BYTES:
        raise PulseValidationError("source snapshot exceeds byte budget")
    return json.loads(payload.decode("utf-8"))


def refresh(snapshot: Path = SNAPSHOT, schema_path: Path = SCHEMA) -> bool:
    # Refuse to replace a corrupted local baseline; retain for forensic review.
    current = load_local(snapshot, schema_path)
    updated = validate_snapshot(fetch_source(), schema_path)
    if updated == current:
        return False
    old_time = current["generated_at"]
    new_time = updated["generated_at"]
    if new_time <= old_time:
        raise PulseValidationError("source timestamp rollback or change without new evidence timestamp")
    # Atomic replace after all validation; writer never mutates homepage or agent tasks.
    from tempfile import NamedTemporaryFile
    import os

    snapshot.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = None
    try:
        with NamedTemporaryFile(
            "w", encoding="utf-8", newline="\n", dir=snapshot.parent,
            prefix=".profile-pulse-", suffix=".tmp", delete=False
        ) as fh:
            json.dump(updated, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
            tmp_path = Path(fh.name)
        os.replace(tmp_path, snapshot)
    finally:
        if tmp_path is not None and tmp_path.exists():
            tmp_path.unlink()
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--check", action="store_true", help="Validate local snapshot offline")
    group.add_argument("--refresh", action="store_true", help="Refresh only if trusted source has changed")
    args = parser.parse_args()
    if args.check:
        try:
            load_local()
        except (OSError, ValueError, jsonschema.exceptions.SchemaError) as exc:
            print("PROFILE_PULSE_LOCAL_VALIDATION=FAIL: " + str(exc))
            return 1
        print("PROFILE_PULSE_LOCAL_VALIDATION=PASS")
        return 0
    try:
        changed = refresh()
    except (OSError, ValueError, UnicodeError, jsonschema.exceptions.SchemaError, TimeoutError) as exc:
        # Fail closed while allowing other periodic agent-task work to continue.
        print("::warning::Portfolio Pulse refresh skipped; last verified snapshot retained: " + type(exc).__name__)
        print("PROFILE_PULSE_REFRESH=SKIPPED")
        return 0
    print("PROFILE_PULSE_REFRESH=" + ("UPDATED" if changed else "UNCHANGED"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
