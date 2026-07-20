# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
CampaignPlanner repair communications policy direct routing.

Status:
Completed and pushed.

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
Removed the two one-hop CampaignPlanner repair communications helpers and
routed their consumers directly to DownlinkObjectiveRequirements and
ContactContentionResolutionPolicy. `campaign_planner.ex` moved from 1,049 to
1,041 lines.

Verification:
- Strict focused core planner, repair link-capacity, contact-allocation, and
  determinism baseline before routing: 9 passed.
- The same strict focused suite after routing: 9 passed.
- Strict adjacent missed-downlink, allocation-filter, resource-projection, and
  generated-refresh repair coverage: 13 passed.
- `mix xref callers` for DownlinkObjectiveRequirements and
  ContactContentionResolutionPolicy reports the expected CampaignPlanner
  orchestrator and existing internal consumers.
- Static search confirms both helper definitions and indirect calls are gone.
- `git diff --check` passed.
- Strict forced compile passed across 4,065 files.
- Implementation commit `fb3dfadc` pushed to `main`.

Behavior/schema changes:
None. Public CampaignPlanner APIs, required-downlink aggregation,
contact-contention policy, allocation report content, repair sequencing, and
deterministic artifacts remain unchanged.

Last completed slice:
CampaignPlanner repair communications policy direct routing, selected in
`6eb2e64d` and implemented in `fb3dfadc`.
`campaign_planner.ex` moved from 1,049 to 1,041 lines.

Next candidate:
Re-rank the remaining non-capability Schema responsibility clusters now that
direct domain capability reads have been removed from the facade.

Blocked:
No.
