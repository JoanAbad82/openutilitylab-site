# Open Utility Lab

Public home for practical, transparent software utilities built independently.

**Live site:** https://openutilitylab.com/

## Repository role

This repository contains the static Open Utility Lab website and public source for several utility/project surfaces. It also contains historical/project-source material used to document design work. Repository-local canonical guidance is defined in `AGENTS.md` and `PROJECT_CONTEXT.json`.

## Current public utilities

### Affiliate Friction Auditor

Browser-side tool for reviewing affiliate/content pages from pasted HTML or uploaded `.html` / `.htm` files.

**Live:** https://openutilitylab.com/affiliate-friction-auditor/

- analysis input is processed locally in the browser;
- no account is required;
- the supplied HTML is not uploaded to an application backend for analysis;
- the tool does not call an external analysis API;
- aggregate site analytics may be provided by the hosting/analytics platform and are separate from the HTML-analysis workflow;
- outputs can be copied or exported as JSON.

The score is indicative. It is not a revenue prediction, legal/compliance guarantee, or complete analysis of JavaScript-rendered content.

### Master Security Review

Windows first-pass security review utility focused on structured local reports and safer sharing.

**Repository:** https://github.com/JoanAbad82/master-security-review

## Other public project surfaces

- **MTGSynergy:** https://mtgsynergy.com/
- **AI-assisted work:** public notes/examples on AI-assisted workflows.
- **BTC 15m Arena:** bounded experimental/project-source material published as part of the site.
- **SpectralCode / Tension Cores:** project pages retained as separate public surfaces.

## Engineering principles

- transparent output;
- local/client-side processing where practical;
- explicit limitations;
- evidence separated from interpretation;
- public source separated from private inputs/configuration;
- deterministic validation where practical.

## Validation

Run the repository verifier:

```bash
python scripts/verify_public_site.py
```

GitHub Actions runs the same validation on pushes and pull requests.

## Agent / machine-readable context

- `AGENTS.md` — repository operating map and canonical-source guidance.
- `PROJECT_CONTEXT.json` — structured project/surface inventory.
- `sitemap.xml` — public URL inventory.

## Security

See `SECURITY.md`. Do not commit secrets, private client inputs, credentials, or raw sensitive audit material.

## License

Repository source and documentation are licensed under the Apache License 2.0 unless a file or subdirectory explicitly states otherwise.
