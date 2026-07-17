# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-review source callback ownership cleanup.

Status:
Selected; implementation pending.

Selected slice:
Point provider-counteroffer and contact-intent general/cadence source-match
callbacks directly at `Schema.ContactReviewHandoffContracts`. Remove both
specialized/fallback facade wrapper pairs across eight callback positions.

Why this slice:
Each family has three general capture positions and one cadence position. The
facade duplicates the owner's specialized source-row dispatch and permissive
fallback clauses; direct captures preserve field-pair order without moving
contact-review logic or introducing dependencies.

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
All eight selected captures point directly to `ContactReviewHandoffContracts`,
the four specialized/fallback facade wrapper pairs are gone, and callback plus
field-pair issue ordering remains exact,
validation and schema exports remain byte-for-byte stable, focused tests pass,
and bounded review finds no blocker.

Verification gaps:
- Implementation and verification pending.

Tests run:
- Pending.

Behavior/schema changes:
None.

Last completed slice:
Schema readiness/quality-gate source callback ownership cleanup published as
`671dd406`: fourteen readiness gate/report and quality row/report captures now
point directly to their dedicated owners; 182 schema/export tests passed, full
export bytes stayed exact, and bounded review was clean.

Next candidate:
Audit the contact-review source-match family. Provider-counteroffer and
contact-intent general/cadence wrappers duplicate specialized/fallback clauses
already exposed by `ContactReviewHandoffContracts` across eight capture
positions.

Blocked:
No.
