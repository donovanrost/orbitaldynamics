# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema accepted-state/candidate-refresh validation context extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add StateRefreshArtifactValidation owner-default entry points for three
accepted-state artifacts and eight candidate-refresh/diff/window artifacts.
Derive requirements from the accepted-state and candidate-refresh registries,
compose the candidate-refresh report callbacks from existing owners, and route
all 11 direct Schema clauses. Keep artifact contract APIs unchanged.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,939 lines; the other
  targeted public facades are now 164 to 524 lines.
- Eleven adjacent direct clauses repeat registry requirements and owner routing.
- AcceptedStateRegistryContracts and CandidateRefreshRegistryContracts own
  every required-field definition.
- CandidateRefreshContracts needs only existing contact-allocation and
  candidate-rejection owner callbacks.
- Accepted-state, candidate-diff, freshness, budget, and window contract modules
  own all remaining artifact-specific validation.
- No route needs recursive Schema lookup or facade-local callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, callbacks, validation ordering and paths,
public Schema APIs, validation results, and checked-in exports must remain
unchanged.

Last completed slice:
Schema validation-reference/acceptance context extraction, selected in
`f8ce79ba` and implemented in `f71e1160`.
`schema.ex` moved from 4,958 to 4,939 lines.

Next candidate:
Implement and verify the selected accepted-state/candidate-refresh context
extraction, then re-rank the remaining Schema responsibility clusters.

Blocked:
No.
