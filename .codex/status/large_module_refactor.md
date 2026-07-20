# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema result-artifact validation owner extraction.

Status:
Complete and pushed.

Selected boundary:
Add a focused `ResultArtifactValidation` owner that resolves standalone
requirements from `StudyResultRegistryContracts`, delegates nested execution
reports directly to `ExecutionReproducibilityValidation` at root path `"$"`,
and routes the direct `result_artifact.v1` `Schema` clause through it. Remove
the facade-only nested callback.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,627 lines; the other
  targeted public facades are now 164 to 524 lines.
- The remaining specialized clause owns required-field setup and a callback
  that re-enters only the already-extracted execution-report owner.
- The callback always validates the nested report at `"$"` and prepends its
  issues exactly as `ResultArtifactContracts` specifies.
- `StudyResultRegistryContracts` already owns the standalone requirements, so
  no full-facade registry access is needed.

Implementation:
Added a 35-line `ResultArtifactValidation` owner that resolves standalone
requirements and delegates nested execution reports directly to the existing
execution/reproducibility owner at root path `"$"`. Routed the direct
result-artifact clause through it and removed the facade-only recursive
callback. `schema.ex` moved from 4,627 to 4,614 lines.

Verification:
- Strict result-artifact, nested execution-report, fixture, refresh, and review
  baseline: 22 tests passed.
- Result/execution, validation, planner, refresh, review, export, and fixture
  adjacency: 30 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,091 files successfully.

Behavior/schema changes:
None. Required fields, nested execution-report root paths and issue ordering,
public `Schema`, validation results, and checked-in exports remain unchanged.

Last completed slice:
Schema result-artifact validation owner extraction, selected in `b2c2ddfe` and
implemented in `0c3e0f97`. `schema.ex` moved from 4,627 to 4,614 lines.

Next candidate:
Re-rank the remaining `Schema` responsibilities now that every specialized
validation clause routes through a focused owner; assess fallback routing,
JSON-schema property dispatch, and other large cohesive blocks.

Blocked:
No.
