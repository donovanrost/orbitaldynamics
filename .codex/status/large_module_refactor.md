# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport warning manifest-row builder extraction.

Status:
Implementation published as `394c3213`; handoff publication pending.

Selected slice:
Move `warning_manifest_row/2` into internal
`CadenceImport.WarningManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,877 lines. The builder was a 71-line transformation with
46 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,816 lines.

Public facade to preserve:
All `CadenceImport` APIs; all warning keys and value expressions; resource
pressure fallback precedence, import/approval defaults, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/warning_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 46-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,684 files.
- Exact AST proof: 46/46 entries, full normalized body, and all public facade
  definitions match selection `e9d8d589`.
- All eight resource-pressure fallbacks retain primary-row precedence.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Warning action/status, import/approval defaults, resource-pressure
fallbacks, compaction, deterministic output, and APIs are exact.

Last completed slice:
Warning row builder selected in `e9d8d589` and published in `394c3213`: focused
100/100, strict 3,684-file compile, exact 46-entry/full-body AST comparison, and
independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
