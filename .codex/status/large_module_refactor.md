# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `strategy_manifest_row/4` and all four exclusive
`strategy_import_status/2` clauses into internal
`CadenceImport.StrategyManifestRow.build/5`. Inject the three shared branch-field
list providers and compaction.

Why this slice:
After extracting recommendation context, the builder is a cohesive roughly
300-line boundary with one caller, an exact 204-key base projection, and four
shared callbacks. `CadenceImport` is 4,236 lines.

Public facade to preserve:
All `CadenceImport` APIs; all 204 base keys and selected/default expressions;
context merge order; branch-field, operational-feedback, and compaction
pipelines; status mapping; deterministic output; and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/strategy_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal builder owns the exact strategy projection and four status clauses;
the facade supplies four exact callbacks; focused tests, strict compile,
equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Strategy-recommendation context published in `2c7648e2`; handoff in `5416e4f6`.

Next candidate:
Remap the reduced facade after the strategy builder extraction.

Blocked:
No.
