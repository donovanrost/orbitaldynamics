# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport freshness manifest-row builder extraction.

Status:
Implementation published as `f7830da5`; handoff publication pending.

Selected slice:
Move `freshness_manifest_row/2` into internal
`CadenceImport.FreshnessManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,755 lines. The builder was a 46-line transformation with
35 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,719 lines.

Public facade to preserve:
All `CadenceImport` APIs; all freshness keys and value expressions; stale and
unknown reason normalization/counting, import/approval defaults, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/freshness_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 35-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,686 files.
- Exact AST proof: 35/35 entries, full normalized body, and all public facade
  definitions match selection `8a39fa27`.
- Both reason-list normalizations and their summed count are exact.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Freshness action/status, import/approval defaults, reason normalization
and counting, compaction, deterministic output, and APIs are exact.

Last completed slice:
Freshness row builder selected in `8a39fa27` and published in `f7830da5`:
focused 100/100, strict 3,686-file compile, exact 35-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
