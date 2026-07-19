# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Study.Manifest input field extraction.

Status:
Completed and pushed in `2cd566e6`.

Selected boundary:
Extract required/optional scalar, number, boolean, string, identifier, map,
list, integer, vector, atom, station-availability, and interval field readers
into `OrbitalDynamics.Study.Manifest.InputField`. Preserve the existing private
field-reader seams in the Manifest facade.

Selection evidence:
- Live re-ranking places `study/manifest.ex` at 4,489 lines.
- The selected 4,193-4,476 helper family is a pure typed field-reader layer
  shared across manifest parsing branches.
- Manifest source routing, domain-specific assembly, run options, planning
  state interpretation, and public load/validation APIs remain in the facade.
- Field-reference normalization and validation-error shaping remain with their
  existing dedicated owners.

Verification:
- Strict warnings-as-errors compile passed across 3,889 files.
- Focused `study/manifest_test.exs` passed: 42 tests.
- Adjacent manifest lint, reference, schema-export, schema-lint, and golden
  artifact bundle passed 41 of 42 tests. The remaining golden-artifact failure
  is a pre-existing deterministic payload-metric mismatch at
  `payload_metrics.sections.campaign_plan.bytes` (checked-in 294,278 versus
  generated 294,280); compiling and using the pre-slice Manifest from
  `6f2faa18` reproduced the identical mismatch.
- Exact public old/new comparison against `6f2faa18` passed all 11 checked-in
  study manifests and 13 invalid-input mutations.
- `mix xref callers OrbitalDynamics.Study.Manifest.InputField` reports only
  the Manifest facade as a runtime caller.
- Static ownership review confirms field-reader implementations live in the
  new owner and the facade retains only delegating private seams.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Study.Manifest input-field extraction, selected in `6f2faa18` and implemented
in `2cd566e6`. `study/manifest.ex` moved from 4,489 to 4,260 lines; the
dedicated owner is 195 lines.

Next candidate:
Re-rank the remaining large modules and select the next cohesive,
facade-preserving responsibility boundary. Prefer a remaining domain-specific
Manifest parsing family only if ownership is clearer than the alternatives.

Blocked:
No.
