# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair report owner direct routing.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner strategy owner direct routing, selected in `0aec9fda` and
implemented in `f1571f1c`.
`campaign_planner.ex` moved from 1,078 to 1,061 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
