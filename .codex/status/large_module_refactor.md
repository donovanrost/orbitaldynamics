# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-contention manifest-row builder extraction.

Status:
Implementation published as `8ae493a6`; handoff publication pending.

Selected slice:
Move `contact_contention_manifest_row/2` and its exclusive
`contact_contention_import_action/1` clauses into internal
`CadenceImport.ContactContentionManifestRow.build/3`. Inject the five shared
facade helpers for review action, adapter status, provider-result values,
station-calendar context fields, and compact-map cleanup.

Why this slice:
`CadenceImport` was 6,211 lines. The builder was a 125-line transformation with
107 projected keys, one station-context merge, two provider-result conversions,
and one facade caller. The facade is now 6,092 lines.

Public facade to preserve:
All `CadenceImport` APIs; all contact-contention keys and value expressions;
action policy, station-context merge precedence, provider-result normalization,
approval/import defaults, compaction, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/contact_contention_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 107-key projection, station-context merge,
and action clauses; the facade supplies five exact callbacks; focused tests,
strict compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- None for this slice.

Tests run:
- Focused CadenceImport and schema contracts: 100/100.
- Strict warnings-as-errors compile: 3,681 files.
- Exact AST proof: 107/107 entries, full normalized body, both action clauses,
  and all public facade definitions match selection `75718b78`.
- Format, diff, caller/xref, callback-surface, and whitespace checks clean.
- Independent read-only review: no code findings or additional test gaps.

Behavior/schema changes:
None. Station-context precedence, provider-result normalization, action policy,
approval/import defaults, compaction, deterministic output, and APIs are exact.

Last completed slice:
Contact-contention row builder selected in `75718b78` and published in
`8ae493a6`: focused 100/100, strict 3,681-file compile, exact 107-entry/full-body
AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
