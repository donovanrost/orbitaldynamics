# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema suppression callback ownership cleanup.

Status:
Completed and verified; publishing.

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
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 104 focused cadence/import and operator-review suppression tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All six suppression captures now point directly to
`SuppressionHandoffContracts`. Five pure facade clauses were removed,
duplicate-row evidence injection remains unchanged, and `schema.ex` decreased
from 8,278 to 8,242 lines.

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
