# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-recommendation manifest-row builder extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move `strategy_recommendation_manifest_row/2` into internal
`CadenceImport.StrategyRecommendationManifestRow.build/3`. Keep public
`RecommendationRiskContext` catalogs referenced directly and inject only the
six shared facade helpers for review action, adapter status, three branch field
catalogs, and compact-map cleanup.

Why this slice:
`CadenceImport` is 7,827 lines. The strategy-recommendation row builder is a
379-line transformation with 200 direct projection keys, 30 shared
`RecommendationRiskContext` catalog merges, and one facade caller.

Current coupling/problem:
The main artifact adapter embeds a large strategy-recommendation projection and
its long ordered context-merge pipeline alongside every other source family’s
manifest transformation.

Public facade to preserve:
All `CadenceImport` APIs; strategy-recommendation row keys and value
expressions; all 30 context catalog merges and their order; branch field merges;
defaults, import status/action, compaction, deterministic output, and artifact
contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/strategy_recommendation_manifest_row.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The internal builder owns the exact 200-key projection and ordered merge
pipeline; the facade supplies only six same-purpose callbacks; focused
Cadence-import and schema-contract tests pass; strict warnings-as-errors
compile, projection/merge equivalence, public API checks, and independent
review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and independent
  review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
CadenceImport realized-feedback row builder published as implementation
`44f84e10` and handoff `672fa031`: focused 100/100, strict 3,673-file compile,
exact 435-entry AST comparison, independent behavior matrix, and review passed.

Next candidate:
Remap the reduced `CadenceImport` module and select the next source-specific
manifest-row builder.

Blocked:
No.
