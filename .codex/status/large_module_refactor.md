# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner derived-branch generation boundary extraction.

Status:
Ready for implementation.

Selected slice:
Move the two private `maybe_add_derived_branches/6` clauses and their remaining
thin family wrappers from `CampaignPlanner` into a new internal
`CampaignPlanner.DerivedBranchOrchestration.merge/6` boundary.

Why this slice:
After the station extraction, `CampaignPlanner` is 2,023 lines with 144 private
functions. Repeated family extractions have made the remaining derived-branch
pipeline a cohesive V3 generation boundary composed almost entirely of
internal owners.

Current coupling/problem:
The public planner facade still owns derive-disabled handling, the complete
family ordering, final contact-intent deduplication, merge policy, and thin
wrappers for degraded/ground/feedback/link/fuel/target/latency/downlink
families.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
IDs/events/metadata, branch ordering and deduplication, scoring artifacts,
deterministic output, and all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/derived_branch_orchestration.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
Strategy normalization delegates derived-branch generation to
`DerivedBranchOrchestration.merge/6`; disabled behavior, exact family ordering,
deduplication, merge policy, public artifacts, and errors are unchanged;
focused and full planner tests match live baseline; strict compile and
independent review are clean.

Verification gaps:
- Focused and full planner baselines are pending.
- The full planner directory has five previously documented failures that must
  retain their exact observations.

Tests run:
- Live inventory: `CampaignPlanner` is 2,023 lines with 144 private functions.
- Target includes the two orchestration clauses and nine remaining thin family
  helpers.

Behavior/schema changes:
None.

Outcome:
No derived-branch boundary extraction has started.

Last completed slice:
Station-pressure derivation orchestration extraction published as `73737ad1`:
`CampaignPlanner` shrank from 2,064 to 2,023 lines; focused, file-backed, and
compile proof passed; independent review was clean. Handoff published as
`6ee115cf`.

Next candidate:
Publish this selection note, capture focused and full planner baselines, then
perform the mechanical generation-boundary extraction.

Blocked:
No.
