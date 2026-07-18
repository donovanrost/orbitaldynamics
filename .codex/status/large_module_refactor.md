# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport resource-projection manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `resource_projection_manifest_row/2` into internal
`CadenceImport.ResourceProjectionManifestRow.build/3`, injecting only the three
shared facade helpers for review action, adapter status, and compact-map
cleanup.

Why this slice:
`CadenceImport` is 6,327 lines. The resource-projection builder is a 125-line
transformation with 108 projected keys, one facade caller, and a complete call
inventory of only three shared dependencies.

Current coupling/problem:
The main artifact adapter embeds a large resource-projection and flow-summary
projection alongside every other source transformation.

Public facade to preserve:
All `CadenceImport` APIs; all resource-projection row keys and value
expressions; approval/import defaults, review action, adapter status,
compaction, deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/resource_projection_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 108-key projection; the facade supplies
only three same-purpose callbacks; focused Cadence-import and schema-contract
tests pass; strict warnings-as-errors compile, projection equivalence, public
API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and independent
  review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport station-calendar row builder published as implementation
`099f0ef9` and handoff `36f1ad87`: focused 100/100, strict 3,679-file compile,
exact 125-entry AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next low-coupling
source-specific manifest-row builder.

Blocked:
No.
