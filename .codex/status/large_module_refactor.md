# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema optimization-handoff callback ownership cleanup.

Status:
Completed and published.

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

Outcome:
All general and cadence-source-review optimization handoff callback lists now
capture the existing `OptimizationHandoffContracts` validators directly. Eight
private one-hop delegates were removed, reducing `schema.ex` from 9,321 to
9,231 lines without changing callback keys, order, fallback behavior, validation
results, or checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 11 focused cadence-import, readiness, and review-import handoff tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Behavior/schema changes:
None.

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
