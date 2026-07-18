# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport objective-satisfaction manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `objective_satisfaction_manifest_row/2` into internal
`CadenceImport.ObjectiveSatisfactionManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,484 lines. The builder is a 40-line transformation with 31
projected keys, no exclusive helper dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all objective-satisfaction keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/objective_satisfaction_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 31-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Execution row builder selected in `1509e848` and published in `944bf730`:
focused 100/100, strict 3,695-file compile, exact 31-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
