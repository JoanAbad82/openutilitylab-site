# BTC 15m Arena — Validation Helpers Contract V1

Microphase: BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_DOCS_ONLY_V1
Mode: docs-only contract. No runtime implementation.

## 1. Title and purpose

This document defines the future common validation-helper contract for BTC 15m Arena.

The goal is to preserve a senior validation standard without creating fragile over-validation. The validator layer must help distinguish real product, safety, data, and scope problems from validator implementation defects.

This contract does not implement helpers. It defines the expected behavior, output shape, blocking policy, and future validation boundaries for reusable helpers.

The future helper system must support:

- predictable result objects;
- normalized arrays and counts;
- robust snippets;
- contextual guardrail classification;
- precise git scope checks;
- safe handling of warnings;
- clear separation between product failure and validator failure.

This phase does not authorize LiveData, collector, bot, wallet, authenticated API, orders, trading automation, runtime changes, calculator changes, fixture promotion, or external market-data calls.

## 2. Problems detected

Previous BTC 15m Arena phases exposed recurrent validation failures that were caused by validator fragility rather than product defects.

Detected problems:

- PowerShell converts single-element arrays into scalars unless results are forced with `@(...)`.
- `.Count` on `PSCustomObject` or null values can give incorrect or misleading results.
- Snippet helpers can return string, array, object, or null inconsistently.
- Helpers lacked uniform output contracts.
- Literal text validators confused negative guardrails with positive claims.
- Overly rigid documentation anchors caused `NO_PASS` even when the artifact was correct.
- `git diff --name-status` and staged/unstaged status can be parsed incorrectly.
- `Set-Content` can rewrite line endings and contaminate diffs.
- `FinalUrl` or `ResponseUri` can be a warning, not a blocking failure, when HTTP 200 and expected content validate.
- Obsolete expected HEAD values can block phases that should instead move through post-commit review.
- The validator must not be more fragile than the artifact being validated.

Concrete historical examples to avoid repeating:

- A literal `web3` token in a prohibited-pattern list was misclassified as runtime.
- Absent forbidden tokens were treated as `$null` issues instead of zero-hit pass conditions.
- Cached content checks failed on a Unicode title dash even though worktree bytes and ASCII anchors validated.
- `let` was misdetected inside natural-language words such as `wallet`.
- Negative guardrails such as `No real orders` or `No trading automation` were treated as possible positive capabilities.

## 3. Validation levels

Every validation result must be classified into one of three operational levels plus informational output.

### A) FAIL

A `FAIL` must block the phase when there is real risk involving state, scope, safety, data, or artifact integrity.

Blocking examples:

- working tree unexpectedly dirty;
- HEAD/origin incoherent when the phase requires sync;
- files outside authorized scope modified;
- critical artifact missing;
- diff contaminated by unauthorized massive rewrite or line-ending conversion;
- wallet, authenticated API, orders, or trading automation appearing as positive capability;
- real data captured without an authorized phase;
- wrong token, wrong market, wrong slug, or wrong 15m window in future LiveData;
- invalid JSON in future snapshots;
- fixture or script broken when the phase touches them;
- runtime/API/order logic introduced without authorization.

### B) WARN

A `WARN` must be documented but should not block if the critical artifact and guardrails validate through stronger evidence.

Warning examples:

- `FinalUrl` empty while HTTP status is 200 and expected content validates;
- secondary documentation anchor missing while the main artifact hash or primary anchors validate;
- equivalent phrase present but not literal;
- snippet incomplete when alternative evidence is sufficient;
- non-conclusive validator warning;
- minor wording difference without guardrail impact.

### C) INFO

`INFO` is informational only and must never block.

Info examples:

- refactor recommendation;
- readability improvement;
- opportunity to consolidate helpers;
- duplication-reduction note;
- future cleanup suggestion.

## 4. Common result contract

Every helper must return a normalized object or a normalized array of objects. No helper may return ambiguous scalar/string/null results when the caller expects structured validation output.

Minimum fields for each validation result:

- `name`
- `level`
- `status`: `PASS`, `FAIL`, `WARN`, or `INFO`
- `message`
- `evidence`
- `file`
- `expected`
- `actual`
- `classification`
- `blocking`: `true` or `false`

Rules:

- `FAIL` with `blocking=true` stops the phase.
- `WARN` must use `blocking=false` unless explicitly promoted by phase policy.
- `INFO` must always use `blocking=false`.
- Empty result sets must be represented as an empty array, not `$null`.
- Single result sets must still be represented as arrays when the caller expects a collection.
- Validator exceptions must be converted into `VALIDATOR_ERROR` results rather than silently converted into product failures.

Example conceptual shape:

```text
name: Test-ExactChangedScope
level: FAIL
status: FAIL
message: unexpected file changed
file: btc-15m-arena/index.html
expected: only project_sources/btc-15m-arena/BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_V1.md
actual: btc-15m-arena/index.html
classification: OUT_OF_SCOPE_CHANGE
blocking: true
```

## 5. Mandatory future helpers

The following helpers should be defined conceptually before implementation. This document does not implement them.

### Normalize-Array

Purpose:
Normalize any PowerShell output into a predictable array.

Expected input:
Any value that can be `$null`, scalar, array, collection, pipeline result, `PSCustomObject`, or string.

Expected output:
A real array suitable for indexing and `.Count`.

Errors avoided:
- scalar collapse for one result;
- `$null` treated as one object;
- misleading `.Count` behavior.

Blocking behavior:
Does not block by itself. It supports other checks.

WARN behavior:
Can emit WARN if a helper returns an unsupported type that was normalized defensively.

### Get-SafeCount

Purpose:
Return reliable counts for normalized collections.

Expected input:
Normalized array or unknown value.

Expected output:
Integer count.

Errors avoided:
- `.Count` on scalar object;
- `.Count` on `$null`;
- `.Count` on string interpreted incorrectly.

Blocking behavior:
Does not block by itself.

WARN behavior:
Can warn when input had to be normalized from an unexpected type.

### New-ValidationResult

Purpose:
Create a standard validation result object.

Expected input:
Name, level, status, message, evidence, file, expected, actual, classification, blocking.

Expected output:
One normalized validation result object.

Errors avoided:
- inconsistent field names;
- missing `blocking` flag;
- string-only helper outputs.

Blocking behavior:
The returned object may be blocking according to level/status.

WARN behavior:
WARN results must explicitly set `blocking=false`.

### New-SnippetObject

Purpose:
Return a normalized snippet object with token, index, snippet text, and context metadata.

Expected input:
Text, token, index, radius, file.

Expected output:
Object with stable fields such as `token`, `index`, `snippet`, `file`, `classification`.

Errors avoided:
- returning raw strings;
- returning inconsistent arrays;
- null snippets for absent tokens.

Blocking behavior:
Only blocks if the snippet reveals positive prohibited capability or unresolved ambiguity.

WARN behavior:
Can warn if snippet radius is truncated but alternative evidence exists.

### Get-ContextSnippet

Purpose:
Extract safe surrounding context for a token hit.

Expected input:
Text, token or index, radius.

Expected output:
Normalized snippet object or empty array if no hit exists.

Errors avoided:
- null result for zero hits;
- invalid `.snippet` property access;
- malformed context.

Blocking behavior:
No block for zero hits. Block only if classification finds a real issue.

WARN behavior:
Warn if snippet extraction fails but hit count and alternative evidence remain available.

### Test-GitClean

Purpose:
Validate clean working tree at phase start or end when required.

Expected input:
Expected clean state and optional allowed dirty scope.

Expected output:
Validation result array.

Errors avoided:
- overlooking untracked files;
- confusing staged and unstaged files.

Blocking behavior:
Blocks when unexpected dirty state exists.

WARN behavior:
Can warn only if dirty state is explicitly allowed and fully classified.

### Test-ExpectedBranch

Purpose:
Validate current branch.

Expected input:
Expected branch name.

Expected output:
Validation result.

Errors avoided:
- running a phase on the wrong branch.

Blocking behavior:
Blocks on wrong branch.

WARN behavior:
No WARN expected for branch mismatch.

### Test-HeadOriginSync

Purpose:
Validate local HEAD and origin/main relationship.

Expected input:
Expected HEAD policy: exact, synced, or informational.

Expected output:
Validation result array.

Errors avoided:
- stale local branch;
- accidental commit on top of unexpected baseline;
- obsolete expected HEAD blocks not classified properly.

Blocking behavior:
Blocks when exact sync is required and absent.

WARN behavior:
Warns when HEAD mismatch may be a post-commit review case rather than product failure.

### Test-ExactChangedScope

Purpose:
Validate unstaged/tracked and untracked changes match allowed scope.

Expected input:
Allowed paths and current git status.

Expected output:
Validation result array.

Errors avoided:
- parsing `git status` incorrectly;
- missing untracked new files;
- accepting extra files.

Blocking behavior:
Blocks on any out-of-scope change.

WARN behavior:
No WARN for unauthorized dirty scope unless phase explicitly permits review-only classification.

### Test-ExactStagedScope

Purpose:
Validate staged files exactly match allowed scope.

Expected input:
Allowed staged paths and cached diff list.

Expected output:
Validation result array.

Errors avoided:
- accidental broad `git add`;
- committing unintended files.

Blocking behavior:
Blocks on staged extra/missing files.

WARN behavior:
No WARN for wrong staged scope.

### Test-NoForbiddenFilesTouched

Purpose:
Confirm forbidden paths remain untouched.

Expected input:
Forbidden path list and git status/diff.

Expected output:
Validation result array.

Errors avoided:
- touching route/home/sitemap/runtime/scripts/package files in docs-only phases.

Blocking behavior:
Blocks if any forbidden path is touched.

WARN behavior:
Can warn only for matches in documentation strings, not actual changed paths.

### Test-NoLineEndingContamination

Purpose:
Detect massive line-ending rewrites and visible CR markers.

Expected input:
Diff text, stat, numstat, target file type.

Expected output:
Validation result array.

Errors avoided:
- Set-Content rewriting HTML/XML line endings;
- dirty large diffs that hide small intended edits.

Blocking behavior:
Blocks unauthorized massive rewrites or visible `^M` contamination.

WARN behavior:
Warns only when line-ending differences are expected and explicitly authorized.

### Test-NegatedGuardrail

Purpose:
Classify sensitive terms that appear in negated guardrail contexts.

Expected input:
Text, token list, snippets.

Expected output:
Validation result array with `NEGATED_GUARDRAIL` classification.

Errors avoided:
- false failures for `No wallet`, `No orders`, `No real orders`, and similar guardrails.

Blocking behavior:
Does not block when negation is explicit.

WARN behavior:
Warns if wording is safe but could be clearer.

### Test-ForbiddenPositiveClaim

Purpose:
Detect sensitive terms used as positive capability, CTA, or promise.

Expected input:
Text and prohibited positive phrase list.

Expected output:
Validation result array.

Errors avoided:
- allowing real trading capability language;
- accepting wallet/order CTAs.

Blocking behavior:
Blocks on positive capability, CTA, or promise.

WARN behavior:
Can warn if context is incomplete but appears non-operational.

### Test-JsonParseable

Purpose:
Validate JSON artifacts and future snapshots.

Expected input:
JSON text or file path.

Expected output:
Validation result array.

Errors avoided:
- invalid snapshot artifacts;
- silently broken fixture or capture files.

Blocking behavior:
Blocks if JSON must be valid and parsing fails.

WARN behavior:
Warns only when JSON is optional or out of scope.

### Test-RequiredAnchors

Purpose:
Validate primary and secondary anchors with severity levels.

Expected input:
Required anchor list with level metadata.

Expected output:
Validation result array.

Errors avoided:
- treating every anchor as equally blocking;
- over-blocking due to harmless wording changes.

Blocking behavior:
Blocks missing primary anchors.

WARN behavior:
Warns missing secondary anchors when equivalent evidence exists.

### Test-AllowedWarningsOnly

Purpose:
Confirm all warnings are permitted by phase policy.

Expected input:
Validation result array and allowed warning classifications.

Expected output:
Validation result array.

Errors avoided:
- burying real risk under warnings;
- failing phases due only to classified non-blocking warnings.

Blocking behavior:
Blocks if an unapproved warning classification appears.

WARN behavior:
Emits consolidated warning summary.

## 6. PowerShell-specific rules

Future validation scripts for BTC 15m Arena must follow these rules:

- Force arrays with `@(...)` whenever a result can have 0, 1, or N elements.
- Do not use `.Count` directly on non-normalized objects.
- Do not assume pipeline output always returns an array.
- Do not return strings when the caller expects a result object.
- Do not use `$HOME`, `$Host`, `$PID`, `$Error`, `$Matches`, `$Input`, `$Args`, or other reserved/predefined names as work variables.
- Do not use `Set-Content` for HTML/XML when it can modify EOL unexpectedly.
- Prefer `[System.IO.File]::WriteAllText()` with explicit encoding and detected EOL when writing is authorized.
- Separate product errors from validator errors.
- If the validator fails by exception, classify as `VALIDATOR_ERROR`; do not automatically label the product artifact as failed.
- Normalize snippets before property access.
- Never treat zero hits for forbidden tokens as `$null` failure.
- Avoid Unicode-only anchors as the sole cached-content validation mechanism.
- Use ASCII-safe primary anchors for cached validation when shell encoding is uncertain.
- Validate git status, untracked files, staged files, and unstaged diffs separately.

## 7. Contextual guardrails

These texts are valid when they appear as explicit negative guardrails:

- No wallet
- No orders
- No real orders
- No authenticated trading API
- No trading automation
- No live trading
- No financial advice

These texts must block when they appear as affirmative capability, CTA, promise, or available feature:

- connect wallet
- place order
- execute order
- authenticated trading API available
- real orders enabled
- trading automation supported
- live trading mode
- guaranteed profit
- guaranteed prediction
- sure-win strategy

Classification policy:

- `No wallet` -> `NEGATED_GUARDRAIL`, non-blocking.
- `Connect wallet` -> `CTA_OR_INSTRUCTION`, blocking.
- `No real orders` -> `NEGATED_GUARDRAIL`, non-blocking.
- `Real orders enabled` -> `POSITIVE_CAPABILITY`, blocking.
- `No trading automation` -> `NEGATED_GUARDRAIL`, non-blocking.
- `Trading automation supported` -> `POSITIVE_CAPABILITY`, blocking.

## 8. Future application to Polymarket LiveData

Before opening any future LiveData work, the validation helper system must be able to robustly validate:

- fresh `token_id`;
- correct slug and market;
- correct 15-minute window;
- coherent `active` and `closed` state;
- CLOB `/book` parseability;
- capture timestamp;
- no implicit fixture promotion;
- no real order;
- no authenticated API;
- no wallet;
- valid snapshot JSON;
- exact write scope;
- separation between single capture, repeatable capture, collector, and fixture promotion.

This document does not implement LiveData.

This document only prepares the validation contract required before later phases can safely handle Polymarket-oriented read-only data validation.

Future LiveData validation must distinguish:

- capture target discovery;
- single snapshot capture;
- repeatable capture;
- collector runtime;
- fixture promotion;
- fixture consumption;
- paper-only calculation;
- real execution, which remains out of scope unless explicitly authorized in a separate future policy.

## 9. Blocking policy

A validator should block only when it detects real risk in one of these categories:

- git state;
- exact scope;
- safety/guardrails;
- incorrect data;
- invalid artifact;
- unauthorized modification;
- disallowed real execution capability.

A validator should not block solely because of:

- equivalent wording;
- non-critical snippets;
- secondary documentation anchors;
- classified technical warnings;
- internal validator defects without evidence of product failure.

Validator failure policy:

- If the validator cannot classify a condition, emit `AMBIGUOUS_REQUIRES_REVIEW`.
- If the validator throws or returns malformed data, emit `VALIDATOR_ERROR`.
- If stronger evidence proves the artifact is valid, downgrade fragile validator findings to WARN or INFO according to phase policy.
- Do not edit a valid artifact merely to satisfy a brittle validator unless wording clarity itself is valuable.

## 10. PASS criteria for this microphase

This docs-only microphase passes if:

- exactly one new file is created:
  `project_sources/btc-15m-arena/BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_V1.md`
- no other file is modified;
- the document contains all required sections;
- no stage is performed;
- no commit is performed;
- no push is performed;
- final working tree is dirty only because of this new file;
- guardrails for no wallet, no orders, no trading automation, no live trading, and no authenticated API are explicit;
- next recommended phase is:
  `BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_DOCS_ONLY_REVIEW_V1`.

## Explicit non-authorization

This contract does not authorize:

- LiveData implementation;
- collector implementation;
- bot implementation;
- wallet connection;
- authenticated API use;
- order creation;
- order placement;
- order execution;
- trading automation;
- market data HTTP requests;
- Gamma requests;
- CLOB requests;
- Polymarket live integration;
- runtime changes;
- calculator changes;
- fixture promotion;
- fixture modification.


## Anchor compatibility notes

This section intentionally includes literal compatibility anchors for legacy validators.

These anchors do not add runtime capability, helper implementation, LiveData, collector, bot, wallet/API/order logic, or trading automation.

Literal compatibility anchors:

- .Count on PSCustomObject or null values
- Set-Content can rewrite line endings
- FinalUrl or ResponseUri can be a warning

Anchor classification policy:

- PRIMARY_BLOCKING_ANCHOR: missing critical product/safety/scope evidence.
- SECONDARY_WARN_ANCHOR: useful wording check that must not block if equivalent evidence exists.
- EQUIVALENT_TEXT_ACCEPTED: concept present with Markdown inline-code, Unicode, whitespace, or equivalent wording.
- FORMAT_COMPATIBILITY_NOTE: text added only to keep older literal validators aligned.

Repair classification:

- The V1 NO_PASS was caused by literal anchor mismatch after Markdown inline-code formatting.
- The document already contained the corresponding concepts with backticks or equivalent wording.
- This repair aligns literal anchors without changing runtime, calculator, route, script, fixtures, LiveData, collector, bot, wallet/API/order logic, orders, or trading automation.

## Next recommended phase

`BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_DOCS_ONLY_REVIEW_V1`

Purpose:
Review the contract locally, validate scope and content, and decide whether to commit/push the docs-only contract in a separate controlled phase.