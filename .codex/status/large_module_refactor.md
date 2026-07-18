# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport pareto-frontier manifest-row builder extraction.

Status:
Implementation published as `92bd80b5`; handoff publication pending.

Selected slice:
Move `pareto_frontier_manifest_row/2` into internal
`CadenceImport.ParetoFrontierManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,641 lines. The builder was a 33-line transformation with
24 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,618 lines.

Public facade to preserve:
All `CadenceImport` APIs; all pareto-frontier keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/pareto_frontier_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 24-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,690 files.
- Exact AST proof: 24/24 entries, full normalized body, and all public facade
  definitions match selection `f62d24b7`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Pareto-frontier action/status, import/approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Pareto-frontier row builder selected in `f62d24b7` and published in `92bd80b5`:
focused 100/100, strict 3,690-file compile, exact 24-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
