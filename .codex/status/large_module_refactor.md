# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection pressure-risk projection extraction.

Status:
Completed and pushed.

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
- Selection was recorded and pushed in `351c84ce`.
- Implementation was committed and pushed in `5dd9dd79`.
- `resource_projection.ex` moved from 2,504 to 2,418 lines.
- `OrbitalDynamics.ResourceProjection.PressureRisks` is a 91-line owner
  reached through a private facade delegate.

Verification:
- Strict warning-clean compilation passed across 3,964 files.
- The focused ResourceProjection file and five adjacent review, strategy,
  replay-routing, Cadence-import, and schema consumers passed together:
  137 tests.
- Exact old/new public parity passed for 8 cases covering combined storage,
  downlink, battery, and thermal pressure; spacecraft unavailability;
  payload/antenna unavailability; nominal and empty projections; report
  passthrough; and public-error behavior.
- `mix xref callers` reports only the ResourceProjection facade.
- The removed risk helpers are absent from the facade apart from the thin
  delegate, formatting and `git diff --check` passed, and the final diff is
  ownership-only.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceProjection pressure-risk projection extraction, selected in
`351c84ce` and implemented in `5dd9dd79`.
`resource_projection.ex` moved from 2,504 to 2,418 lines; the dedicated
pressure-risk owner is 91 lines.

Next candidate:
Re-rank the live checkout and select the next cohesive facade-preserving
boundary.

Blocked:
No.
