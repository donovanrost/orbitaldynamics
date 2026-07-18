# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport operational-timeline manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `operational_timeline_manifest_row/2` into internal
`CadenceImport.OperationalTimelineManifestRow.build/3`, injecting only the six
shared facade helpers for import presence, review action, adapter status,
provider-result normalization/value extraction, and compact-map cleanup.

Why this slice:
`CadenceImport` is 7,460 lines. The operational-timeline builder is a 306-line
transformation with 287 projected keys and one facade caller.

Current coupling/problem:
The main artifact adapter embeds a large operational-timeline field projection
alongside every other source family’s manifest transformation.

Public facade to preserve:
All `CadenceImport` APIs; all operational-timeline row keys and value
expressions; approval/import defaults, import presence, provider-result
normalization, import status/action, compaction, deterministic output, and
artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/operational_timeline_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 287-key projection; the facade supplies
only six same-purpose callbacks; focused Cadence-import and schema-contract
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
CadenceImport strategy-recommendation row builder published as implementation
`1126b2ac` and handoff `f193b639`: focused 100/100, strict 3,674-file compile,
exact 200-entry and 34-stage pipeline comparison, and independent review
passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
