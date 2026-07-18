# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport quality-gate manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `quality_gate_manifest_row/2` into internal
`CadenceImport.QualityGateManifestRow.build/3`. Inject the five shared facade
helpers for review action, adapter status, readiness cadence-import context,
readiness resource context, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,419 lines. The builder has 33 projected keys, two ordered
context merges, five shared dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all quality-gate keys and value expressions; cadence
then resource context precedence, action/status, import/approval defaults,
compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/quality_gate_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 33-key projection and ordered merges; the
facade supplies five exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Schema-validation row builder selected in `0da37cf7` and published in
`5c68b8a7`: focused 100/100, strict 3,697-file compile, exact 35-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
