# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport freshness manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `freshness_manifest_row/2` into internal
`CadenceImport.FreshnessManifestRow.build/3`. Inject the three shared facade
helpers for review action, adapter status, and compact-map cleanup.

Why this slice:
`CadenceImport` is 5,755 lines. The builder is a 46-line transformation with 35
projected keys, no exclusive helper dependencies, and one facade caller.

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
- Focused baseline, implementation proof, strict compile, and review remain.

Tests run:
- None yet.

Behavior/schema changes:
None intended.

Last completed slice:
Risk row builder selected in `512d1c03` and published in `79067c2b`: focused
100/100, strict 3,685-file compile, exact 47-entry/full-body AST comparison, and
independent review passed.

Next candidate:
Remap the reduced `CadenceImport` module for the next low-coupling builder.

Blocked:
No.
