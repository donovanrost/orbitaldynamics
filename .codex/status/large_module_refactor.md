# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair replacement-transition extraction.

Status:
Selected.

Selected slice:
Extract the complete missed-downlink and failed-observation replacement
transition branches into `RepairReplacementTransitions`.

Why this slice:
Identity, selection, and accumulator ownership are now explicit. Both
transitions can move whole—including no-candidate cancellation, replacement
metadata, deltas, approvals, warnings, and used-candidate tracking—without
callbacks or duplicating accumulator mutation.

Public facade to preserve:
`OrbitalDynamics.CampaignPlanner.repair/1`, exact repaired activities, deltas,
warnings, approvals, replacement metadata, candidate-diff metadata, and
deterministic ordering.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/repair_replacement_transitions.ex`
- `.codex/status/large_module_refactor.md`

Likely verification:
- focused missed-downlink, execution-policy, candidate-diff, and determinism families
- normalized transition-branch and accumulator-call audit
- compile, format, diff hygiene, and bounded review

Definition of done:
Both dispatch branches delegate to one transition owner; success and
no-candidate behavior, accumulator call order, metadata, warnings, approvals,
and ordering remain exact; focused tests pass; and bounded review finds no
blocker.

Outcome:
Pending.

Verification gaps:
- Pending.

Last completed slice:
CampaignPlanner repair replacement-selection extraction published as
`b0006439`: one owner now supplies the complete filter and deterministic sort
pipeline, 67 repair tests passed, the one broader failure was proven
pre-existing, and bounded review found no blocker.

Next candidate:
After replacement transitions, remap preservation/cancellation transitions;
extract only a complete responsibility family rather than isolated helpers.

Blocked:
No.
