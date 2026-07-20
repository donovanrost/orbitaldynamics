# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema maneuver-review capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract the maneuver-recommendation and maneuver-review report model-limit
projections into
`OrbitalDynamics.Schema.ManeuverReviewCapabilityContext`.
Import those two focused internal APIs into the Schema facade.
Keep maneuver schema construction, property dispatch, report validation, and
all public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,188 lines.
- The two adjacent private helpers form the complete schema-facing
  ManeuverReview capability boundary: recommendation limits from the domain
  API and atom-to-string report limits from the capabilities map.
- Importing those two focused APIs preserves existing callback captures and
  validation calls while leaving all consumers in their current owners.
- Exact model-limit values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema timeline-feedback capability routing, selected in `5b92a765` and
implemented in `d5a9fec1`.
`schema.ex` moved from 6,187 to 6,188 lines; the existing
TimelineCapabilityContext owner moved from 34 to 36 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
