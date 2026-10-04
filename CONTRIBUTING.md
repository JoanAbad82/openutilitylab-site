# Contributing

## Principles

- Keep changes small and reviewable.
- Preserve the static/client-side architecture unless a change explicitly requires otherwise.
- Keep public claims aligned with actual behavior.
- Do not commit secrets, client data, private configurations, raw sensitive outputs, or credentials.
- Treat `project_sources/` as supporting/historical material unless a current surface explicitly designates a document as canonical.

## Before committing

Run:

```bash
python scripts/verify_public_site.py
```

GitHub Actions executes the same check on Linux and Windows.
