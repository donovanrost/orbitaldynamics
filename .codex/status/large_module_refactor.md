# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-feedback manifest-context extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `operational_feedback_manifest_context/1` and its exclusive trust-status,
trust-boundary, field-boundary, and merge helpers into internal
`CadenceImport.OperationalFeedbackManifestContext.build/2`. Inject shared
`stringify_keys/1`, `encode_json_value/1`, and `compact_map/1`.

Why this slice:
The reduced facade is 3,942 lines. This contiguous roughly 138-line provenance
cluster has one upstream caller, an exact 7-key projection, exclusive helper
ownership, and three shared normalization/compaction dependencies.

Public facade to preserve:
All `CadenceImport` APIs; exact trust classification, source normalization,
deduplication and sorting, field-boundary merge semantics, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/operational_feedback_manifest_context.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal module owns the exact 7-key projection and all exclusive trust and
merge clauses; the facade supplies three exact callbacks; focused tests, strict
compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.
- Initial implementation compile exposed omitted stringify and JSON-encoding
  dependencies; the boundary was corrected before successful compile.

Behavior/schema changes:
None intended.

Last completed slice:
Strategy row builder published in `9fccbf48`; handoff in `5c74d4e0`.

Next candidate:
Remap the reduced facade and station-reservation specialization.

Blocked:
No.
