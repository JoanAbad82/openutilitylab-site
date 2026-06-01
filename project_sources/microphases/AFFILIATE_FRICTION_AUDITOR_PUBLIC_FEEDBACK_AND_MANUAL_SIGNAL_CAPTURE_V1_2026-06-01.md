# AFFILIATE_FRICTION_AUDITOR_PUBLIC_FEEDBACK_AND_MANUAL_SIGNAL_CAPTURE_V1

Date: 2026-06-01  
Repository: `openutilitylab-site`  
Status: INITIAL_SIGNAL_CAPTURE_PLAN_CREATED  
Type: docs-only manual feedback and signal capture plan

## Objective

Create a clean manual feedback and signal capture plan for Affiliate Friction Auditor after the public trust and report-clarity improvements.

This phase is intentionally documentation-only. It does not add tracking, analytics, forms, backend storage, URL fetching, scraping, automation, or mass outreach.

The goal is to decide what real-world feedback should be collected manually before investing in heavier product infrastructure.

## Baseline

Current baseline before this docs-only artifact:

- branch: `main`
- baseline commit: `104faac`
- previous implementation commit: `92c0b63`
- previous closure:
  `AFFILIATE_FRICTION_AUDITOR_REPORT_OUTPUT_CLARITY_AND_SAMPLE_JOURNEY_V1`
- previous closure document:
  `project_sources/microphases/AFFILIATE_FRICTION_AUDITOR_REPORT_OUTPUT_CLARITY_AND_SAMPLE_JOURNEY_V1_2026-06-01.md`
- public main route:
  `https://openutilitylab.com/affiliate-friction-auditor/`
- public example route:
  `https://openutilitylab.com/affiliate-friction-auditor/affiliate-review-audit-example/`

The previous phase verified:

- public main route HTTP 200;
- public example route HTTP 200;
- `First-Pass Local HTML Report`;
- `inspect priorities`;
- `Manual Review Backlog`;
- `guided reading order`;
- `How to read this sample:`;
- `load the demo HTML, analyze locally, inspect the top priorities`;
- preserved canonical, privacy and guarantee markers;
- local scoring validator remained stable:
  - score: `54`;
  - score band: `High friction`;
  - audited links: `7`.

## Product state

Affiliate Friction Auditor is currently positioned as:

- a local/browser-based HTML inspection tool;
- pasted/uploaded HTML only;
- no account;
- no backend;
- no analytics;
- no tracking;
- no server-side storage;
- no URL fetching;
- indicative first-pass report only.

The product currently helps a user inspect:

- affiliate-looking links;
- opaque tracking links;
- shorteners;
- commercial CTAs;
- unclear destinations;
- internal/non-monetized buying-intent paths;
- visible friction signals in supplied HTML.

## Why this phase exists

The next risk is not technical implementation.

The next risk is evidence quality:

- Do users understand that they must paste or upload HTML?
- Do users understand that no URL fetching exists yet?
- Do users understand the score as indicative, not definitive?
- Is the report useful enough to trigger action?
- Do affiliate/SEO/content users recognize the findings as relevant?
- Which next improvement has real demand:
  - better report output;
  - URL fetching;
  - export improvements;
  - examples/templates;
  - paid review workflow;
  - integration into an agency process?

This phase creates a structured manual capture process before adding product surface or infrastructure.

## Explicit non-changes

This phase does not change:

- runtime HTML;
- CSS;
- JavaScript;
- analyzer logic;
- scoring;
- report JSON shape;
- validator logic;
- sitemap;
- robots;
- canonical metadata;
- deployment configuration;
- dependencies;
- package/build tooling;
- backend behavior;
- URL fetching;
- analytics;
- tracking;
- cookies;
- contact forms;
- scraping;
- automation;
- mass messaging;
- RealityGap;
- Tension Cores;
- MTGSynergy;
- SpectralCode.

## Manual feedback targets

Prefer low-volume, context-rich feedback from people who can judge the tool.

Candidate reviewer types:

1. Affiliate publishers

Useful because they understand monetized content and affiliate link quality.

Questions:

- Would this report help you improve an existing affiliate article?
- Are the findings phrased in a way you can act on?
- Is the score useful or distracting?
- Would you paste HTML manually if the tool stayed private/local?
- What would make this worth using repeatedly?

2. SEO consultants

Useful because they understand content audits, intent alignment and client reporting.

Questions:

- Could this be used as a first-pass audit before manual review?
- Are the report sections clear enough for client work?
- Which section needs stronger evidence?
- Is the local-only HTML workflow acceptable?
- Would URL fetching be required before serious use?

3. Content operators

Useful because they operate review/comparison pages and may not be deeply technical.

Questions:

- Do you understand what to paste?
- Do you understand what to do after the report appears?
- Are the top priorities obvious?
- Is the manual backlog useful?
- What wording confused you?

4. Site buyers / niche-site operators

Useful because they care about monetization quality and hidden friction.

Questions:

- Would this help inspect a site before purchase?
- Are tracking/redirect/shortener findings useful?
- Do you need exportable evidence?
- Would you want multiple-page comparison?
- What would make this more trustworthy?

5. Agencies

Useful because they may need repeatable client-facing outputs.

Questions:

- Is the report format usable internally?
- Would Markdown/JSON export be useful?
- Is the guarantee/privacy wording appropriate?
- What is missing for client delivery?
- Would a paid manual audit be more attractive than self-serve software?

## Safe manual outreach channels

Allowed for this phase:

- one-to-one manual conversations;
- direct messages only when contextually appropriate;
- existing personal/professional contacts;
- small communities where sharing a tool is allowed;
- manual posting in relevant spaces only if rules permit;
- LinkedIn post or comment only if not spammy;
- GitHub/project portfolio references;
- direct review request to a known relevant person.

Not allowed in this phase:

- scraping contact lists;
- mass messaging;
- automated DMs;
- cold email campaigns;
- paid ads;
- tracking pixels;
- analytics installation;
- newsletter import;
- contact form collection;
- form backend;
- URL capture;
- storing user-submitted HTML;
- aggressive promotional posting.

## Suggested short manual ask

Use this when asking one person for feedback:

```text
I built a small browser-only tool for checking affiliate friction in pasted HTML: affiliate links, redirects, shorteners, unclear CTAs and monetization gaps.

It does not fetch URLs or track anything; the idea is a first-pass local report.

Could you look at the public page and tell me:
1. Do you understand what to do first?
2. Is the sample/report useful?
3. What would make it worth using for a real affiliate page?

Main page:
https://openutilitylab.com/affiliate-friction-auditor/

Example:
https://openutilitylab.com/affiliate-friction-auditor/affiliate-review-audit-example/
```

## Manual signal log template

Use this table for each feedback item.

| Date | Source | Reviewer type | Route reviewed | Signal type | Feedback summary | Severity | Actionability | Product implication | Follow-up needed |
|---|---|---|---|---|---|---|---|---|---|
| 2026-06-01 | Manual | TBD | Main / Example | Comprehension / Utility / Trust / Demand | TBD | Low / Medium / High | Low / Medium / High | TBD | Yes / No |

## Signal categories

Use these categories to avoid vague notes.

### Comprehension signal

The user does or does not understand:

- what the tool does;
- what HTML input means;
- why URL fetching is absent;
- what the score means;
- which section to read first.

### Utility signal

The user says whether the report is useful for:

- improving an affiliate page;
- auditing a client page;
- checking redirect/shortener risk;
- finding monetization gaps;
- preparing manual review.

### Trust signal

The user reacts to:

- local-only wording;
- no account/no backend/no tracking;
- guarantee limitations;
- confidence in score/findings;
- whether the tool feels safe to use.

### Demand signal

The user expresses interest in:

- using the tool again;
- testing a real page;
- sharing with someone;
- wanting URL fetching;
- wanting exports;
- wanting paid/manual audit help.

### Objection signal

The user resists because:

- pasting HTML is too technical;
- URL fetching is expected;
- report is too long;
- score is unclear;
- findings feel too obvious;
- they do not trust local-only claims;
- they want direct recommendations, not diagnostics.

## Decision criteria

Do not open a runtime/product phase just because the tool can be improved technically.

Open the next phase only if feedback supports it.

### Consider URL fetching only if

At least 3 relevant reviewers independently say:

- pasting HTML blocks usage;
- they would test real URLs if available;
- they understand the privacy tradeoff;
- the current local-only flow is too technical.

### Consider report/export improvement only if

At least 2 reviewers say:

- the findings are useful;
- the report needs clearer action steps;
- Markdown/JSON export is useful;
- they would share or save the output.

### Consider public copy improvement only if

At least 2 reviewers say:

- they do not understand the first step;
- they do not understand what HTML means;
- they do not understand the sample/demo distinction;
- they are confused by score or guarantee language.

### Consider paid/manual audit positioning only if

At least 2 qualified reviewers say:

- they would rather send a page for review than self-serve;
- they would pay for a concise affiliate-friction review;
- the tool is more credible as a lead-in to a manual service.

## Initial signal log

No external manual feedback has been captured yet in this phase.

Initial status:

- `PUBLIC_FEEDBACK_CAPTURE_NOT_STARTED`
- `NO_RUNTIME_CHANGE`
- `NO_TRACKING_CHANGE`
- `NO_BACKEND_CHANGE`
- `NO_URL_FETCHING_CHANGE`
- `NO_AUTOMATION_CHANGE`

## First manual capture target

Recommended first capture:

- ask 1 affiliate/content/SEO-relevant person to review the main page and example page;
- do not ask for broad promotion;
- ask only for comprehension and usefulness feedback;
- log the result manually in a future docs-only update if useful.

## Final classification

This phase creates the manual feedback framework and initial signal log.

Final marker:

`AFFILIATE_FRICTION_AUDITOR_PUBLIC_FEEDBACK_AND_MANUAL_SIGNAL_CAPTURE_V1_INITIAL_SIGNAL_CAPTURE_PLAN_CREATED`
