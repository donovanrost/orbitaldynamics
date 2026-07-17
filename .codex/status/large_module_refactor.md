# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair-accumulator mutation ownership cleanup.

Status:
Selected.

Selected slice:
Move activity insertion, replacement-ID tracking, and warning insertion into
`RepairAccumulator`; route transition code directly through its existing
delta, ambiguous-feedback, and approval APIs; remove six facade wrappers.

Why this slice:
The repair transition cluster cannot move cleanly yet because replacement
selection still shares scoring and candidate-diff helpers. Its accumulator
mutation boundary is complete, however: `RepairAccumulator` already owns delta
and approval construction, while the facade keeps six thin wrappers across 43
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
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner V1 build-artifact assembly extraction published as `af42dda3`:
all 34 fields and attachment order remained exact, every direct `build/2` test
file passed 36/36, and bounded review found no blocker.

Next candidate:
With accumulator ownership unified, remap the repair transition cluster and
replacement selection. Extract only if scoring, candidate-diff matching, and
timeline identity dependencies can move as a complete owner without callbacks.

Blocked:
No.
