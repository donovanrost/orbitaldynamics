# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair candidate-refresh inheritance extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner source-plan ID direct routing, selected in `de4f069d` and
implemented in `7f901083`.
`campaign_planner.ex` moved from 1,041 to 1,037 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
