# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optimization-handoff callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point the constraint, objective-satisfaction, score-term, and
objective-tradeoff handoff callback captures directly at the existing
`Schema.OptimizationHandoffContracts` owner. Remove the eight redundant private
delegates for the general and cadence-source-review validation paths.

Why this slice:
All eight delegates are pure pass-throughs to one already-extracted internal
module, whose public functions also own the matching fallback clauses. Direct
captures consolidate callback ownership without creating another callback bag
or moving unrelated schema/provider orchestration.

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
`OptimizationHandoffContracts` validator, the eight facade delegates are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Campaign-planner branch event/state application published as `42abcf65`: plan
and realized event pipelines, capacity/station matching, degradation, and state
merge helpers now live in one cohesive internal module, 64 focused/regression
tests passed, and bounded review found no finding.

Next candidate:
Pivot to `schema.ex` and audit the cadence-import row JSON-provider and
contract-callback clusters. Select only a boundary whose provider/validator
dependencies can move with it; do not extract the remaining large
CampaignPlanner orchestration functions through broad callback bags.

Blocked:
No.
