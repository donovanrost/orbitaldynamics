# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport contact-contention manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `contact_contention_manifest_row/2` and its exclusive
`contact_contention_import_action/1` clauses into internal
`CadenceImport.ContactContentionManifestRow.build/3`. Inject the five shared
facade helpers for review action, adapter status, provider-result values,
station-calendar context fields, and compact-map cleanup.

Why this slice:
`CadenceImport` is 6,211 lines. The builder is a 125-line transformation with
107 projected keys, one station-context merge, two provider-result conversions,
and one facade caller.

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
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Resource-projection row builder published as implementation `6f621cde` and
handoff `62136117`: focused 100/100, strict 3,680-file compile, exact
108-entry AST comparison, and independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
