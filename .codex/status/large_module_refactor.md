# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner source-plan ID direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove the one-hop CampaignPlanner source-plan ID helper. Route its four
strategy and repair call sites directly to `RepairMetadata.source_plan_id/1`.
Keep ID fallback semantics, manifest metadata, score-timeline construction,
strategy artifact construction, public CampaignPlanner APIs, and the owner API
unchanged.

Selection evidence:
- `campaign_planner.ex` remains 1,041 lines after the repair communications
  slice.
- The helper delegates to the same-arity owner API without guards, defaults,
  transformation, caching, or shared facade state.
- StrategyBranchEvaluation and RepairArtifact already call the owner directly,
  so the owner is an established shared planning identity boundary despite its
  historical module name.
- Exact plan-ID fallbacks, generated manifest IDs, provenance, repair and
  strategy artifact content, and deterministic output must remain unchanged.

Implementation:
Removed the one-hop CampaignPlanner source-plan ID helper and routed all four
strategy and repair call sites directly to RepairMetadata.
`campaign_planner.ex` moved from 1,041 to 1,037 lines.

Verification:
- Strict focused core planner, repair determinism/generated refresh, and
  strategy branch-repair baseline before routing: 11 passed.
- The same strict focused suite after routing: 11 passed.
- Strict adjacent repair input/source-report and strategy
  candidate/recommendation coverage: 13 passed.
- `mix xref callers OrbitalDynamics.CampaignPlanner.RepairMetadata` reports
  the expected CampaignPlanner, RepairArtifact, and StrategyBranchEvaluation
  consumers.
- Static search confirms the helper definition and all indirect calls are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `7f901083` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, plan-ID fallbacks, manifest IDs and
metadata, score timelines, repair/strategy artifacts, and deterministic output
remain unchanged.

Last completed slice:
CampaignPlanner source-plan ID direct routing, selected in `de4f069d` and
implemented in `7f901083`.
`campaign_planner.ex` moved from 1,041 to 1,037 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
