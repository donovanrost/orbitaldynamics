# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest activity-schema extraction.

Status:
Completed and pushed in `90b9d08e`.

Selected boundary:
Extract the activity input JSON Schema assembly, including activity-specific
identity fragments and contact-direction schema metadata, into
`OrbitalDynamics.Study.Manifest.ActivitySchema`. Preserve the private
`activity_schema/0` seam in the Manifest facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,260 lines, just behind the
  remaining TimelineFeedback facade.
- The selected 513-699 function is a self-contained activity contract assembly
  whose activity types, statuses, approvals, directions, and provider aliases
  derive from `MissionPlan.Activity.capabilities/0`.
- Manifest loading, typed field reading, activity construction, all other
  schema families, and public JSON Schema APIs remain in the facade.
- Existing public manifest schema output and loader behavior remain unchanged.

Verification:
- Strict warnings-as-errors compile passed across 3,893 files.
- Focused `study/manifest_test.exs` passed under warnings-as-errors: 42 tests.
- Adjacent manifest lint, reference, schema-export, and schema-lint coverage
  passed under warnings-as-errors: 30 tests.
- Exact public old/new comparison against `73142212` passed for the complete
  Manifest JSON Schema, including all 178 activity properties.
- `mix xref callers OrbitalDynamics.Study.Manifest.ActivitySchema` reports
  only the Manifest facade as a runtime caller.
- Static ownership review confirms the activity contract assembly and its
  activity-local identity, capability-enum, direction-alias, vector, frame,
  and primitive schema fragments live in the new owner.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest activity-schema extraction, selected in `73142212` and
implemented in `90b9d08e`. `study/manifest.ex` moved from 4,260 to 4,075
lines; the dedicated owner is 283 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary.

Blocked:
No.
