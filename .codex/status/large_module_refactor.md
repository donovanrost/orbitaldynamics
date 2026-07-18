# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport link-capacity manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `link_capacity_manifest_row/2` into internal
`CadenceImport.LinkCapacityManifestRow.build/3`. Inject the four shared facade
helpers for review action, adapter status, provider-result values, and
compact-map cleanup.

Why this slice:
`CadenceImport` is 6,092 lines. The builder is a 120-line transformation with
105 projected keys, two provider-result conversions, no exclusive helper
dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all link-capacity keys and value expressions; constant
action/import semantics, provider-result normalization, approval defaults,
compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/link_capacity_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 105-key projection; the facade supplies four
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Contact-contention row builder selected in `75718b78` and published in
`8ae493a6`: focused 100/100, strict 3,681-file compile, exact 107-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
