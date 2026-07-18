# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport generic-review manifest-row builder extraction.

Status:
Implementation published as `4a7c07a5`; handoff publication pending.

Selected slice:
Move `generic_review_manifest_row/2` into internal
`CadenceImport.GenericReviewManifestRow.build/3`. Inject seven shared facade
helpers for presence, action, review action, adapter status, activity context,
provider normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,317 lines. The builder had 20 base keys, one passthrough
registry merge, seven shared dependencies, and one fallback facade caller. The
facade is now 5,295 lines.

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
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,701 files.
- Exact AST proof: 20/20 base entries, protected passthrough/full normalized
  body, and all public facade definitions match selection `2b863c8e`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Passthrough-over-base precedence with computed presence protected,
activity normalization, actions/defaults, compaction, deterministic output, and
APIs are exact.

Last completed slice:
Generic-review row builder selected in `2b863c8e` and published in `4a7c07a5`:
focused 100/100, strict 3,701-file compile, exact 20-entry/protected-passthrough
full-body comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
