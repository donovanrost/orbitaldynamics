# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema policy capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the capability-derived policy model-limit projection into
`OrbitalDynamics.Schema.PolicyCapabilityContext`.
Import that focused internal API into the Schema facade.
Keep policy schema construction, property dispatch, approval/policy
validation, and all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,184 lines.
- The private projection converts Policy capability atoms to strings and feeds
  two property-dispatch paths plus four validation paths.
- Importing the focused API preserves existing callback captures and
  validation calls while leaving every consumer in its current owner.
- Exact model-limit values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema maneuver-review capability-context extraction, selected in `381c3a71`
and implemented in `d4761487`.
`schema.ex` moved from 6,188 to 6,184 lines; the dedicated
ManeuverReviewCapabilityContext owner is 13 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
