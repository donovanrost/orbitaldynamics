# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport refresh-budget manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `refresh_budget_manifest_row/2` and its exclusive
`refresh_budget_gate_status/1` clauses into internal
`CadenceImport.RefreshBudgetManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,719 lines. The builder has 31 projected keys, one exclusive
two-clause status helper, three shared dependencies, and one facade caller.

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
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Freshness row builder selected in `8a39fa27` and published in `f7830da5`:
focused 100/100, strict 3,686-file compile, exact 35-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
