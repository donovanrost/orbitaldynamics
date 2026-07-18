# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport link-capacity manifest-row builder extraction.

Status:
Implementation published as `31d860df`; handoff publication pending.

Selected slice:
Move `link_capacity_manifest_row/2` into internal
`CadenceImport.LinkCapacityManifestRow.build/3`. Inject the four shared facade
helpers for review action, adapter status, provider-result values, and
compact-map cleanup.

Why this slice:
`CadenceImport` was 6,092 lines. The builder was a 120-line transformation with
105 projected keys, two provider-result conversions, no exclusive helper
dependencies, and one facade caller. The facade is now 5,983 lines.

Public facade to preserve:
All `CadenceImport` APIs; all link-capacity keys and value expressions; constant
action/import semantics, provider-result normalization, approval defaults,
compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/link_capacity_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 105-key projection; the facade supplies four
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,682 files.
- Exact AST proof: 105/105 entries, full normalized body, and all public facade
  definitions match selection `0ef33258`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Constant action/import semantics, provider-result normalization, approval
defaults, compaction, deterministic output, and APIs are exact.

Last completed slice:
Link-capacity row builder selected in `0ef33258` and published in `31d860df`:
focused 100/100, strict 3,682-file compile, exact 105-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
