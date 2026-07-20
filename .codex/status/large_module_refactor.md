# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema result-artifact validation owner extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, nested execution-report root paths and issue
ordering, public `Schema`, validation results, and checked-in exports must
remain unchanged.

Last completed slice:
Schema capability-catalog validation owner extraction, selected in `c4e1db05`
and implemented in `cf2a0310`. `schema.ex` moved from 4,632 to 4,627 lines.

Next candidate:
Implement and verify the selected result-artifact owner, then re-rank the
remaining fallback validation and facade responsibilities.

Blocked:
No.
