# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema priority-override count callback ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

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
