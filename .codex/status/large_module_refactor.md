# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
RepairAccumulator delayed-maneuver tracking ownership.

Status:
Published as `e36c06fd`.

Selected slice:
Move the delayed-maneuver tracking and downstream activity-replacement
mutations behind `RepairAccumulator`.

Why this slice:
Delayed-maneuver tracking and downstream activity replacement were the two
remaining facade mutations. Owning both is the prerequisite for moving the
complete delayed-maneuver/downstream-impact transition without split
ownership.

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
Added `RepairAccumulator.track_delayed_maneuver/3` and
`replace_activities/2`, then routed delayed tracking and downstream activity
replacement through them. Entry shape, prepend order, and activity ordering
are unchanged, and no direct repair-accumulator mutation remains in the
facade. The facade fell from 4,140 to 4,138 lines and the owner grew from 206
to 215; the bounded scope is net +7 lines for the explicit ownership boundary.

Verification gaps:
- Strict compilation and diff hygiene pass.
- Delayed-maneuver execution-policy, timeline-protection, and determinism
  families pass 16/16.
- Both mutation bodies and call sites were audited against selection commit
  `8f4ad796`; entry shape, prepend order, and activity ordering are unchanged.
- Independent review's ownership finding was corrected; re-review found no
  blocker.

Last completed slice:
RepairAccumulator delayed-maneuver mutation ownership published as
`e36c06fd`: all repair-accumulator mutation is now owner-local, 16 focused
tests passed, and corrected bounded review found no blocker.

Next candidate:
Extract the complete delayed-maneuver movement and downstream-impact family
once accumulator ownership is unified.

Blocked:
No.
