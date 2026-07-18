# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport generic-review manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `generic_review_manifest_row/2` into internal
`CadenceImport.GenericReviewManifestRow.build/3`. Inject seven shared facade
helpers for presence, action, review action, adapter status, activity context,
provider normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,317 lines. The builder has 20 base keys, one passthrough
registry merge, seven shared dependencies, and one fallback facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all generic-review keys and value expressions;
passthrough precedence with `has_cadence_import` protected, activity-context
normalization, presence/action/defaults, compaction, and deterministic output.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/generic_review_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 20-key base projection and protected
passthrough merge; the facade supplies seven exact callbacks; focused tests,
strict compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Operational-readiness row builder selected in `5bacc482` and published in
`452ab316`: focused 100/100, strict 3,700-file compile, exact 36-entry/full-body
and four-merge comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
