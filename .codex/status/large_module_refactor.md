# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport approval-requirement manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `approval_requirement_manifest_row/2` and its now-exclusive candidate-diff
enrichment helpers into internal
`CadenceImport.ApprovalRequirementManifestRow.build/3`. Inject nine shared facade
helpers for policy selection, normalization, review/adapter status, activity
context, and compaction.

Why this slice:
`CadenceImport` is 5,142 lines. The builder has 33 base keys, an exclusive
candidate-diff enrichment chain, nine shared dependencies, and one facade
caller.

Public facade to preserve:
All `CadenceImport` APIs; all approval-requirement keys and fallback expressions;
policy escalation, candidate-diff enrichment, activity-context normalization,
action/defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/approval_requirement_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 33-key base projection and complete
candidate-diff enrichment chain; the facade supplies nine exact callbacks;
focused tests, strict compile, equivalence/API checks, and independent review
are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Candidate-diff row builder selected in `3b02d0f4` and published in `46c32945`:
focused 100/100, strict 3,702-file compile, exact 66-entry/46-field/helper AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
