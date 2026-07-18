# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-diff manifest-row builder extraction.

Status:
Implementation published as `46c32945`; handoff publication pending.

Selected slice:
Move `candidate_diff_manifest_row/2`, its scoped-context registry/merge, gate
policy, and semantic-reason normalization into internal
`CadenceImport.CandidateDiffManifestRow.build/3`. Inject five shared facade
helpers for changed fields/count, review action, adapter status, and compaction.

Why this slice:
`CadenceImport` was 5,295 lines. The builder had 66 base keys, one 46-field
scoped-context merge, four exclusive helper responsibilities, five shared
dependencies, and one facade caller. The facade is now 5,142 lines.

Public facade to preserve:
All `CadenceImport` APIs; all candidate-diff keys and value expressions; scoped
context precedence, gate and semantic-reason policy, changed-field behavior,
action/defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/candidate_diff_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 66-key base projection, scoped registry and
merge, gate policy, and semantic-reason normalization; the facade supplies five
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,702 files.
- Exact AST proof: 66/66 entries, 46/46 scoped registry, scoped/gate/semantic
  helpers, and all public facade definitions match selection `3b02d0f4`.
- Initial compile exposed missing callback threading in the moved scoped helper;
  corrected before the successful focused and strict gates.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Scoped-over-base precedence, gate and semantic-reason policy,
changed-field behavior, actions/defaults, compaction, deterministic output, and
APIs are exact.

Last completed slice:
Candidate-diff row builder selected in `3b02d0f4` and published in `46c32945`:
focused 100/100, strict 3,702-file compile, exact 66-entry/46-field/helper AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
