# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema strategy handoff callback ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point the strategy-recommendation, strategy-tradeoff, branch-comparison,
ranking-comparison, and Pareto-frontier handoff callback captures directly at
the existing `Schema.StrategyHandoffContracts` owner. Remove the nine redundant
private delegates across the general and cadence-source-review validation paths.

Why this slice:
All nine delegates are pure pass-throughs to one already-extracted internal
module. The four paired families each have three general capture sites and one
cadence-specific site; branch comparison has one general site. Direct captures
consolidate all 17 callback positions without moving strategy validation logic
or unrelated schema orchestration.

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
`StrategyHandoffContracts` validator, the nine facade delegates are gone,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
All strategy recommendation/tradeoff, branch-comparison, ranking-comparison,
and Pareto-frontier callback lists now capture the existing
`StrategyHandoffContracts` validators directly. Nine private one-hop delegates
were removed, reducing `schema.ex` from 9,090 to 8,990 lines without changing
callback keys, order, fallback behavior, validation results, or checked-in
schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 41 focused strategy-referencing schema contract tests
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
Schema risk-feedback handoff callback ownership cleanup published as `ce35687f`:
all risk-explanation and realized-feedback callback captures now point directly
to their existing contract owner; 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the strategy handoff callback family as one possible next boundary:
strategy recommendation/tradeoff, branch comparison, ranking comparison, and
Pareto-frontier validators already share `StrategyHandoffContracts`. Select
only if every delegate is pure, all targets retain fallbacks, and the family is
still small enough for one independently reviewable slice.

Blocked:
No.
