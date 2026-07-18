# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport risk manifest-row builder extraction.

Status:
Implementation published as `79067c2b`; handoff publication pending.

Selected slice:
Move `risk_manifest_row/2` into internal
`CadenceImport.RiskManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,816 lines. The builder was a 70-line transformation with
47 projected keys, no exclusive helper dependencies, and one facade caller.
The facade is now 5,755 lines.

Public facade to preserve:
All `CadenceImport` APIs; all risk keys and value expressions; resource-pressure
and source-window fallback precedence, import/approval defaults, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/risk_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 47-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,685 files.
- Exact AST proof: 47/47 entries, full normalized body, and all public facade
  definitions match selection `512d1c03`.
- All six resource-pressure and three source-window fallbacks retain primary-row
  precedence.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Risk action/status, import/approval defaults, all nine fallbacks,
compaction, deterministic output, and APIs are exact.

Last completed slice:
Risk row builder selected in `512d1c03` and published in `79067c2b`: focused
100/100, strict 3,685-file compile, exact 47-entry/full-body AST comparison, and
independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
