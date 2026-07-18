# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport command-window manifest-row builder extraction.

Status:
Implementation published as `60607379`; handoff publication pending.

Selected slice:
Move `command_window_manifest_row/2` into internal
`CadenceImport.CommandWindowManifestRow.build/3`. Inject the five shared facade
helpers for review action, adapter status, provider-result values, provider
context normalization, and compact-map cleanup.

Why this slice:
`CadenceImport` was 5,983 lines. The builder was a 118-line transformation with
101 projected keys, two provider-result conversions, two identical context
normalizations, no exclusive helper dependencies, and one facade caller. The
facade is now 5,877 lines.

Public facade to preserve:
All `CadenceImport` APIs; all command-window keys and value expressions; import
status/type defaults, context alias normalization, provider-result conversion,
approval defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/command_window_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 101-key projection; the facade supplies five
exact callbacks; focused tests, strict compile, equivalence/API checks, and
independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,683 files.
- Exact AST proof: 101/101 entries, full normalized body, and all public facade
  definitions match selection `157146a5`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Import status/type defaults, both context aliases, provider-result
conversion, approval defaults, compaction, deterministic output, and APIs are
exact.

Last completed slice:
Command-window row builder selected in `157146a5` and published in `60607379`:
focused 100/100, strict 3,683-file compile, exact 101-entry/full-body AST
comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
