# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport execution manifest-row builder extraction.

Status:
Implementation published as `944bf730`; handoff publication pending.

Selected slice:
Move `execution_manifest_row/2` into internal
`CadenceImport.ExecutionManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,514 lines. The builder was a 40-line transformation with
31 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,484 lines.

Public facade to preserve:
All `CadenceImport` APIs; all execution keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/execution_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 31-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,695 files.
- Exact AST proof: 31/31 entries, full normalized body, and all public facade
  definitions match selection `1509e848`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Execution action/status, import/approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Execution row builder selected in `1509e848` and published in `944bf730`:
focused 100/100, strict 3,695-file compile, exact 31-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
