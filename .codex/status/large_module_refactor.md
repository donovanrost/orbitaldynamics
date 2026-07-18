# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema Cadence source-review callback-provider extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move callback-key ordering and external contract wiring from
`cadence_source_review_row_contract_callbacks/0` into an internal
`Schema.CadenceSourceReviewRowCallbacks.build/1`, injecting only facade-private
validators.

Why this slice:
`Schema` is 7,725 lines. The source-review callback registry is a 164-line
responsibility mixing stable external contract captures with private facade
validators.

Current coupling/problem:
The facade owns the complete dependency registry, callback ordering, and dozens
of external handoff-contract module captures for Cadence source-review rows.

Public facade to preserve:
All `Schema` APIs; Cadence source-review validation behavior; callback keys,
order, values, arities, error ordering, deterministic output, and all schema
exports.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/cadence_source_review_row_callbacks.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The new provider owns the exact ordered callback registry and external captures;
`Schema` passes only private callback captures; focused Cadence source-review,
import, readiness, timeline, and export tests pass; strict compile, full
byte-clean schema regeneration, and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Candidate-rejection timeline schema dispatch published as implementation
`ee84e47c` and handoff `e8413564`: focused 25/25, strict 3,667-file compile,
full byte-clean schema regeneration, and independent review passed.

Next candidate:
Continue callback-provider extraction with the Cadence import or operator-review
registries after remapping the reduced facade.

Blocked:
No.
