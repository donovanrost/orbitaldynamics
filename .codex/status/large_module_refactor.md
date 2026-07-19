# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest realized-activity input-schema extraction.

Status:
Completed and pushed in `e6decc5e`.

Selected boundary:
Extract the complete embedded realized-activity input JSON Schema into
`OrbitalDynamics.Study.Manifest.RealizedActivitySchema`. Preserve the existing
public Manifest schema and loader facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,008 lines, ahead of
  ContactAllocation and TimelineFeedback and behind the three larger
  orchestration-heavy facades.
- The selected 175-line builder is one embedded artifact-input contract with
  no runtime parsing or semantic-validation responsibility.
- Its property and embedded-value dependencies now have dedicated owners, so
  the extraction introduces no duplicated schema primitives.
- Public schema/export APIs, operational-feedback composition, and all runtime
  loader behavior remain in the facade.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,902
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent manifest lint/reference/schema-export and schema-lint task coverage
  passed: 30 tests.
- Exact public old/new comparison against selection commit `f3f73799` passed
  for the complete Manifest JSON Schema.
- `mix xref callers` reports only the Manifest facade as a runtime caller of
  the extracted owner.
- Static ownership checks confirm the realized-activity contract lives in the
  dedicated owner while public schema composition remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest realized-activity input-schema extraction, selected in
`f3f73799` and implemented in `e6decc5e`.
`study/manifest.ex` moved from 4,008 to 3,836 lines; the dedicated owner is 181
lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
