# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-timeline validation extraction.

Status:
Completed and published.

Selected boundary:
Extract optional operational-timeline report validation and timeline-row
orchestration into `OrbitalDynamics.Schema.OperationalTimelineValidation`.
Preserve the existing arity-2 and arity-3 private Schema callback seams.

Selection evidence:
- `schema.ex` is 6,878 lines; the selected operational-timeline seams span
  6,062-6,074 and 6,084-6,095.
- The cluster has one responsibility: validate nested operational-timeline
  reports and their rows.
- Registry dispatch remains facade-owned, while timeline-context and integrity
  validators can be supplied as callbacks to the new owner.
- Registry data, JSON Schema export, contract dispatch, unrelated validation,
  and all public `Schema` APIs remain outside.

Verification:
- Strict compile passed across 3,869 files with warnings as errors.
- Focused operational-timeline and timeline-summary contracts passed: 19 tests.
- Full Schema suite passed: 175 tests.
- JSON Schema export contracts passed: 15 tests.
- Exact old/new validation reports matched for 8 valid and mutated standalone
  row and nested campaign fixtures.
- Static inspection confirms the facade retains only its arity-2/arity-3 seams
  plus registry and timeline-context callback inputs; runtime xref reports
  `Schema` as the sole caller of the new owner.
- `git diff --check` and bounded ownership review passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
Schema operational-timeline validation extraction, selected in `477cf707` and
implemented in `0c32a016`. `schema.ex` moved from 6,878 to 6,872 lines; the
dedicated owner is 25 lines.

Next candidate:
Re-inventory remaining Schema family-validation clusters after
operational-timeline validation has one production owner.

Blocked:
No.
