# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport score-term manifest-row builder extraction.

Status:
Implementation published as `6a311378`; handoff publication pending.

Selected slice:
Move `score_term_manifest_row/2` into internal
`CadenceImport.ScoreTermManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,663 lines. The builder was a 32-line transformation with
23 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,641 lines.

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
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,689 files.
- Exact AST proof: 23/23 entries, full normalized body, and all public facade
  definitions match selection `78dec6b5`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Score-term action/status, import/approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Score-term row builder selected in `78dec6b5` and published in `6a311378`:
focused 100/100, strict 3,689-file compile, exact 23-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
