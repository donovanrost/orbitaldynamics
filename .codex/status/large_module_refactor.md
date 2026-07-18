# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport schema-validation manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `schema_validation_manifest_row/2` into internal
`CadenceImport.SchemaValidationManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,454 lines. The builder is a 45-line transformation with 35
projected keys, one local issue-count computation, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all schema-validation keys and value expressions;
issue-count semantics, action/status, import/approval defaults, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/schema_validation_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 35-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Objective-satisfaction row builder selected in `66eccccd` and published in
`0b333d0e`: focused 100/100, strict 3,696-file compile, exact 31-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
