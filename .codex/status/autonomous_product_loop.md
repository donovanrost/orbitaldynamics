# Autonomous Product Loop Status

Overall maturity target:
Level 6 mature operational-planning platform across library, LEO campaign
planning, and Cadence-facing operational-planning surfaces.

Current slice:
Canonicalize collection-latency objective aliases across standalone
CandidateRefresh and V3 objective replay.

Status:
Implemented and verified; publish pending.

Why this slice:
The live checkout had a split semantic contract. Standalone CandidateRefresh
accepted provider-style collection-latency labels that V3 mission objectives
did not, V3 accepted mission-style labels that standalone refresh did not, and
report-driven V3 objective-satisfaction pressure accepted only literal
`collection_latency`. Equivalent provider/review inputs could therefore remain
visible in provenance while silently failing to create the same decision.

Level 6 pillar:
Refreshed candidates from current mission state plus stable, interoperable
operational artifacts whose equivalent inputs have equivalent semantics.

Behavior/evidence added:
- Added one shared six-label collection-latency objective contract:
  `collection_latency`, `collection_downlink_latency`, `data_latency`,
  `downlink_latency`, `max_collection_latency`, and
  `collection_latency_limit`.
- Standalone CandidateRefresh applies every alias to matching observation and
  downlink candidates, including latency context and required volume.
- V3 mission objectives accept the same aliases and emit canonical
  `objective_type: collection_latency` decision events.
- Objective-satisfaction direct reports, result/review/import-derived source
  objectives, pressure branches, and objective-gap summaries share the same
  classification instead of maintaining divergent lists.
- A provider `Data Latency` row with `Needs Replan` status now derives a real
  canonical latency branch and a 40 MB refreshed downlink while preserving the
  source report path, normalized provider status, and trust boundary.
- A `Collection Latency Limit` source-report row becomes an executable
  canonical objective; the objective-gap summary still records the original
  normalized source label for audit.
- Capability and artifact docs now state the cross-ingress alias guarantee and
  canonical event behavior.

Verification:
- Focused alias/source/V3 integration suites: 47 passed.
- CandidateRefresh and CampaignPlanner objective suites: 133 passed.
- Candidate/strategy schema suites: 35 passed.
- Full `mix test --timeout 180000`: 3,480 passed.
- Schema lint: 155 artifacts, zero errors/warnings.
- `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
  `git diff --check`: pass.

Parent review:
Complete. The parent inspected the shared contract, every consumer boundary,
canonical event output, source-label audit preservation, V3 candidate impact,
schema validation, docs, and regression coverage. The initially exposed
mission-objective event-label drift was fixed before the full gate. No must-fix
findings remain. Runtime policy disallows subagent delegation, so the parent
performed review and publish prep.

Previous published slice:
- `dbcf90d2` Harden allocation wrapper selection contract (`3477 passed`).

Current publish:
- Commit pending.

Remaining maturity gaps:
- Continue richer objective semantics beyond deterministic count/volume gaps.
- Continue calibrated realized-feedback depth and challenge fixtures.
- Continue deeper numerical/backend and resource-model maturity separately.

Blocked:
Not blocked. Runtime policy disallows subagent delegation, so the parent will
perform bounded review and publish handoff.
