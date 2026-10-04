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
    print(f'ERROR: {msg}')
    raise SystemExit(1)

def tracked_files() -> list[str]:
    result = subprocess.run(['git','ls-files'], cwd=ROOT, check=True, capture_output=True, text=True)
    return [x.strip() for x in result.stdout.splitlines() if x.strip()]

def main() -> int:
    required = ['README.md','AGENTS.md','PROJECT_CONTEXT.json','SECURITY.md','CONTRIBUTING.md','sitemap.xml','robots.txt','index.html']
    for rel in required:
        if not (ROOT / rel).exists(): fail(f'missing required file: {rel}')

    json.loads((ROOT/'PROJECT_CONTEXT.json').read_text(encoding='utf-8'))
    ET.parse(ROOT/'sitemap.xml')

    forbidden_claims = [r'No tracking or analytics\.', r'no analytics, no tracking']
    for rel in ['README.md','affiliate-friction-auditor/index.html']:
        text = (ROOT/rel).read_text(encoding='utf-8', errors='ignore')
        for pattern in forbidden_claims:
            if re.search(pattern, text, re.I): fail(f'stale analytics claim in {rel}: {pattern}')

    risky = re.compile(r'(^|/)(\.env($|\.)|.*\.(pem|key|p12|pfx)$)', re.I)
    bad = [p for p in tracked_files() if risky.search(p)]
    if bad: fail('risky tracked files: ' + ', '.join(bad))

    print('PUBLIC_SITE_VERIFY=PASS')
    print('Required context: PASS')
    print('Project context JSON: PASS')
    print('Sitemap XML: PASS')
    print('Privacy/analytics wording: PASS')
    print('Tracked secret-file policy: PASS')
    return 0

if __name__ == '__main__':
    sys.exit(main())
