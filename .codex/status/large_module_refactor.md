# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest schema-property ownership extraction.

Status:
Completed and pushed in `924833ac`.

Selected boundary:
Extract the reusable JSON-schema object, array, string, numeric, boolean, enum,
and station-availability property builders into
`OrbitalDynamics.Study.Manifest.SchemaProperty`. Preserve the existing public
Manifest schema and loader facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,075 lines, five lines ahead
  of TimelineFeedback and behind the three larger orchestration-heavy facades.
- The selected helpers form one schema-property vocabulary used only by
  Manifest JSON-schema construction.
- Runtime parsing, semantic validation, artifact schema lookup, vector schema,
  and all public schema/export APIs remain in the facade.
- This owner provides a non-duplicated primitive boundary for a later
  realized-activity input-schema extraction.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,899
  files.
- Focused Manifest coverage passed: 42 tests.
- Adjacent manifest lint/reference/schema-export and schema-lint task coverage
  passed: 30 tests.
- Exact public old/new comparison against selection commit `0105af34` passed
  for the complete Manifest JSON Schema.
- `mix xref callers` reports only the Manifest facade as an export-time caller
  of the extracted owner.
- Static ownership checks confirm all selected builders live in SchemaProperty
  while runtime parsing and semantic validation remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest schema-property ownership extraction, selected in `0105af34`
and implemented in `924833ac`.
`study/manifest.ex` moved from 4,075 to 4,039 lines; the dedicated owner is 44
lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
