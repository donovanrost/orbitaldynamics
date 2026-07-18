# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport command-window manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `command_window_manifest_row/2` into internal
`CadenceImport.CommandWindowManifestRow.build/3`. Inject the five shared facade
helpers for review action, adapter status, provider-result values, provider
context normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,983 lines. The builder is a 118-line transformation with
101 projected keys, two provider-result conversions, two identical context
normalizations, no exclusive helper dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all command-window keys and value expressions; import
status/type defaults, context alias normalization, provider-result conversion,
approval defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/command_window_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 101-key projection; the facade supplies five
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Link-capacity row builder selected in `0ef33258` and published in `31d860df`:
focused 100/100, strict 3,682-file compile, exact 105-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
