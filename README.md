# Open Utility Lab

Practical, transparent software utilities built independently.

Live site: https://openutilitylab.com/

## Tools

### Affiliate Friction Auditor

Affiliate Friction Auditor is a browser-side local MVP for reviewing affiliate and content pages from pasted HTML or uploaded `.html` / `.htm` files.

Live tool: https://openutilitylab.com/affiliate-friction-auditor/

Current local mode:

- Paste HTML directly into the browser.
- Upload an `.html` or `.htm` file.
- Load a built-in sample.
- Analyze locally in the browser.
- Generate an indicative friction score.

Privacy model:

- No backend.
- No account.
- No tracking or analytics.
- No data upload.
- No external APIs.
- No payment.

Detected observable signals:

- Affiliate-looking links.
- CTA signals.
- Weak, opaque tracking and redirect links.
- Shortened commercial links.
- Internal or non-monetized commercial/product links.
- Commercial intent signals.
- Basic metadata and heading structure.
- Possible friction points.

Export options:

- Copy a summary.
- Download a JSON report.

Limitations:

- It does not fetch live URLs yet.
- It may miss JavaScript-rendered content unless included in the supplied HTML.
- The score is indicative and is not a revenue prediction.
- It is not a legal or compliance guarantee.

### Master Security Review

Master Security Review is a lightweight Windows security review utility focused on structured local reports and transparent output.

## Principles

- Practical tools.
- Transparent output.
- Local or client-side processing where possible.
- No unnecessary accounts.
- Clear limitations.

## Status

Affiliate Friction Auditor is an early local MVP. It is intentionally simple and currently analyzes only HTML supplied by the user.

Internal note: LOCAL_HTML_FRICTION_SCORING_CALIBRATION_V1 corrects overly optimistic scoring in local HTML auditing.

## Repository Note

This repository contains the static Open Utility Lab website.
