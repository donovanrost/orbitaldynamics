# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair orchestration extraction.

Status:
Completed and pushed.

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
Added `RepairOrchestration` and moved the complete normalized repair
execution/report/artifact pipeline behind `run/1`. CampaignPlanner moved from
502 to 164 lines and now has no private functions; the new owner is 338 lines.

Verification:
- Strict focused core planner, determinism, generated-refresh,
  resource-projection, timeline-protection, and contact-allocation baseline
  before extraction: 21 passed.
- The same strict focused suite after extraction: 21 passed.
- Strict adjacent repair input/filter/source-report/downlink/station coverage:
  14 passed.
- Strict strategy-through-repair coverage: 6 passed.
- `mix xref callers` reports CampaignPlanner as the sole RepairOrchestration
  consumer and the new owner as the expected RepairExecution and RepairArtifact
  consumer.
- Static search confirms CampaignPlanner has no remaining private functions.
- Strict compile removed nineteen aliases that moved with the repair block.
- `git diff --check` passed.
- Strict forced compile passed across 4,070 files.
- Implementation commit `b94e90b1` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, helper clause order and guards, repair
sequencing, source-report defaults, policy decisions, score terms, reports,
warnings, artifacts, and deterministic output remain unchanged.

Last completed slice:
CampaignPlanner repair orchestration extraction, selected in `13845591` and
implemented in `b94e90b1`.
`campaign_planner.ex` moved from 502 to 164 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
