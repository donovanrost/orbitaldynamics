# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Campaign-planner branch candidate-refresh derivation extraction.

Status:
Ready for implementation.

Selected slice:
Move `derive_branch_candidate_refresh_request/2` and its exclusive refresh-input
helpers from `CampaignPlanner` into existing internal module
`CampaignPlanner.BranchCandidateRefresh`. Keep strategy entry points and result
artifacts unchanged.

Why this slice:
Live hotspot inventory shows `CampaignPlanner` remains 3,025 lines with 242
private functions while candidate-refresh and operator-review facades are
already 524 and 505 lines. The selected ~140-line cluster is cohesive, and all
of its helpers are used only by branch refresh derivation; underlying behaviors
already live in dedicated internal modules.

Current coupling/problem:
The public planner facade still assembles accepted state, targets, ground
network, policies, source reports, operational feedback, and resource summaries
for a branch refresh request despite `BranchCandidateRefresh` owning request
selection and execution.

Public facade to preserve:
`CampaignPlanner.strategy/1`, `strategy!/1`, file-backed entry points, branch
refresh request maps, candidate-refresh artifacts, deterministic ordering, and
all error behavior.

Likely files:
- `lib/orbital_dynamics/campaign_planner.ex`
- `lib/orbital_dynamics/campaign_planner/branch_candidate_refresh.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
`CampaignPlanner` passes `&BranchCandidateRefresh.derive/2` at both existing
call sites; derivation and exclusive helpers live in the internal module;
baseline request/artifact behavior is unchanged; focused and broader planner
tests pass to their live baseline; review finds no blocker.

Verification gaps:
- Implementation and post-change verification pending.
- One relevant baseline test is already stale on clean `d02cbca2`:
  `strategy_branch_generated_candidate_refresh_test.exs:269` reports current
  branch-local refresh-budget pressure as true while the assertion expects
  false. It must retain the same observed failure after extraction; do not
  redefine runtime behavior to satisfy the stale assertion in this slice.

Tests run:
- Exclusive-helper source counts: each supporting facade helper has one
  definition and one derivation use; `derive_branch_candidate_refresh_request`
  has three clauses and two callback captures.
- Focused five-test green subset covering branch execution, source paths, rich
  mission state, shared candidates, and branch overrides: 5 passed with warnings
  as errors.
- Full six-test pair baseline: 5 passed, 1 pre-existing stale assertion failed
  as described above.

Behavior/schema changes:
None.

Outcome:
No branch candidate-refresh extraction has started.

Last completed slice:
Policy-escalation ownership cleanup published as `109c7d4b`: `schema.ex` shrank
from 7,798 to 7,794 lines, focused 1 and complete 182 tests passed, all 122
exports byte-matched, and review was clean.

Next candidate:
Implement the internal derivation move mechanically, then compare the known
failing observation and run the five green focused cases.

Blocked:
No.
