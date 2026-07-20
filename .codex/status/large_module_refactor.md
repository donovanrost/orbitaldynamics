# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair communications policy direct routing.

Status:
Selected; implementation not started.

Selected boundary:
Remove two one-hop CampaignPlanner repair communications helpers for downlink
completion objectives and contact-contention resolution policy. Route their
single consumers directly to DownlinkObjectiveRequirements and
ContactContentionResolutionPolicy. Keep objective value guards, link-policy
aggregation, contact-allocation options, repair sequencing, public
CampaignPlanner APIs, and all owner APIs unchanged.

Selection evidence:
- `campaign_planner.ex` remains 1,049 lines after the repair-report slice.
- Both helpers delegate to same-arity owner APIs without guards, defaults,
  transformation, caching, or shared facade state.
- Each helper has exactly one repair communications consumer.
- Exact required-downlink aggregation, contact-contention policy, allocation
  report content, repair artifact content, and deterministic output must remain
  unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
CampaignPlanner repair report owner direct routing, selected in `6a2ae37b` and
implemented in `3293d85c`.
`campaign_planner.ex` moved from 1,061 to 1,049 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
