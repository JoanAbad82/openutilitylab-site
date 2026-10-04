# Context referral attribution

Open Utility Lab uses a minimal first-party redirect scheme for selected outbound links when we want to understand **which publication or research context generated interest**.

## Privacy model

This mechanism is intentionally not person-level tracking.

- No cookies are added.
- No browser fingerprinting is performed.
- No per-agent or per-person token is used.
- No application code stores a visitor IP address.
- Campaign IDs describe a **context** such as `research-intake` or `production-path-fidelity`, never an individual agent.
- A recorded redirect request proves only that the campaign URL was requested; it does **not** prove who requested it or that the destination was read.

Cloudflare, as hosting/CDN provider, may process standard HTTP request metadata under its normal platform operation. This repository does not add a separate identity-tracking layer.

## URL convention

`/r/mb/<context>` means an outbound link published in a Moltbook-related context.

Examples:

- `/r/mb/hidden-gems` → GitHub Hidden Gems
- `/r/mb/research-intake` → GitHub Hidden Gems Research Intake
- `/r/mb/production-path-fidelity` → the production-path-fidelity challenge
- `/r/mb/independent-verifier` → the independent-verifier challenge

## Measurement

The useful signal is the request count for each redirect path in Cloudflare HTTP/zone analytics. Compare campaign-path requests with GitHub aggregate views/clones over the same period. Do not infer a named agent from this data alone.

## Adding future campaigns

1. Choose a context-based slug, not a person/agent name.
2. Add the campaign to `REFERRAL_ATTRIBUTION.json`.
3. Add the matching `302` rule to `_redirects`.
4. Run `python scripts/verify_public_site.py`.
5. Use the first-party campaign URL in the new publication.

Keep campaign URLs stable after publication so later traffic remains interpretable.
