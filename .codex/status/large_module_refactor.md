# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport timeline-diff manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `timeline_diff_manifest_row/2` into internal
`CadenceImport.TimelineDiffManifestRow.build/3`, injecting only the five shared
facade helpers for review action, adapter status, generic activity-context
selection, provider-result normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` is 7,166 lines. The timeline-diff builder is a 266-line
transformation with 182 projected keys and one facade caller.

Current coupling/problem:
The main artifact adapter embeds a large timeline-diff and transition-
application projection alongside every other source family’s transformation.

Public facade to preserve:
All `CadenceImport` APIs; all timeline-diff row keys and value expressions;
approval/import defaults, activity-context fallback and normalization, import
status/action, compaction, deterministic output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/timeline_diff_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 182-key projection; the facade supplies
only five same-purpose callbacks; focused Cadence-import and schema-contract
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
CadenceImport operational-timeline row builder published as implementation
`a05666c3` and handoff `31115713`: focused 100/100, strict 3,675-file compile,
exact 287-entry AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
