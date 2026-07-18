# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport realized-feedback manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `realized_feedback_manifest_row/2` and its exclusively used
`realized_feedback_has_cadence_import?/2`, `realized_feedback_import_status/2`,
and `realized_feedback_import_action/1` helpers into internal
`CadenceImport.RealizedFeedbackManifestRow.build/3`. Inject only the shared
facade helpers for review action, provider-result normalization, adapter status,
and compact-map cleanup.

Why this slice:
`CadenceImport` is 8,285 lines. The realized-feedback row builder is 451 lines,
and its adjacent specialized status/action helpers add 18 lines. The builder is
a self-contained artifact-row transformation with one facade caller.

Current coupling/problem:
The main artifact adapter embeds an exceptionally large realized-feedback field
projection and its specialized import-state policy alongside every other source
family’s manifest transformation.

Public facade to preserve:
All `CadenceImport` APIs; realized-feedback manifest row keys, values, default
statuses, identifiers, import actions, import statuses, provider-result
normalization, compaction, deterministic row output, and artifact contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/realized_feedback_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact realized-feedback row projection and
specialized status/action helpers; the facade supplies only the five shared
callbacks; focused Cadence-import and schema-contract tests pass; strict
warnings-as-errors compile, public API and row-construction equivalence checks,
and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and independent
  review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport generic-review passthrough registry published as implementation
`514d444a` and handoff `fe952c71`: focused 100/100, strict 3,672-file compile,
exact 384-entry comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
