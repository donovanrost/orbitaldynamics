# Overview and Strategy API

The first V3 implementation was a deterministic branch-comparison layer over V2
repair. It accepted a living mission-state snapshot, evaluated explicit future
branches from the same source plan, ran V2 repair inside each branch, scored
campaign-level tradeoffs, and emitted a recommended strategy with approval
boundaries.

The current V3 feature-completeness pass keeps that artifact-first boundary but
turns the strategy layer into a more useful mission-orchestration slice. It can
derive default branches from mission state, feed mission-state spacecraft
degradations into V2 repair, score thin resource and operational-feedback
models, classify approvals through `OrbitalDynamics.Policy`, emit
`policy_decision.v1` records for each branch, accept branch-specific
`candidate_refresh.v1` artifacts or executable `candidate_refresh_request`
manifests when different futures need different candidate sets,
feasibility-check urgent target additions against candidate windows, and
explain recommendations in operator-facing terms.

The public API is `OrbitalDynamics.CampaignPlanner.strategy/1`. It accepts a map
with:

- `prior_plan`: a V1 `campaign_plan`, or a V2 repair artifact that carries
  `source_candidate_activities`, used as the common source.
- `mission_state`: a `%MissionState{}` or map containing spacecraft state,
  operational status, resource summaries, known degradations, ground-network
  availability, campaign objectives, prior plan history, optional
  `operational_feedback` or `timeline_feedback_report` realized-feedback
  handoff data, candidate-refresh defaults, target/station catalogs, and
  assumptions.
- `realized_state`: optional Cadence-sourced realized operations snapshot.
- `branches`: optional explicit what-if branches. A baseline branch plus useful
  mission-state-derived branches can be generated when branch derivation is
  enabled.
- branch-level `candidate_refresh`: optional `candidate_refresh.v1` artifact.
  When present, it overrides the shared strategy refresh input for that branch
  and is recorded in branch assumptions/provenance as `scope: "branch"`.
- branch-level `candidate_refresh_request`: optional executable refresh manifest
  or candidate-refresh request map. The request may carry either
  `accepted_planning_state` or simple `orbit_data` state estimates. When
  present, V3 runs it through the same study pipeline that backs
  `candidate_refresh.v1`, then feeds the generated refresh artifact into branch
  repair and records `scope: "branch_generated"`. Orbit-data inputs can also be
  bridged through the narrow CCSDS OPM KVN import/export adapter when a
  compatibility test needs a real flight-dynamics interchange shape.
- mission-state-derived refresh: when no branch refresh artifact or request is
  supplied, V3 can derive a branch refresh request from branch events if
  `mission_state` includes accepted planning-state data plus enough
  ground-station or target catalog metadata to run the sampled event detectors.
  When both `ground_stations` and `ground_network` provide geometry for the same
  station ID, `ground_stations` is treated as the station-definition source and
  calendar/network geometry is used only as a fallback for IDs without a
  definition.
- `current_epoch_s` and `remaining_horizon`.
- `derive_branches` or `branch_generation_policy`: enables deterministic branch
generation from mission-state degradation, ground-network, resource, urgent
objective, target-revisit, priority-commitment, downlink-risk, and direct
planned-activity or operational-timeline feedback inputs.
Mission-state objective type tokens are canonicalized from `type`,
`objective_type`, or `objective` fields before branch derivation, accepting
provider-style casing, whitespace, hyphens, and atom values so `target revisit`
and `target-revisit` replay as executable `target_revisit` refreshes.
Delivery-latency objective aliases such as `Max Delivery Latency` and
`max_delivery_latency_s` likewise normalize into collection-latency branch
refreshes.
Downlink-completion objectives accept provider contact-count aliases such as
`required_contact_count`, `expected_contact_count`, and required contact ID
lists before branch-local refresh, so generated downlink additions satisfy the
declared contact demand instead of falling back to one contact.
Target-revisit objectives can request multiple observations; V3 stages
non-overlapping validated candidate windows first and uses an
  approval-required placeholder only for the remaining unmet observation count
  when placeholders are allowed. Validated urgent-target additions also preserve
  any semantic candidate-diff replacement row from their source refresh before
  staging rewrites the branch-local activity ID, and repair metadata uses
  objective-specific reasons for priority commitments, target coverage, target
  revisit, feedback, and urgent-target sources. Downlink strategic additions
  likewise distinguish downlink-completion, collection-latency relief, storage
  relief, and downlink-margin pressure reasons. Unscheduled priority
  commitments can derive refresh-backed branches even when they are not
  explicitly marked urgent. When a strategic addition carries that diff context,
  V3 includes it in recommendation explanation rows and
  `operator_review_package.v1` approval rows, preserving ambiguity metadata
  when multiple diff rows point at the same replacement candidate.
  `branch_generation_policy.combine_derived_branches` can also add one
  aggregate `derived_combined_mission_state` branch that combines the individual
  derived events for joint-case review; each combined event carries
  `source_branch_id` / `source_branch_ids` so operators can trace it back to
  the individual derived branch that produced it, and branch-comparison rows
  summarize event counts, event types, combined source branch IDs, and
  branch-event station/calendar/provider/reservation context for review/import
  handoff. When the selected recommendation carries branch
  events, its explanation includes a `branch_event_summary` row with the same
  count/type and combined-source evidence. Strategy tradeoff review/import rows
  also flatten those fields for queue routing while preserving the full source
  branch-comparison row.
- `strategy_policy`, `approval_policy`, `repair_policy`, and `scoring_policy`.
- optional `operational_feedback` calibration maps.
  `station_throughput_factor` also feeds generated branch refreshes as
  ground-network capacity factors, so refreshed downlink candidates carry the
  reduced throughput assumption instead of only changing branch score terms.
  Branch-generated refresh manifests preserve that operational-feedback
  provenance so the same throughput factor is not applied twice.
  Explicit branch-local feedback events for station throughput, contact
  success, observation success, target priority, and command success are also
  folded into generated branch refresh requests, which lets a hand-authored
  what-if branch affect refreshed candidates without supplying a prebuilt
  `candidate_refresh.v1` artifact. Branch feedback score and risk evidence use
  the same branch-local feedback merge, so branch-comparison rows expose the
  confidence factors and source labels used by the generated candidates.
  Objective-tradeoff latency rows can also derive branch-local downlink-refresh
  pressure from nested source-observation target, collection, product, payload,
  instrument, collection-end, deadline, latency, and data-volume evidence instead of
  requiring every provider adapter to flatten that routing metadata first.
  Mission-state collection-latency objectives use the same provider-shaped data
  identity selectors (`collection`, `product`/`data_product`, `products`,
  `payload`, and `instrument`) before branch-local refresh, and staged downlink
  additions expose canonical identity fields for Cadence import routing. When
  the objective declares multiple products, branch events keep the matched
  source-observation product in `product_id` while preserving the full selector
  list in `product_ids`; downlink-completion events without a source
  observation omit singular data-identity fields for broad selector sets and
  keep normalized plural evidence in `collection_ids`, `product_ids`,
  `payload_ids`, and `instrument_ids`. Score-term and objective-satisfaction
  downlink or collection-latency pressure replay preserves those same plural
  selector lists in derived branch events, risk rows, and branch-comparison
  summaries, and staged downlink additions retain the triggering selector lists
  and plural objective IDs in their feasibility context plus approval and selected-recommendation
  handoff rows, including provider-shaped nested `collections`,
  `products`/`data_products`, `payloads`, and `instruments` object lists.
  Operator-review and Cadence-import rows preserve those labels for handoff
  audit. Top-level,
  mission-state, and branch-local success/throughput feedback factors are
  clamped to the same `[0, 1]` planning range used by refreshed candidate rows.
  Mission-state realized contact or observation rows may omit station, target,
  type, or expected-throughput context when their identity matches a prior
  activity, candidate, or proposed contact row by `id`, `activity_id`,
  `planned_activity_id`, or explicit `timeline_id`; V3 joins that planned
  context before deriving operational feedback. Realized command/health-check
  rows can likewise carry provider-owned external IDs plus `planned_activity_id`
  or an explicit `timeline_id` match, and V3 keys the derived command-success
  feedback back to the selected planned activity while using provider
  `command_result` aliases such as rejected, failed, timeout, accepted,
  acknowledged, or succeeded, including list- or map-shaped provider payloads.
  Explicit command and maneuver feedback maps can
  also target selected activities by `timeline_id`, and branch-authored
  provider feedback keys are aliased back to the planned activity for
  confidence scoring. When operational-feedback provenance resolves to one
  trust boundary, derived station-throughput, contact-success,
  observation-success, maneuver-success, command-success, downlink-demand, and
  target-priority branch events carry that boundary for downstream review, with
  strategy branch-event schema validation covering the event-level
  `trust_boundary` and `provenance` fields. Branch-comparison,
  operator-review, and Cadence-import rows summarize those event drivers with
  row-derived `branch_event_trust_boundary_status_counts` whose keys are
  limited to `declared` / `missing` and whose values must add up to
  `branch_event_count`.
  Standalone `proposed_contact.v1`, `realized_activity.v1`, and
  `realized_state_snapshot.v1` activity rows now join planned-activity and
  operational-timeline rows as direct V3 replay inputs for branch-local
  contact-success, station-throughput, observation, command, and maneuver
  pressure, so Cadence contact and execution-feedback exports can drive refresh
  comparisons without first being wrapped in a campaign artifact.
  Mission-state realized resource telemetry rows with spacecraft or scenario
  identity can feed the same operational feedback surface directly:
  `fuel_margin`, `power_margin`, `storage_margin`, `storage_capacity_margin`,
  `downlink_margin`, `downlink_capacity_margin`, `battery_soc`, or
  `battery_state_of_charge` become resource-margin overrides, and
  `payload_available?`, `antenna_available?`, degraded, mode, or spacecraft
  availability fields become resource-availability overrides before branch
  refresh derivation.
  Timeline-feedback reports publish the same resource feedback maps from
  realized resource telemetry, including conservative repeated-snapshot merge
  rules, so a prior repair artifact can drive V3 resource-pressure refresh
  without passing raw telemetry rows again.
  `resource_margin_overrides` can derive branch-local resource-margin-pressure
  refreshes so feedback-adjusted storage/downlink/power/fuel margins flow into
  source resource summaries, branch resource-projection rows, and
  branch-comparison resource score/risk fields, while declared operational
  feedback trust boundaries remain attached to feedback-synthesized resource
  summaries and downstream review/import rows.
  `resource_availability_overrides` can derive branch-local payload/antenna
  availability refreshes, causing generated observation or downlink candidates
  to pass through the existing resource-filter suppression path. The
  `availability_overrides` alias is merged into the canonical availability
  override map before V3 branch derivation and candidate-refresh filtering, and
  explicit branch resource events preserve event-level trust boundaries across
  merged resource-summary overlays before downstream review/import handoff.
  Standalone refresh applies degraded-mode and spacecraft-unavailable feedback
  to resource summaries before resource filtering, so
  adapter-shaped feedback does not disappear when the canonical map is empty.
  Resource-filter suppressions flatten station-calendar entry IDs from nested
  provider source evidence when needed while preserving the source entry and
  overlap context for review/import audit.
- V3 emits both `ranking_comparison_report.v1` and
  `pareto_frontier_report.v1` alongside branch comparisons. Ranking comparison
  preserves normalized-order versus score-rank deltas; Pareto frontier
  preserves explainable dominance over branch objective vectors, including
  repaired constraint warning/fail counts as minimization objectives, with
  frontier and dominated branch IDs carried into operator-review and
  Cadence-import rows.
  Branch comparison, ranking comparison, and Pareto reports include top-level
  `model_limits` so downstream review/import gates can distinguish
  deterministic explanation products from solver output or autonomous execution.
