# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-state transition extraction.

Status:
Selected.

Selected slice:
Extract ambiguous-review, degraded-suppression, executed/locked/viable
preservation, and terminal-cancellation branches into
`RepairActivityStateTransitions`.

Why this slice:
These non-timing state transitions share a closed dependency set and can move
whole without callbacks. Delayed-maneuver movement and downstream annotation
remain separate because they form a timing-impact responsibility and still
need explicit accumulator ownership for delayed-maneuver tracking.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
warnings, approvals, repair metadata, realized-feedback review rows, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_activity_state_transitions.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused execution-policy, realized-state, timeline-protection, and determinism families
- normalized state-branch, metadata, and accumulator-call audit
- compile, format, diff hygiene, and bounded review

Definition of done:
All six state branches delegate to one owner; metadata, accumulator call order,
warning and approval behavior, realized-feedback handling, and ordering remain
exact; focused tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair replacement-transition extraction published as
`73a32081`: one owner now supplies both complete replacement branches, 67
repair tests passed, and bounded review found no blocker.

Next candidate:
After activity-state transitions, add delayed-maneuver tracking to
`RepairAccumulator`, then reassess the complete maneuver/downstream-impact
transition boundary.

Blocked:
No.
