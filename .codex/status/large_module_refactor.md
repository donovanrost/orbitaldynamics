# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport ranking-comparison manifest-row builder extraction.

Status:
Implementation published as `c58ebf4d`; handoff publication pending.

Selected slice:
Move `ranking_comparison_manifest_row/2` into internal
`CadenceImport.RankingComparisonManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,593 lines. The builder was a 35-line transformation with
26 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,568 lines.

Public facade to preserve:
All `CadenceImport` APIs; all ranking-comparison keys and value expressions;
action/status semantics, import/approval defaults, compaction, deterministic
output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/ranking_comparison_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 26-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,692 files.
- Exact AST proof: 26/26 entries, full normalized body, and all public facade
  definitions match selection `b49ea026`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Ranking-comparison action/status, import/approval defaults, compaction,
deterministic output, and APIs are exact.

Last completed slice:
Ranking-comparison row builder selected in `b49ea026` and published in
`c58ebf4d`: focused 100/100, strict 3,692-file compile, exact 26-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
