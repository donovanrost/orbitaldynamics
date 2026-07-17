# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema suppression callback ownership cleanup.

Status:
Ready for implementation.

Selected slice:
Point two duplicate-group, three source-match, and one cadence source-review
callback captures directly at `Schema.SuppressionHandoffContracts`. Remove the
five pure facade clauses and leave callback-injected duplicate-row evidence
validation unchanged.

Why this slice:
The owner already exposes the exact three-argument APIs, including specialized
and fallback clauses for cadence source-review rows and duplicate-group input.
The facade clauses only forward arguments. Keeping duplicate-row evidence
injection separate avoids widening this slice into domain callback ownership.

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
All six selected captures point directly to `SuppressionHandoffContracts`, the
five pure facade clauses are gone, duplicate-row evidence injection is
unchanged, issue ordering remains exact, validation and schema exports remain
byte-for-byte stable, focused tests pass, and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema timeline publication-summary callback ownership cleanup published as
`5bc62467`: six captures now point directly to `TimelineHandoffContracts`, the
owner internalizes its existing validator dependency, 182 schema/export tests
passed, full export bytes stayed exact, and bounded review was clean.

Next candidate:
After this boundary, audit whether suppression duplicate-row evidence can move
behind an owner-owned default without coupling `SuppressionHandoffContracts` to
unrelated facade state.

Blocked:
No.
