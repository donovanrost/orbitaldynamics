# Branch-Local Feedback, Validation, and Recommendation

## Candidate-refresh request inputs

Candidate-refresh request inputs normalize clean numeric strings before deriving branch-local candidates and freshness reports. The normalized inputs cover:

- Operational-feedback factor/demand maps.
- Resource-margin override maps.
- Maneuver execution-uncertainty scalars/vectors.
- Target priority overrides.
- Candidate-limit counts.
- Candidate-refresh minimum-duration constraints.
- Target-row encoded observation-success factors.
- Objective required counts/data-volume/latency/priority fields.
- Scoring-policy weights.
- Freshness-policy timing thresholds.
- Branch-generation feedback and priority thresholds.
- Generated urgent-placeholder booleans.
- Current epoch.
- Remaining-horizon timing.

### Current-epoch fallback chain

When the top-level request omits `current_epoch_s`, candidate refresh falls back, in order, to:

1. `mission_state.current_epoch_s`
2. `mission_state.current_epoch.seconds_since_j2000`
3. `accepted_planning_state.current_epoch_s`
4. `accepted_planning_state.current_epoch.seconds_since_j2000`
5. The first accepted-state spacecraft epoch.

This preserves request precedence while allowing durable mission snapshots to supply freshness timing.

### Remaining-horizon fallback chain

When the top-level request omits `remaining_horizon`, candidate refresh uses `mission_state.remaining_horizon` as the same bounded refresh and freshness input. It falls back again to `accepted_planning_state.remaining_horizon` when both the request and mission-state bundle omit horizon fields. Explicit request horizons take precedence.

### Spacecraft-identity and accepted-state fallbacks

- **Spacecraft identity** — Candidate refresh applies mission-state spacecraft identity before accepted-state spacecraft identity when matching spacecraft-scoped objectives or backfilling resource-filter candidate IDs. Accepted-state spacecraft rows remain the fallback when mission-state rows are absent.
- **Targets** — Candidate refresh consumes accepted-state `targets` through the same target-priority path as explicit and mission-state targets.
- **Ground network** — Accepted-state `ground_network` rows flow through the same station-overlay path as top-level and mission-state ground-network rows, preserving trust-boundary evidence on branch-local contact suppressions when explicit request rows are omitted.
- **Resource summaries** — Accepted-state `resource_summaries` flow through the same resource-filter path as top-level and mission-state summaries, preserving source-quality and trust-boundary evidence on branch-local resource suppressions.
- **Station calendar** — Candidate refresh consumes top-level, mission-state, and accepted-state `station_calendar` interval lists through the same station overlay path as `ground_network`, preserving reservation and trust-boundary evidence on branch-local contact suppressions.

### Contact allocation in embedded refresh

Embedded candidate-refresh contact allocation passes `contact_allocation_policy` through to `ContactAllocation`, including `default_required_capacity_fraction`. As a result, reduced-capacity packing decisions in branch-local refresh artifacts carry the same `capacity_pack_*` and capacity-requirement ledger evidence as standalone allocation reports.

### Capability surface and constraint normalization

The capability surface now names explicitly:

- Mission-state spacecraft-identity precedence.
- Accepted-planning-state spacecraft-state, target, ground-network, resource-summary, current-epoch, remaining-horizon, station-calendar interval, and provider-list fallbacks.

Candidate-refresh `avoid_eclipse` constraints normalize JSON-style boolean strings before candidate filtering; malformed values remain missing/default evidence.

## Validation and integrity

Executable artifact validation applies the same typed checks to operational-feedback number maps, resource-margin overrides, and resource-availability override aliases in top-level feedback and provenance source feedback. It also checks malformed-feedback section rows, source-report status counts, and declared source-count consistency inside operational-feedback provenance.

### Realized partial-row success factors

Partial realized contact, observation, maneuver, and command rows use explicit `completed_fraction` values as success factors when present, before falling back to the planner's coarse partial defaults. Partial contact rows can also use throughput-completion evidence for `contact_success_rate`. Explicit provider `contact_success: false`, `command_success: false`, or terminal result aliases remain hard failure evidence.

## Branch-local feedback events

Branch-local feedback events for station throughput, contact success, observation success, target priority, command success, and downlink demand are folded into the generated `candidate_refresh_request`. This lets explicit what-if branches regenerate candidates without a precomputed branch refresh artifact.

### Resource-pressure and availability aliases

Branch-authored resource-pressure and availability events normalize the same provider aliases used by operational feedback, including:

- `storage_capacity_margin`
- `downlink_capacity_margin`
- `battery_soc`
- `battery_state_of_charge`
- `payload_available?`
- `antenna_available?`
- `spacecraft_available?`

Normalization happens before branch-local candidate refresh, resource filtering, resource scoring, and risk output.

### Downlink-demand feedback

Downlink-demand feedback derives its own strategy branch and carries required-demand evidence into refreshed downlink scoring and branch risk rows. Branch-local downlink-demand context also carries collection, product, payload, instrument, target, latency, source-activity, and trust-boundary evidence into branch-generated downlink candidates. Therefore objective-satisfaction collection-latency replay does not lose provider scoping before V2 repair tries to stage a replacement.

Branch risk indicators, branch-comparison rows, selected-recommendation risk-driver rows, operator-review rows, and Cadence import manifest rows flatten the same scoped downlink completion evidence for review/import routing without reopening raw branch events.

### Collection-latency derivation

Collection-latency derivation now treats the following as no-collected-data cases, instead of creating downlink relief for data that was never collected:

- Missed/failed/canceled/cancelled/rejected realized observations.
- Completed observations with explicit unsuccessful observation feedback and no actual or fractional data volume.

## Priority-commitment and target branches

### Priority-commitment derivation

Priority-commitment branch derivation and objective-satisfaction summaries now honor explicit `target_id`, `target_ids`, and `required_target_ids` selectors. List-scoped commitments generate per-target branch refreshes without counting the commitment row ID as a required target. Inline target specs are carried into branch refresh when no separate target catalog row is present.

Priority-commitment scoring now measures required, planned, and missing observation counts, so a target with a `required_count` above one is not treated as satisfied by a single selected observation. Branch-comparison, operator-review, and Cadence-import rows flatten those required/planned/missing observation counts plus the priority-commitment ratio for adapter routing.

### Target-revisit and target-observation derivation

Target-revisit and target-observation branch derivation uses the same explicit target-selector and inline target-spec handling, while keeping distinct branch IDs, labels, and strategic-addition repair reasons for `target_revisit` versus `target_observation` objectives. Campaign `target_commitment` rows use the shared target-observation alias contract at direct CandidateRefresh, mission-objective, and objective-satisfaction replay boundaries; V3 decision events and repair reasons are canonical `target_observation`, while standalone candidate evidence retains the supplied label for audit.

Multiple scoped objectives for the same target keep disambiguated branch IDs plus base-branch lineage in branch metadata. Branch-comparison, operator-review, and Cadence-import rows flatten that target-branch lineage so adapter queues can route scoped target futures without reopening branch internals.

## Branch feedback scoring and comparison rows

Branch feedback score/risk fields use the same branch-local feedback merge, so branch-comparison rows expose the confidence factors and source labels that shaped generated candidates. Branch-comparison rows also summarize branch event count/type evidence plus combined source branch IDs. Review/import rows flatten those fields while also preserving that context under `source_branch_comparison`.

Strategy branch events preserve numeric what-if feedback inputs for audit, while executable schema validation bounds station-throughput plus contact, command, observation, and maneuver success factors to the same unit interval as refreshed candidate rows.

Link-capacity pressure branches also carry prior realized `actual_downlink_completion_ratio` into branch-comparison, operator-review, and Cadence-import rows, so adapter queues can see whether the pressure came from selected-capacity planning shortfall, realized delivery shortfall, or both.

Branch-comparison rows keep the applied success confidence in that same unit interval.

### Multiple scoped objectives and derived branch events

Multiple scoped downlink-completion objectives derive independent branch-local refresh branches, preserving objective IDs on the gap event and avoiding objective order as a hidden selector.

Derived branch events that aggregate multiple realized rows keep stable `source_activity_ids` or `missed_downlink_activity_ids` arrays, while using the singular source field as the stable primary identifier for adapters.

Collection-latency derived branch events preserve `objective_id`, and derived branch IDs include that objective identity when present, so multiple latency objectives on the same observation do not collapse into indistinguishable branch rows.

## Mission-state realized resource telemetry

Mission-state realized resource telemetry can also derive the same normalized operational-feedback maps when rows declare spacecraft or scenario identity:

- **Margin fields** — including `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`, and `battery_state_of_charge` aliases — feed `resource_margin_overrides`.
- **Payload, antenna, degraded-mode, and spacecraft-availability fields** feed `resource_availability_overrides`.

The same telemetry rows now contribute spacecraft-keyed `feedback_trust_boundaries` for both resource override maps, preserving the row's declared trust boundary when V3 later replays the timeline-feedback report into resource-margin or availability branches.

### Availability override schema and normalization

The exported operational-feedback schema now types those availability overrides for both the canonical field and the `availability_overrides` alias, including:

- `spacecraft_available`
- `spacecraft_availability`
- `degraded`
- `mode`
- `incompatible_activity_types`
- `suppressed_activity_types`

Direct candidate-refresh resource summaries normalize trimmed case-insensitive `"true"`/`"false"` strings for payload, antenna, degraded, and spacecraft availability before filtering.

## Resource-margin and availability branch routes

`operational_feedback.resource_margin_overrides` is preserved in V3 artifacts and can drive branch-local resource-margin-pressure refreshes plus the matching branch-comparison resource score/risk fields.

The same branch-local refresh route as planning-grade projected resource pressure (with report or wrapper trust provenance) can be driven by:

- Prior source and canonical repair or plan `resource_projection_report.v1` pressure rows.
- `resource_projection_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, or mission-state `source_result_artifact` / `result_artifact` wrappers.
- Resource-projection rows preserved in operator-review packages or Cadence-import manifests.

Prior source, canonical, and result-artifact-embedded `station_calendar_report.v1` affected-contact and provider-contention rows can likewise drive branch-local station outage, reservation, and reduced-capacity refreshes without re-entering the provider calendar interval by hand.

`operational_feedback.resource_availability_overrides` can drive branch-local payload/antenna availability refreshes through the resource filter. Spacecraft-level degraded/unavailable feedback can derive a `degraded_spacecraft` branch event that suppresses incompatible generated candidates while lowering branch-comparison spacecraft, payload, and antenna availability according to the event's incompatible activity types.

### Normalizer aliases and flag canonicalization

The strategy normalizer accepts the same `availability_overrides` alias as candidate refresh and merges it before branch derivation. Struct-style `payload_available?`, `antenna_available?`, and `degraded?` flags are canonicalized before deriving branch events.

The following inputs normalize JSON-style degraded booleans (including `"1"` / `"0"`), plus atom-or-string scalar values and lists for `incompatible_activity_types` / `suppressed_activity_types` into deterministic string arrays before repair, resource summaries, and branch comparison consume them — while preserving the event's declared degraded-mode label in the branch repair realized-state snapshot:

- Mission-state degraded spacecraft inputs.
- Raw mission-state resource margins/capacity-derived storage/downlink inputs.
- Resource-summary degradation rows.
- Branch-authored degraded events.

Mission-state degraded spacecraft rows and branch-authored degraded/resource events also normalize spacecraft/scenario identity and degraded-mode values before writing derived branch events, realized-state snapshots, resource overlays, operational-feedback keys, and risk rows. Branch-authored `suppressed_activity_types` is accepted as an input alias but emitted through canonical `incompatible_activity_types` on normalized branch events.

### Resource-projection provenance in comparison rows

Branch-comparison rows also lift resource-projection source-quality and trust-boundary status count maps from nested branch projection reports, so strategy review can see whether resource pressure came from declared or missing-boundary planning summaries without reopening the full branch payload.

## Contact, station-throughput, and realized-row matching

Contact-success and station-throughput feedback scoring applies to native downlinks and direction-`downlink` `planned_contact` rows selected by branch repair. It falls back to branch-generated source candidates when a refresh branch has not selected those contacts into the repaired activity list yet.

Branch-comparison, operator-review, and Cadence-import rows expose the corresponding feedback activity source so reviewers can distinguish selected plan activities from refresh-only source candidates.

The exported JSON Schema now exposes the known nested operational-feedback maps and branch rows. Operator-review/Cadence-import rows preserve those branch-comparison feedback factor source labels plus raw observation provider results while still allowing future feedback or branch context keys.

### Sparse realized-row identity matching

Mission-state realized contact and observation feedback can be sparse as long as the realized row identity matches a prior activity, candidate, or proposed contact row by `id`, `activity_id`, `planned_activity_id`, or explicit `timeline_id`. V3 joins that planned context before deriving station-throughput, contact-success, or observation-success factors.

## Command, observation, and maneuver provider-result feedback

### Command-success feedback

Command-success feedback can also derive command/health-check confidence review branches from status, completed fraction, or provider `command_result` aliases. This includes provider-shaped `planned_contact` / `contact` rows with `direction: health_check` or provider hyphen/whitespace variants, using `planned_activity_id` when provider rows carry their own external IDs, with list-valued provider results flattened before artifact emission.

### Observation-success feedback

Timeline-feedback and V3 observation-success feedback accept the same provider-result alias grammar through `observation_result`, with failure aliases overriding a completed status before producing branch-local observation success rates.

### Maneuver-success feedback

Timeline-feedback and V3 maneuver-success feedback accept the same provider-result alias grammar through `maneuver_result`, with failure aliases winning over success aliases when mixed, and realized maneuver outcomes taking precedence over planned maneuver-confidence factors. Failed completed maneuver results are review-gated as maneuver exceptions in the artifact-only review/import queue.

### Timeline-identity and trust-boundary propagation

Timeline-identity matches are still keyed back to the selected planned activity for activity-scoped confidence scoring. Explicit command/maneuver operational-feedback maps can target a planned row by its `timeline_id`. Branch-authored command or maneuver feedback events that carry provider feedback keys are also aliased back to `activity_id` for branch scoring.

When the merged operational-feedback provenance has one unambiguous trust boundary, derived station-throughput, contact-success, observation-success, maneuver-success, command-success, downlink-demand, and target-priority branch events carry that `trust_boundary` alongside their feedback-source labels.

Strategy branch-event schemas and executable validation type-check branch-event `trust_boundary`, `provenance`, and feedback confidence/sample weight fields, so downstream import/review tools do not need to treat that provenance as arbitrary extra JSON.

### Qualitative image-quality statuses

Qualitative image-quality statuses such as unusable, rejected, missing, degraded, or marginal now map to deterministic planning factors when no scalar quality, cloud-cover, or blur evidence is supplied. This lets status-only product feedback derive the same branch-local observation refresh path without introducing a separate image-product model.

### Branch-authored scalar feedback and weight sources

Explicit branch-authored scalar feedback preserves the declared raw scalar, weight, and weight-source fields on the event, while applying the bounded confidence weight only to branch-local refresh and comparison scoring. Feedback adjustments, branch-comparison rows, and selected recommendation explanations summarize the contributing `feedback_weight_sources` for adapter review.

### Strategic additions and event-driver provenance

Strategic additions staged from those branch events also carry the event `feedback_source`, `feedback_scope`, `trust_boundary`, source activity/timeline identity, and derivation reasons in their feasibility evidence. The generated approval-requirement `activity_context` exposes the same fields, so operator review can audit why the candidate was inserted without rejoining against branch events.

Branch-comparison, operator-review, and Cadence-import rows also expose row-derived `branch_event_trust_boundary_status_counts` for those event drivers. Executable validation checks that the declared and missing counts use only those two status keys and add up to `branch_event_count`.

Command feedback still requires selected command or health-check activities to scope the event.

## `strategy_recommendation.v1` exports

`strategy_recommendation.v1` exports nested ranked branch ID arrays, tradeoff rows, risk rows, explanation rows, feedback factor activity-source provenance, and approval-requirement rows, so downstream review tooling can inspect recommendation rationale and approval boundaries without treating those fields as free-form lists.

`branch_event_summary` explanation rows expose, with executable type checks:

- Event counts.
- Event types.
- Status-transition type/category/reason summaries.
- Operator-review requirement counts.
- Combined source branch IDs.
- Reduced-capacity pack demand summaries.

### Resource-pressure explanation rows

Resource-pressure explanation rows preserve first-pressure activity, direction, ground-station, station-calendar entry, provider, provider-entry, and resource availability status/type evidence when the selected recommendation is driven by projected resource pressure. Operator-review and Cadence-import recommendation rows flatten that resource-pressure status/type and first-pressure-kind context for adapter routing.

## Policy surfaces and approval enums

`campaign_strategy.v3.recommendation` exports the same nested recommendation shape. Recommendation `approval_status` is constrained to the policy classification enum. `campaign_strategy.v3.strategy_policy` exports string-keyed numeric scoring-weight fields instead of an opaque object.

The embedded `campaign_strategy.v3.approval_policy` exports the same typed approval-rule surface as `policy_bundle.v1`, including schema-constrained policy-classification selectors. `campaign_repair.v2.approval_policy` uses the same nested approval-policy schema, so repair-time approval rules are checked before Cadence-facing review or import.

### Policy-decision shape

Embedded V2 repair and V3 branch `policy_decision` objects also export the same policy-decision classification, rule-match, escalation, and model-limit shape as standalone `policy_decision.v1`. Direct row-level policy decisions use that same canonical policy-decision shape instead of opaque objects in these schemas:

- link-capacity
- contact-allocation
- contention
- contention-resolution
- contact-filter
- resource-filter
- resource-projection
- contact-intent
- maneuver-review
- command-window
- station-calendar

### Source-evidence snapshots

Operator-review package rows and Cadence import manifest rows keep `source_policy_decision` as optional snapshot evidence, but its known fields now expose the same schema-constrained policy classification, schema-contract, rule-match, escalation, and count surface.

Their `source_policy_escalation` snapshots likewise expose schema-constrained classification, authority, queue/role/level, rule ID, and SLA fields without turning the source evidence into executable workflow.

## Standalone fixtures and wrappers

The standalone `strategy_recommendation_v1.json` fixture keeps that Cadence-facing import surface lintable without requiring consumers to load a full V3 strategy artifact.

`strategy_branch.v1` is also exported as a standalone wrapper around the V3 branch row shape, preserving:

- Branch probability.
- Numeric score terms.
- Risks.
- Approval requirements.
- Policy decision evidence.
- Typed branch-event downlink, latency, stable-ID lineage, bounded feedback factors.
- Feedback-adjustment activity-source provenance.
- Optional resource/provenance context for branch-level compatibility checks.
