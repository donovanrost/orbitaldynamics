# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CadenceImport strategy-recommendation context extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move the contiguous pure strategy-recommendation context cluster into internal
`CadenceImport.StrategyRecommendationContext`: resource-pressure,
readiness/quality-gate, risk, resource-margin, merge, and value-collection
helpers. Update the strategy row builder to call four explicit internal entry
points.

Why this slice:
The reduced facade is 4,662 lines. This roughly 440-line cluster is cohesive and
dependency-free. The adjacent operational-feedback trust helpers are excluded
because they also serve an upstream facade path.

Public facade to preserve:
All `CadenceImport` APIs; exact context maps, filtering, normalization,
deduplication, sorting, merge semantics, deterministic output, and contracts.

Likely files:
- `lib/orbital_dynamics/cadence_import.ex`
- `lib/orbital_dynamics/cadence_import/strategy_recommendation_context.ex`
- `.codex/status/large_module_refactor.md`

Likely tests:
- `test/orbital_dynamics/cadence_import_test.exs`
- `test/orbital_dynamics/schema/cadence_import_contracts_test.exs`

Definition of done:
The internal module owns the exact pure context cluster behind explicit
resource-pressure, readiness/quality-gate, risk, and merge entry points;
operational-feedback helpers remain in the facade; focused tests, strict
compile, equivalence/API checks, and independent review are clean.

Verification gaps:
- Focused baseline, implementation proof, strict compile, and review remain.

Behavior/schema changes:
None intended.

Last completed slice:
Suppression row builder published in `9ed575c7`; handoff in `c87f0a7a`.

Next candidate:
Remap the reduced strategy builder after this extraction.

Blocked:
No.
