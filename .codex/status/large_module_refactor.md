# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair orchestration extraction.

Status:
Selected; implementation not started.

Selected boundary:
Move `do_repair/1` and every remaining private repair helper into a new
internal `RepairOrchestration` module. Keep public `repair/1`, repair request
normalization, the ReplanRequest struct, helper clause order and guards, exact
errors, deterministic sequencing, and all repair artifact behavior unchanged.

Selection evidence:
- `campaign_planner.ex` is 502 lines after strategy orchestration extraction.
- Every remaining private function from line 190 through EOF belongs to the
  normalized repair execution/report/artifact pipeline.
- The block already composes focused owners such as RepairExecution,
  RepairScoreTerms, RepairSourceReports, RepairTimelineSummary, and
  RepairArtifact; moving the orchestration preserves those boundaries.
- Exact source-report defaults, policy decisions, score terms, reports,
  warnings, artifact content, and deterministic output must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner strategy orchestration extraction, selected in `a0d60531` and
implemented in `e39f726b`.
`campaign_planner.ex` moved from 601 to 502 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
