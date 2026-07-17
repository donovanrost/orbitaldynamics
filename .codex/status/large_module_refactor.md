# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair replacement-selection extraction.

Status:
Selected.

Selected slice:
Extract replacement filtering, repair-intent matching, duplicate rejection,
candidate-diff priority, and deterministic churn scoring into
`RepairReplacementSelection`.

Why this slice:
The identity and accumulator slices removed the facade-only dependencies from
this cluster. Its remaining closure is now cohesive and can call existing
timing, identity, policy, candidate-diff, and scalar helpers directly without
callbacks; unrelated strategy-side candidate-diff lookup can remain outside.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
selected replacement candidates, candidate-diff metadata, churn scoring, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_replacement_selection.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused repair replacement, rejection, candidate-diff, and determinism families
- normalized selection-pipeline and sort-key audit
- compile, format, diff hygiene, and bounded review

Definition of done:
Both downlink and observation replacement paths delegate to one owner; the
filter and sort pipeline remains exact; candidate-diff ambiguity and metadata
remain exact; focused tests pass; and bounded review finds no blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair activity-identity ownership extraction published as
`6a51d53b`: one owner now supplies repair timeline/context/station/window
identity, the bounded scope is net -33 lines, 94 focused tests passed, and
bounded review found no blocker.

Next candidate:
After replacement selection, remap the two successful repair-transition
metadata branches and extract only if their action-specific construction can
move without obscuring accumulator ownership.

Blocked:
No.
