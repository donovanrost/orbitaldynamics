# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection pressure-risk projection extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract row-to-policy-risk construction for storage overflow, downlink
shortfall, battery depletion, negative thermal margin, spacecraft
unavailability, and activity availability into
`OrbitalDynamics.ResourceProjection.PressureRisks`. Preserve all public
ResourceProjection report facades.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 2,504 lines, the largest
  eligible facade behind Schema, Timeline, MissionPlan.Activity, and the root
  public facade.
- The selected helper family spans lines 1,642-1,728 and exclusively converts
  an already-projected resource row into policy risk maps.
- Approval-policy application is the single consumer of the risk builder.
- Resource arithmetic, activity flow, first-event projection, pressure
  type/status classification, approval requirements, input normalization,
  public clauses, and artifact contracts remain outside this boundary.
- Existing risk order, severity, reason strings, units, numeric guards,
  activity-availability filtering, duplicate behavior, and empty-list behavior
  must remain unchanged.

Implementation:
- Pending.

Verification:
- Pending focused baseline, strict compilation, exact old/new public parity,
  focused and adjacent tests, static ownership checks, and xref review.

Behavior/schema changes:
None intended.

Last completed slice:
ContactContention resolution-summary values extraction, selected in
`4541dbd9` and implemented in `12e731f7`.
`communications/contact_contention.ex` moved from 2,509 to 2,466 lines; the
dedicated resolution-summary values owner is 71 lines.

Next candidate:
Complete and verify the selected ResourceProjection pressure-risk projection
extraction.

Blocked:
No.
