# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair candidate-refresh inheritance extraction.

Status:
Completed and pushed.

Selected boundary:
Move the cohesive repair candidate-refresh inheritance cluster into a new
internal `RepairCandidateRefreshInheritance` module. The owner will preserve
approval-policy inheritance, mission-state and accepted-state defaults, target
synthesis, ground-station inheritance, and empty-value handling behind one
`inherit/4` call. Keep normalization order, nil/empty guards, public
CampaignPlanner APIs, and all artifact behavior unchanged.

Selection evidence:
- `campaign_planner.ex` remains 1,037 lines after source-plan ID routing.
- The cluster spans approval inheritance, mission-state inheritance, two
  synthesized inputs, manifest ground stations, and one private empty-value
  helper; none are used outside this flow.
- BranchRefreshAcceptedState, BranchRefreshTargets, and
  BranchRefreshGroundNetwork aliases are used only by this cluster and move
  with it.
- Exact approval precedence, empty-mission-state behavior, accepted planning
  state, targets, ground stations, generated refresh inputs, and deterministic
  artifacts must remain unchanged.

Implementation:
Added `RepairCandidateRefreshInheritance` and moved the complete approval,
mission-state, synthesized-input, manifest-input, and empty-value cluster
behind `inherit/4`. CampaignPlanner now has one delegation call and moved from
1,037 to 952 lines; the new owner is 98 lines.

Verification:
- Strict focused core planner, generated-refresh, repair-input, and
  candidate-refresh source-report baseline before extraction: 13 passed.
- The same strict focused suite after extraction: 13 passed.
- Strict adjacent candidate-refresh filter, determinism, and missed-downlink
  repair coverage: 8 passed.
- `mix xref callers` reports CampaignPlanner as the sole
  RepairCandidateRefreshInheritance consumer and the new owner as the expected
  additional consumer of its three BranchRefresh dependencies.
- Static search confirms the inheritance cluster, empty-value helper, and
  moved aliases are gone from CampaignPlanner.
- `git diff --check` passed.
- Strict forced compile passed across 4,066 files.
- Implementation commit `727bad87` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, approval precedence, nil/empty guards,
accepted planning state, targets, ground stations, generated refresh inputs,
and deterministic artifacts remain unchanged.

Last completed slice:
CampaignPlanner repair candidate-refresh inheritance extraction, selected in
`f7918ecb` and implemented in `727bad87`.
`campaign_planner.ex` moved from 1,037 to 952 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
