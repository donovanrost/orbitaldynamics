# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport refresh-budget manifest-row builder extraction.

Status:
Implementation published as `aa80b944`; handoff publication pending.

Selected slice:
Move `refresh_budget_manifest_row/2` and its exclusive
`refresh_budget_gate_status/1` clauses into internal
`CadenceImport.RefreshBudgetManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,719 lines. The builder had 31 projected keys, one
exclusive two-clause status helper, three shared dependencies, and one facade
caller. The facade is now 5,681 lines.

Public facade to preserve:
All `CadenceImport` APIs; all refresh-budget keys and value expressions;
dropped-count fallback, gate-status policy, import/approval defaults,
compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/refresh_budget_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 31-key projection and both gate-status
clauses; the facade supplies three exact callbacks; focused tests, strict
compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,687 files.
- Exact AST proof: 31/31 entries, full normalized body, both status clauses, and
  all public facade definitions match selection `e5766ecd`.
- Dropped-count scalar/list fallback is exact.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Gate-status policy, dropped-count fallback, import/approval defaults,
compaction, deterministic output, and APIs are exact.

Last completed slice:
Refresh-budget row builder selected in `e5766ecd` and published in `aa80b944`:
focused 100/100, strict 3,687-file compile, exact 31-entry/full-body AST and
two-clause comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
