# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest reusable value-schema ownership extraction.

Status:
Completed and pushed in `e796c533`.

Selected boundary:
Extract reusable target, ground-station, and spacecraft identity schemas plus
the three-number vector schema into
`OrbitalDynamics.Study.Manifest.ValueSchema`. Preserve the existing public
Manifest schema and loader facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,039 lines, ahead of
  ContactAllocation and TimelineFeedback and behind the three larger
  orchestration-heavy facades.
- The selected builders form one reusable embedded-value schema vocabulary
  with no runtime parsing or semantic-validation responsibility.
- Public schema/export APIs and entity schemas remain in the facade.
- This removes the last facade-private builder dependencies from the remaining
  realized-activity input-schema boundary.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,901
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent manifest lint/reference/schema-export and schema-lint task coverage
  passed: 30 tests.
- Exact public old/new comparison against selection commit `b8f1453e` passed
  for the complete Manifest JSON Schema.
- `mix xref callers` reports only the Manifest facade as an export-time caller
  of the extracted owner.
- Static ownership checks confirm the selected identity and vector builders
  live in ValueSchema while entity schemas remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest reusable value-schema ownership extraction, selected in
`b8f1453e` and implemented in `e796c533`.
`study/manifest.ex` moved from 4,039 to 4,008 lines; the dedicated owner is 37
lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
