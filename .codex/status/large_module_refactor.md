# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport candidate-diff manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `candidate_diff_manifest_row/2`, its scoped-context registry/merge, gate
policy, and semantic-reason normalization into internal
`CadenceImport.CandidateDiffManifestRow.build/3`. Inject five shared facade
helpers for changed fields/count, review action, adapter status, and compaction.

Why this slice:
`CadenceImport` is 5,295 lines. The builder has 66 base keys, one scoped-context
merge, four exclusive helper responsibilities, five shared dependencies, and
one facade caller.

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
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Generic-review row builder selected in `2b863c8e` and published in `4a7c07a5`:
focused 100/100, strict 3,701-file compile, exact 20-entry/protected-passthrough
full-body comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
