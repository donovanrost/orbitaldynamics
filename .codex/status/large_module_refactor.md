# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest candidate-refresh accepted planning-state extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract accepted-planning-state selection, schema validation, mission-state
fallback construction, spacecraft-state completion, and orbit-data import
fallback into
`OrbitalDynamics.Study.Manifest.CandidateRefreshPlanningState`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,638 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of ResourceProjection,
  TimelineFeedback, ContactAllocation, RecommendationRiskContext,
  OrbitalDynamics, LinkCapacity, and StationCalendar.
- The selected family owns one candidate-refresh input responsibility reused
  by simulator and artifact-only manifest paths: resolving the authoritative
  accepted planning state from explicit, mission-state, or orbit-data inputs.
- Horizon, target/ground-station discovery, policies, activities, run options,
  schema generation, and manifest assembly remain outside this boundary.
- Existing source precedence, schema validation, mission-state defaults,
  identity completion, orbit-data errors, and missing/invalid classifications
  remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
StationCalendar availability and capacity normalization extraction, selected
in `6c271bee` and implemented in `8cf68232`.
`station_calendar.ex` moved from 3,655 to 3,487 lines; the dedicated
availability owner is 205 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
