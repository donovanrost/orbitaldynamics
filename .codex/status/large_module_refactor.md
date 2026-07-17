# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline publication-summary callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Give `Schema.TimelineHandoffContracts` an owner-owned three-argument publication
matching entry point that uses its existing summary validator. Point the three
optional-summary and three publication-matching callback captures directly at
the owner, then remove the two pure `Schema` facade wrappers.

Why this slice:
The owner already implements the complete optional-summary validator and
publication matching pipeline. Its four-argument entry point only receives that
same owner validator back from `Schema`, so an owner-owned default removes the
callback inversion while preserving the existing implementation, fallback
clauses, field traversal, and issue order.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/timeline_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All six selected captures point directly to `TimelineHandoffContracts`, its
three-argument matching entry point owns the existing validator dependency, the
two facade wrappers are gone, issue ordering remains exact, validation and
schema exports remain byte-for-byte stable, focused tests pass, and bounded
review finds no blocker.

Verification gaps:
- None for this slice.

Tests run:
- `mix compile --warnings-as-errors`
- 117 focused cadence-import, review-import, and timeline-summary tests
- 182 complete schema-contract and schema-export tests
- full checked-in schema export regeneration; no schema diff
- aggregate schema bundle digest unchanged:
  `757bb20af70443e376085ef2e6f97e5a0a0a8ee97323b5911343e88cd8b9ad15`
- `mix format --check-formatted`
- `git diff --check`
- compile-connected xref check for `schema.ex`
- bounded read-only review: clean, no findings

Outcome:
All six publication-summary captures now point directly to
`TimelineHandoffContracts`. Its new three-argument entry point owns the existing
summary-validator dependency, the two pure facade wrappers are gone, and
`schema.ex` decreased from 8,295 to 8,278 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema timeline publication-summary callback ownership cleanup published as
`5bc62467`: six captures now point directly to `TimelineHandoffContracts`, the
owner internalizes its existing validator dependency, 182 schema/export tests
passed, full export bytes stayed exact, and bounded review was clean.

Next candidate:
Collapse the suppression-only callback boundary: two duplicate-group captures,
three source-match captures, and one cadence source-review capture currently
pass through five pure `Schema` facade clauses. Confirm the owner’s specialized
and fallback clauses remain exact, and leave duplicate-row evidence injection
separate.

Blocked:
No.
