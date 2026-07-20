# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair report owner direct routing.

Status:
Completed and pushed.

Selected boundary:
Remove three one-hop CampaignPlanner repair helpers for timeline protection,
operational-readiness source reports, and quality-gate source reports. Route
their three repair-orchestration call sites directly to RepairTimelineSummary
and RepairSourceReports. Keep guarded/defaulting candidate-refresh adapters,
repair sequencing, score-term argument order, public CampaignPlanner APIs, and
all owner APIs unchanged.

Selection evidence:
- `campaign_planner.ex` remains 1,061 lines after the strategy owner slice.
- All three helpers delegate to same-arity owner APIs without guards, defaults,
  transformation, caching, or shared facade state.
- Each helper has exactly one repair-orchestration consumer.
- Exact timeline protection, readiness/quality source rows, score terms,
  repair artifact content, and deterministic output must remain unchanged.

Implementation:
Removed the three one-hop CampaignPlanner repair-report helpers and routed
their orchestration call sites directly to RepairTimelineSummary and
RepairSourceReports. `campaign_planner.ex` moved from 1,061 to 1,049 lines.

Verification:
- Strict focused core planner, repair source-report, determinism, and timeline
  protection baseline before routing: 13 passed.
- The same strict focused suite after routing: 13 passed.
- Strict adjacent repair filter, generated-refresh, resource-projection, and
  contact-allocation coverage: 12 passed.
- `mix xref callers` for RepairTimelineSummary and RepairSourceReports reports
  the expected CampaignPlanner orchestrator and existing repair modules.
- Static search confirms all three helper definitions and indirect calls are
  gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `3293d85c` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, repair sequencing, timeline protection,
readiness/quality source rows, score terms, and deterministic artifacts remain
unchanged.

Last completed slice:
CampaignPlanner repair report owner direct routing, selected in `6a2ae37b` and
implemented in `3293d85c`.
`campaign_planner.ex` moved from 1,061 to 1,049 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
