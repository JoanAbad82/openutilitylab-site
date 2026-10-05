# Open Utility Lab — Copilot repository instructions

Read `AGENTS.md`, `PROJECT_CONTEXT.json`, `PROJECT_STATUS.json`, and `REFERRAL_ATTRIBUTION.md` before making changes.

Repository role:
- static public site and utility/project surfaces;
- no application backend for the current browser-side utilities;
- privacy claims must distinguish local analysis from hosting/platform analytics.

Change rules:
- preserve static deployment compatibility;
- do not add secrets, client data, raw audit outputs, or private configs;
- do not turn context referral attribution into identity tracking;
- do not add per-agent tokens, cookies, fingerprinting, or application-level IP storage;
- treat `project_sources/` as supporting/historical context unless a current surface explicitly designates it as canonical;
- keep README/AGENTS/PROJECT_CONTEXT/PROJECT_STATUS/llms.txt/agents.json consistent.

Validation:
- run `python scripts/verify_public_site.py`;
- do not merge if repository validation or Cloudflare Pages preview fails.
