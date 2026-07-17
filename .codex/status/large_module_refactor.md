# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy-plan handoff callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point the approval-requirement and plan-delta handoff callback captures directly
at the existing `Schema.PolicyPlanHandoffContracts` owner. Remove the four
redundant private delegates for the general and cadence-source-review validation
paths.

Why this slice:
All four delegates are pure pass-throughs to one already-extracted internal
module, whose public functions also own the matching fallback clauses. The
capture audit found three general and one cadence-specific site for each
artifact family; direct captures consolidate their ownership without moving
unrelated policy or schema orchestration.

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
Every callback list directly captures the corresponding public
`PolicyPlanHandoffContracts` validator, the four facade delegates are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema optimization-handoff callback ownership cleanup published as `5013b9d7`:
all constraint, objective-satisfaction, score-term, and objective-tradeoff
callback captures now point directly to their existing contract owner; 182
schema/export tests passed, full export bytes stayed exact, and bounded review
was clean.

Next candidate:
Audit the adjacent policy-plan handoff callback family. Approval-requirement and
plan-delta general/cadence validators appear to have the same pure-delegate
shape and an existing `PolicyPlanHandoffContracts` owner; select only after
confirming all capture counts, exact targets, and fallback clauses.

Blocked:
No.
