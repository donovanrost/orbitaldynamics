# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema source-review callback ownership cleanup.

Status:
Completed and verified; publishing.

Selected slice:
Point the refresh-budget source callback plus cadence warning,
timeline-protection, policy-escalation, freshness, refresh-budget,
schema-validation, execution, quality-gate, and operational-readiness callbacks
directly at `Schema.SourceReviewHandoffContracts`. Remove the ten facade
delegates across twelve callback positions.

Why this slice:
The refresh-budget source callback appears in three bags; each cadence callback
appears once. All ten facade functions are pure one-hop delegates, while the
owner already retains the specialized source-row dispatch, permissive
fallbacks, field lists, and issue ordering.

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
All twelve selected captures point directly to
`SourceReviewHandoffContracts`, the ten facade delegates are gone, and callback
plus field traversal issue ordering remains exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Outcome:
The refresh-budget source callback and all nine selected cadence source-review
callbacks now capture `SourceReviewHandoffContracts` directly. Ten pure facade
delegates were removed across twelve positions, reducing `schema.ex` from
8,547 to 8,427 lines without changing source-key dispatch, relative callback
order, field traversal, fallbacks, or checked-in schema bytes.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 98 focused source-review-referencing schema contract tests
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
Schema contact-review source callback ownership cleanup published as
`19c47be6`: eight provider-counteroffer and contact-intent general/cadence
captures now point directly to their owner; 182 schema/export tests passed,
full export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the `SourceReviewHandoffContracts` callback family. One refresh-budget
source delegate plus cadence warning, timeline-protection, policy-escalation,
freshness, refresh-budget, schema-validation, execution, quality-gate, and
operational-readiness delegates appear to be pure one-hop calls; confirm capture
counts and owner fallbacks before selecting a cohesive subset.

Blocked:
No.
