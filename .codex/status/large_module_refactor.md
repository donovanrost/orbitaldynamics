# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema suppression duplicate-evidence callback ownership cleanup.

Status:
Ready for implementation.

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
- Implementation and verification pending.

Tests run:
- Selection only; implementation verification pending.

Behavior/schema changes:
None.

Last completed slice:
Schema suppression callback ownership cleanup published as `8805d3da`: six
captures now point directly to `SuppressionHandoffContracts`, five pure facade
clauses were removed, 182 schema/export tests passed, full export bytes stayed
exact, and bounded review was clean.

Next candidate:
After this boundary, audit the remaining pure contact-allocation and quality
handoff summary delegates by owner and capture count.

Blocked:
No.
