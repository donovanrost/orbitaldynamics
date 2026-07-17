# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair-accumulator mutation ownership cleanup.

Status:
Published as `0f91bc40`.

Selected slice:
Move activity insertion, replacement-ID tracking, and warning insertion into
`RepairAccumulator`; route transition code directly through its existing
delta, ambiguous-feedback, and approval APIs; remove six facade wrappers.

Why this slice:
The repair transition cluster cannot move cleanly yet because replacement
selection still shares scoring and candidate-diff helpers. Its accumulator
mutation boundary is complete, however: `RepairAccumulator` already owns delta
and approval construction, while the facade keeps six thin wrappers serving 37
call sites. Consolidating those mutations removes split ownership without
callbacks or semantic movement.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
approval requirements, used replacement IDs, warnings, and deterministic
ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_accumulator.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused repair facade and repair activity-transition families
- exact call-site and removed-wrapper audit
- compile, format, diff hygiene, and bounded review

Definition of done:
All accumulator mutations route through one owner with call arguments and
pipeline order unchanged; repaired artifacts and ordering remain exact; focused
tests pass; and bounded review finds no blocker.

Outcome:
All 37 repair-transition mutation calls now route directly through
`RepairAccumulator`. It additionally owns activity insertion, replacement-ID
tracking, and warning insertion; its existing delta, ambiguous-feedback, and
approval functions are called without facade wrappers. The facade shrank from
4,568 to 4,540 lines and the accumulator grew from 237 to 250 lines, for a net
15-line reduction with one mutation owner.

Verification gaps:
- Normalized AST audit: all fourteen repair-transition clauses are exact after
  removing only the `RepairAccumulator` qualification.
- All six facade wrappers and all unqualified transition mutation calls are
  absent.
- `mix compile --warnings-as-errors` passed.
- Repair, repair-adjacent constraint/file facade, and strategy-baseline tests
  passed 67/67.
- `mix format --check-formatted` and `git diff --check` passed.
- Independent bounded review found no blocker and accounted for all 34
  qualified calls plus the three moved primitive mutation bodies.

Last completed slice:
CampaignPlanner repair-accumulator mutation ownership cleanup published as
`0f91bc40`: all 37 mutation points remained exact, repair-family tests passed
67/67, and bounded review found no blocker.

Next candidate:
With accumulator ownership unified, remap the repair transition cluster and
replacement selection. Extract only if scoring, candidate-diff matching, and
timeline identity dependencies can move as a complete owner without callbacks.

Blocked:
No.
