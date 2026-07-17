# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema priority-override count callback ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point the contact-allocation priority-override count callback directly at
`Schema.PriorityOverrideContracts.validate_count_matches_ids/5`. Remove the pure
guarded facade delegate.

Why this slice:
The established priority-override owner already exposes the exact guarded `/5`
validator. The facade helper only forwards all five arguments, so the callback
bag can retain its key and position without changing contact-allocation
dispatch or validation behavior.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
The callback points directly to the established priority-override owner, the
guarded facade delegate is gone, argument and callback ordering remain exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 8 focused contact-allocation tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
The priority-override count callback now points directly to
`PriorityOverrideContracts`. The pure guarded facade delegate is gone, the
callback bag and `/5` argument order remain exact, and `schema.ex` decreased
from 8,028 to 8,018 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema priority-field evidence callback ownership cleanup published as
`4df5f3eb`: both callback bags now reuse the established priority-override
owner, duplicate facade clauses were removed, 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, refresh the named production hotspot inventory and compare
the isolated CandidateDiff lineage pipe against a responsibility extraction in
the next-largest facade.

Blocked:
No.
