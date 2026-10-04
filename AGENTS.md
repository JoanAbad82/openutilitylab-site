# AGENTS.md

## Purpose

Open Utility Lab is a static public website containing multiple utility/project surfaces plus supporting project-source documentation.

## Canonical sources

1. `README.md` — repository role and current public positioning.
2. `PROJECT_CONTEXT.json` — machine-readable inventory of public surfaces.
3. Current HTML/CSS/JS files for behavior of each live surface.
4. `sitemap.xml` for public URL inventory.

## Historical / project-source material

`project_sources/` may contain detailed contracts, experiments, microphases, or historical design material. Treat it as supporting evidence, not as the authoritative description of the current homepage or every live product surface.

## Validation

Run `python scripts/verify_public_site.py`. A change is not complete if this validation fails.

## Privacy boundary

For Affiliate Friction Auditor, distinguish application behavior from site-level analytics: user-supplied HTML is analyzed locally and is not uploaded to an application backend. Aggregate site analytics, when enabled at the hosting/platform layer, are separate from analysis input.

Context referral attribution is intentionally non-personal. `REFERRAL_ATTRIBUTION.json` and `_redirects` may distinguish publication/context paths, but must not introduce per-agent tokens, cookies, fingerprinting, or application-level IP storage. A redirect request is evidence that a campaign URL was requested, not proof of the requester's identity or of downstream reading.

## Editing rules

- Do not introduce claims of guaranteed revenue, security, compliance, or correctness.
- Do not add secrets, client data, private configs, raw audit outputs, or credentials.
- Keep live URLs and repository descriptions synchronized.
- Prefer explicit status/limitations over promotional language.
- Do not treat historical project-source documents as current product contracts unless the current surface references them.
