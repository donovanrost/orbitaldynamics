# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-summary owner completion.

Status:
Selected; implementation pending.

Selected boundary:
Extend `ResourceValidation.validate_artifact/4` and its registry lookup to own
`resource_summary.v1`. Route the direct `Schema` clause through the existing
resource owner while preserving its current required-field pass followed by
the existing summary-contract validation.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,732 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats the same registered-artifact routing pattern already
  owned by `ResourceValidation` for projection and filter artifacts.
- `ResourceSummaryRegistryContracts` and `ResourceSummaryContracts` already
  provide the required fields and exact validator.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, duplicate required-field issue behavior,
validation ordering and paths, public `Schema` and `ResourceValidation` APIs,
validation results, and checked-in exports must remain unchanged.

Last completed slice:
Schema command-window report owner extraction, selected in `402d1b0e` and
implemented in `5ce5df9f`. `schema.ex` moved from 4,737 to 4,732 lines.

Next candidate:
Implement and verify the selected resource-summary owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
