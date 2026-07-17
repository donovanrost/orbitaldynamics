# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema readiness/quality-gate source callback ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point operational-readiness gate/report and quality-gate row/report
source-match callbacks directly at their existing dedicated owners. Remove the
four facade delegates across fourteen callback positions.

Why this slice:
All fourteen callback positions forward unchanged through four pure delegates.
`OperationalReadinessHandoffContracts` and `QualityGateHandoffContracts`
already own the specialized and fallback clauses, field-pair order, and report
identity/summary distinction, so direct captures require no callback bag.

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
All fourteen selected captures point directly to their readiness/quality-gate
owners, the four facade delegates are gone, and callback plus field-pair issue
ordering remains exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
All operational-readiness gate/report and quality-gate row/report source
callbacks now capture their dedicated owners directly. Four facade delegates
were removed across fourteen positions, reducing `schema.ex` from 8,657 to
8,609 lines without changing readiness report identity/summary selection,
field-pair issue order, fallbacks, or checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 38 focused readiness/quality-gate schema contract tests
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
Schema contact-allocation source-match callback ownership cleanup published as
`c6930074`: twelve allocation, capacity-pack, and provider-contention captures
now point directly to their owner while duplicate-evidence injection remains
facade-owned; 182 schema/export tests passed, full export bytes stayed exact,
and bounded review was clean.

Next candidate:
Leave contact-allocation field validation in the facade because moving it would
drag the report-domain callback bag across the boundary. Audit the adjacent
operational-readiness and quality-gate source-match wrappers instead: four pure
delegates appear across fourteen callback positions and already have dedicated
owners.

Blocked:
No.
