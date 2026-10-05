#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")
    raise SystemExit(1)


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [x.strip() for x in result.stdout.splitlines() if x.strip()]


def validate_referrals() -> None:
    manifest_path = ROOT / "REFERRAL_ATTRIBUTION.json"
    redirects_path = ROOT / "_redirects"

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    campaigns = data.get("campaigns")
    if not isinstance(campaigns, list) or not campaigns:
        fail("referral manifest must contain at least one campaign")

    ids: set[str] = set()
    paths: set[str] = set()
    expected_redirects: set[str] = set()

    for campaign in campaigns:
        cid = campaign.get("id", "")
        path = campaign.get("path", "")
        destination = campaign.get("destination", "")
        source = campaign.get("source_platform", "")
        status = campaign.get("status", "")

        if not cid or cid in ids:
            fail(f"invalid or duplicate referral id: {cid!r}")
        if not path.startswith("/r/mb/") or path in paths:
            fail(f"invalid or duplicate referral path: {path!r}")
        if source != "moltbook":
            fail(f"unexpected referral source_platform for {cid}: {source!r}")
        if status not in {"active", "retired"}:
            fail(f"invalid referral status for {cid}: {status!r}")
        if not destination.startswith("https://github.com/JoanAbad82/"):
            fail(f"referral destination must stay on the owned GitHub surface: {cid}")

        ids.add(cid)
        paths.add(path)
        if status == "active":
            expected_redirects.add(f"{path} {destination} 302")

    actual_redirects = {
        line.strip()
        for line in redirects_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if actual_redirects != expected_redirects:
        fail("_redirects does not exactly match active referral campaigns")

    if data.get("privacy", {}).get("unique_per_agent_tokens") is not False:
        fail("referral attribution must not use per-agent tokens")
    if data.get("privacy", {}).get("fingerprinting") is not False:
        fail("referral attribution must not enable fingerprinting")
    if data.get("privacy", {}).get("cookies_added") is not False:
        fail("referral attribution must not add cookies")


def main() -> int:
    required = [
        "README.md",
        "AGENTS.md",
        "PROJECT_CONTEXT.json",
        "SECURITY.md",
        "CONTRIBUTING.md",
        "sitemap.xml",
        "robots.txt",
        "index.html",
        "_redirects",
        "REFERRAL_ATTRIBUTION.json",
        "REFERRAL_ATTRIBUTION.md",
        "PROJECT_STATUS.json",
        "llms.txt",
    ]
    for rel in required:
        if not (ROOT / rel).exists():
            fail(f"missing required file: {rel}")

    json.loads((ROOT / "PROJECT_CONTEXT.json").read_text(encoding="utf-8"))
    json.loads((ROOT / "PROJECT_STATUS.json").read_text(encoding="utf-8"))
    ET.parse(ROOT / "sitemap.xml")
    validate_referrals()

    forbidden_claims = [r"No tracking or analytics\.", r"no analytics, no tracking"]
    for rel in ["README.md", "affiliate-friction-auditor/index.html"]:
        text = (ROOT / rel).read_text(encoding="utf-8", errors="ignore")
        for pattern in forbidden_claims:
            if re.search(pattern, text, re.I):
                fail(f"stale analytics claim in {rel}: {pattern}")

    risky = re.compile(r"(^|/)(\.env($|\.)|.*\.(pem|key|p12|pfx)$)", re.I)
    bad = [p for p in tracked_files() if risky.search(p)]
    if bad:
        fail("risky tracked files: " + ", ".join(bad))

    print("PUBLIC_SITE_VERIFY=PASS")
    print("Required context: PASS")
    print("Project context JSON: PASS")
    print("Sitemap XML: PASS")
    print("Referral attribution policy/redirects: PASS")
    print("Privacy/analytics wording: PASS")
    print("Tracked secret-file policy: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
