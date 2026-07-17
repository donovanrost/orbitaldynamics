# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair maneuver timing-impact extraction.

Status:
Selected.

Selected slice:
Extract delayed-maneuver movement and downstream activity-impact annotation
into `RepairManeuverTransitions`.

Why this slice:
Accumulator ownership is now complete. Movement, delay calculation, maneuver
tracking, downstream matching, metadata annotation, approvals, and warnings
form one closed timing-impact responsibility with no callbacks.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
delayed-maneuver tracking, downstream annotations, warnings, approvals, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_maneuver_transitions.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused delayed-maneuver and determinism families
- normalized movement/downstream branch and accumulator-call audit
- compile, format, diff hygiene, and bounded review

Definition of done:
Both facade call sites delegate to one timing-impact owner; delay calculation,
metadata, affected-activity matching, accumulator call order, warnings,
approvals, and ordering remain exact; focused tests pass; and bounded review
finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
RepairAccumulator delayed-maneuver mutation ownership published as
`e36c06fd`: all repair-accumulator mutation is now owner-local, 16 focused
tests passed, and corrected bounded review found no blocker.

Next candidate:
After maneuver transitions, remap the remaining repair dispatch/protection
helpers and stop this lane if no cohesive callback-free owner remains.

Blocked:
No.
