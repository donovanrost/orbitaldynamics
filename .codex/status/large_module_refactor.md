# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema source-review callback ownership cleanup.

Status:
Selected; implementation pending.

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

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

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
