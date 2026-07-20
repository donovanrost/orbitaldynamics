# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema candidate-activity owner completion.

Status:
Selected; implementation pending.

Selected boundary:
Extend `StateRefreshArtifactValidation.validate/4` to own
`candidate_activity.v1`, whose registry is already included in that owner.
Route the direct `Schema` clause through the existing state-refresh owner while
preserving required-field setup followed by `CandidateActivityContracts`.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,730 lines; the other
  targeted public facades are now 164 to 524 lines.
- The direct clause repeats the same generic registered-artifact routing pattern
  already owned for the surrounding candidate-refresh artifact family.
- `StateRefreshArtifactValidation` already merges
  `CandidateRefreshRegistryContracts`, including `candidate_activity.v1`.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, validation ordering and paths, public `Schema`
and `StateRefreshArtifactValidation` APIs, validation results, and checked-in
exports must remain unchanged.

Last completed slice:
Schema resource-summary owner completion, selected in `427ca19f` and implemented
in `7778c944`. `schema.ex` moved from 4,732 to 4,730 lines.

Next candidate:
Implement and verify the selected candidate-activity owner completion, then
re-rank the remaining Schema responsibility clusters.

Blocked:
No.
