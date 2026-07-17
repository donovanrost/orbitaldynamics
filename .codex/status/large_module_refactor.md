# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema suppression duplicate-evidence callback ownership cleanup.

Status:
Completed and published.

Selected slice:
Give `Schema.SuppressionHandoffContracts` a three-argument duplicate-row entry
point that uses `SuppressedCandidateContracts.validate_duplicate_evidence/3`.
Point all three duplicate-row captures at the owner and remove the two pure
facade helpers while retaining the existing four-argument API.

Why this slice:
The facade’s evidence validator is a one-hop delegate to the stable suppressed
candidate contract and is used only by the duplicate-row wrapper. An owner
default can supply that same callback to the unchanged four-argument pipeline,
removing callback inversion without coupling the owner to facade state.

Public facade to preserve:
All `OrbitalDynamics.Schema` public functions, exact validation issue ordering,
paths and messages, cadence-import behavior, JSON Schema bytes, and aggregate
schema export bytes.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/suppression_handoff_contracts.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused cadence-import, readiness, and review-import handoff contract tests
- JSON Schema contract/export tests and full checked-in schema regeneration
- strict compile, format, xref, diff hygiene, and bounded review

Definition of done:
All three selected captures point directly to the owner’s new default, the two
pure facade helpers are gone, the existing four-argument pipeline and evidence
validator behavior remain exact, validation and schema exports remain
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
- compile-connected xref checks for `schema.ex` and
  `suppression_handoff_contracts.ex`
- bounded read-only review: clean, no findings

Outcome:
All three suppression duplicate-row captures now point directly to the owner’s
new three-argument default. The unchanged four-argument pipeline receives the
same suppressed-candidate evidence validator, both pure facade helpers are
gone, and `schema.ex` decreased from 8,242 to 8,225 lines.

Behavior/schema changes:
None.

Last completed slice:
Schema suppression duplicate-evidence callback ownership cleanup published as
`9d901f0d`: three captures now use the owner’s default evidence pipeline, two
pure facade helpers were removed, 182 schema/export tests passed, full export
bytes stayed exact, and bounded review was clean.

Next candidate:
Point the two contact-allocation expiration-summary captures directly at
`ContactAllocationHandoffContracts.validate_expiration_summary/3` and remove
the pure facade delegate. Keep the single quality-gate summary delegate
separate.

Blocked:
No.
