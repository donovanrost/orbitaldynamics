# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner source-plan ID direct routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner repair communications policy direct routing, selected in
`6eb2e64d` and implemented in `fb3dfadc`.
`campaign_planner.ex` moved from 1,049 to 1,041 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
