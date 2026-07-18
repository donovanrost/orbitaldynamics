# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport schema-validation manifest-row builder extraction.

Status:
Implementation published as `5c68b8a7`; handoff publication pending.

Selected slice:
Move `schema_validation_manifest_row/2` into internal
`CadenceImport.SchemaValidationManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,454 lines. The builder was a 45-line transformation with
35 projected keys, one local issue-count computation, and one facade caller.
The facade is now 5,419 lines.

Public facade to preserve:
All `CadenceImport` APIs; all schema-validation keys and value expressions;
issue-count semantics, action/status, import/approval defaults, compaction,
deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/schema_validation_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 35-key projection; the facade supplies three
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,697 files.
- Exact AST proof: 35/35 entries, full normalized body, and all public facade
  definitions match selection `0da37cf7`.
- The error-plus-warning issue-count expression is exact.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Schema-validation action/status, issue count, import/approval defaults,
compaction, deterministic output, and APIs are exact.

Last completed slice:
Schema-validation row builder selected in `0da37cf7` and published in
`5c68b8a7`: focused 100/100, strict 3,697-file compile, exact 35-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
