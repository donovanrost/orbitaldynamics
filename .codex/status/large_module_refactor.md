# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport score-term manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `score_term_manifest_row/2` into internal
`CadenceImport.ScoreTermManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,663 lines. The builder is a 32-line transformation with 23
projected keys, no exclusive helper dependencies, and one facade caller.

Public facade to preserve:
All `CadenceImport` APIs; all score-term keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/score_term_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 23-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Timeline-protection row builder selected in `22a336d7` and published in
`e341968a`: focused 100/100, strict 3,688-file compile, exact 19-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
