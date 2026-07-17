# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair activity-state transition extraction.

Status:
Published as `e99f5f3a`.

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
Added `RepairActivityStateTransitions` as the owner for ambiguous-feedback
review, degraded suppression, executed/locked/viable preservation, and
terminal cancellation. The facade now only dispatches these six state
branches; metadata construction and accumulator mutations move together. The
facade fell from 4,253 to 4,140 lines; the explicit 128-line owner makes the
bounded scope net +15 lines while removing 113 lines of mixed state-transition
responsibility from the facade.

Verification gaps:
- Strict compilation and diff hygiene pass.
- Repair execution-policy, realized-state, timeline-protection, ambiguity, and
  determinism families pass 67/67.
- All six branch bodies, metadata maps, accumulator call order, warning text,
  approval actions, and changed dispatch sites were audited against selection
  commit `d333ce84`.
- Independent bounded review found no blocker.

Last completed slice:
CampaignPlanner repair activity-state transition extraction published as
`e99f5f3a`: one owner now supplies six complete state branches, 67 repair tests
passed, and bounded review found no blocker.

Next candidate:
After activity-state transitions, add delayed-maneuver tracking to
`RepairAccumulator`, then reassess the complete maneuver/downstream-impact
transition boundary.

Blocked:
No.
