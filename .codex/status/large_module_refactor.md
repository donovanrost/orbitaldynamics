# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RepairAccumulator delayed-maneuver tracking ownership.

Status:
Selected.

Selected slice:
Move the final direct `:delayed_maneuvers` accumulator mutation behind
`RepairAccumulator.track_delayed_maneuver/3`.

Why this slice:
All other repair accumulator mutation is owner-local. This exact prepend is the
only remaining facade mutation and is the prerequisite for moving the complete
delayed-maneuver/downstream-impact transition without split ownership.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
delayed-maneuver tracking, downstream annotations, warnings, approvals, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_accumulator.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused delayed-maneuver and determinism families
- exact mutation and call-site audit
- compile, format, diff hygiene, and bounded review

Definition of done:
No direct repair-accumulator mutation remains outside its owner; delayed
maneuver entry shape and prepend order remain exact; focused tests pass; and
bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair activity-state transition extraction published as
`e99f5f3a`: one owner now supplies six complete state branches, 67 repair tests
passed, and bounded review found no blocker.

Next candidate:
Extract the complete delayed-maneuver movement and downstream-impact family
once accumulator ownership is unified.

Blocked:
No.
