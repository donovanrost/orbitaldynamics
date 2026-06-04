# Branch Derivation and Artifact Output

When branch derivation is enabled, V3 appends deterministic branches for:

- degraded spacecraft in `mission_state.spacecraft_states` or
  `mission_state.degradations`,
- unavailable or reduced-capacity ground-network entries,
- low fuel margin or explicit fuel-preservation objectives,
- high-priority unscheduled urgent targets,
- target-coverage objectives for uncovered requested targets, including
  objective time-window bounds, scoped planned-observation counts, explicit
  `target_id` / `target_ids` / `required_target_ids` selectors, and inline
  target latitude/longitude specs, with normalized per-target branch events
  preserving coverage objective IDs, scenario scopes, candidate windows, and
  spacecraft constraints,
- target-revisit objectives that need additional observations,
- collection-latency objectives that need one or more follow-on downlinks or a
  minimum downlink data volume inside the latency window, preserving objective
  identity when multiple latency objectives apply to the same observation,
- downlink-constrained plans when required completion is at risk. If the gap is
  a missing contact count, V3 can use branch-generated access candidates as
  validated strategic additions; if the risk is low storage margin, V3 uses the
  same validated-addition path as downlink relief; if the prior selected plan
  already contains provider-shaped station/time contacts, V3 counts the
  canonicalized downlinks before deriving gap branches or no-viable-downlink
  risks; if the risk is low downlink margin, V3 records reduced capacity
  assumptions.

Explicit caller-provided branches are preserved, derived branches are appended
in stable order, optional combined derived branches are added only when at
least two individual branches were derived, combined events retain source
branch lineage, and duplicate branch IDs are removed deterministically.

The V3 artifact includes:

- `mission_state_snapshot`.
- `branches`, each with `candidate_plan`, nested V2 `repair_result`,
  `score_terms`, `warnings`, `risk_indicators`, `approval_status`,
  `approval_requirements`, `approval_rule_matches`, `derived_source`,
  `resource_impacts`, optional `resource_projection_report`, `feedback_adjustments`,
  `objective_satisfaction`, `feasibility_summary`, `assumptions`, and
  `provenance`.
- `branch_comparison_report.v1` rows flatten branch resource-projection
  pressure fields, including peak storage overflow, peak downlink shortfall,
  flow-row count, the first activity that creates resource pressure, and
  spacecraft IDs/counts for unavailable spacecraft, payload-unavailable,
  degraded-payload, and antenna-unavailable availability pressure. They also
  carry repaired link-capacity requirement evidence, including required downlink
  volume, selected downlink shortfall, realized completion ratio, and
  requirement status, plus repaired constraint counts/statuses, through
  operator-review and Cadence import rows.
- Branch `risk_indicators` promote projected storage overflow and downlink
  shortfall from the nested resource projection report into branch-level
  `storage_overflow` and `downlink_shortfall` risks, so default V3 approval
  policy can block resource-pressure futures before recommendation selection.
  Executable validation checks branch risk rows for required type, severity,
  reason, optional numeric or boolean value, and stable station/spacecraft/target
  IDs.
  Station-derived risks such as outages, reservations, reduced capacity, and
  provider feedback preserve canonical `ground_station_id` evidence, including
  provider-shaped `station_id` inputs, for station-scoped policy matches.
  Resource and availability risks preserve `spacecraft_id` evidence for
  spacecraft-scoped policy matches, and branch-comparison rows flatten
  unavailable-spacecraft, payload-unavailable, degraded-payload, and
  antenna-unavailable counts and IDs from branch resource projections for review
  queues. Target-feedback and urgent-target risks preserve `target_id` evidence
  for target-scoped policy matches.
- `recommendation` with the selected branch, ranked branch IDs, reason,
  tradeoffs, structured explanation, remaining risks, and required approvals.
  Tradeoff rows carry deterministic numeric deltas for expected score, mission
  value, coverage, revisit, latency, downlink completion, fuel preservation,
  asset balance, resource score, feedback adjustment, risk count, approval
  count, and schedule stability. Explanation rows also surface the selected
  branch's first resource-projection pressure activity, pressure kind, start
  time, and peak storage-overflow or downlink-shortfall values when projected
  activity flow creates resource pressure, including contact direction,
  ground-station, station-calendar entry, provider, provider-entry, and
  station-calendar direction context when the pressure starts in a contact row.
  When projected activity effects are
  suppressed because a resource summary declares the spacecraft unavailable, the
  same recommendation surface emits `pressure_kind: spacecraft_unavailable`
  with spacecraft ID and resource-pressure status/type evidence. If repaired
  link capacity remains below the selected branch's required downlink volume,
  explanation rows also
  carry required volume, selected adjusted throughput, shortfall, requirement
  status, and selected contact IDs. `strategy_recommendation.v1` executable
  validation checks these explanation rows for stable IDs, typed numeric
  evidence, boolean risk values, and the stable activity/scenario,
  station/spacecraft/target IDs carried by risk-driver rows. Command-feedback
  risks therefore preserve the command activity and scenario that produced the
  low-success evidence. The strategy-recommendation operator-review row and
  selected Cadence import gate also flatten risk type plus activity, scenario,
  station, spacecraft, and target ID arrays for queue routing. Strategic-addition
  rows carry the same repair reason used by approval requirements.
- `strategy_policy`, `approval_policy`, `operational_feedback`, assumptions,
  provenance, and deterministic `strategy_metadata.strategy_id`.
