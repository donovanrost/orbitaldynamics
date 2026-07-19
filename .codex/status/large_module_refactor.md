# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Manifest candidate-refresh run-input source extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract candidate-refresh accepted-state, target, and ground-station run-input
source discovery across explicit inputs, mission-state catalogs/objectives,
ground-network geometry, and orbit data into
`OrbitalDynamics.Study.Manifest.CandidateRefreshRunInputSources`.
Preserve the existing Manifest public API facade.

Selection evidence:
- Live re-ranking places `manifest.ex` at 3,530 lines, fourth behind Schema,
  Timeline, and MissionPlan.Activity and ahead of LinkCapacity,
  StationCalendar, TimelineFeedback, ResourceProjection, ContactAllocation,
  RecommendationRiskContext, and OperationalReadiness.
- The selected family owns one provenance responsibility used by
  candidate-refresh manifest metadata: declaring which accepted-state,
  target, and ground-station inputs were actually present.
- Candidate-refresh planning-state resolution, target/ground-station parsing,
  scenario construction, policies, activities, schema generation, and manifest
  assembly remain outside this boundary.
- Existing source vocabulary and ordering, geometry-presence rules,
  explicit-versus-mission-state inclusion behavior, empty-list handling, and
  deterministic output remain unchanged.

Verification:
Pending.

Behavior/schema changes:
None intended. This is a facade-preserving production ownership extraction.

Last completed slice:
OrbitalDynamics activity-template catalog extraction, selected in `599aa35d`
and implemented in `c122fda2`.
`orbital_dynamics.ex` moved from 3,572 to 2,951 lines; the dedicated
activity-template catalog owner is 646 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
