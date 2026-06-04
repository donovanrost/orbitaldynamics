# Artifact Overview and Branch Replay

`campaign_strategy.v3` compares branch-local repairs and recommends a branch.

## Top-level shape

- `mission_state_snapshot`
- `branches`, each carrying:
  - events
  - candidate plan
  - repair result
  - score terms
  - policy decision
  - resource impacts
  - optional resource projection reports
  - risks
  - warnings

Resource projection overflow/shortfall and availability pressure is promoted into branch risks for approval classification.

## Branch-local refresh event derivation

When branch derivation is enabled, prior reports can derive branch-local refresh events. The sources below feed this replay path.

### From `resource_projection_report.v1` pressure rows

Prior `resource_projection_report.v1` pressure rows can derive branch-local refresh events for:

- projected storage overflow
- downlink shortfall
- battery depletion
- externally supplied negative thermal margin pressure
- unavailable payload
- unavailable antenna
- degraded-payload operations
- unavailable spacecraft
- resource-summary activity-type suppression/incompatibility

Prior result-artifact wrappers may use either `source_resource_projection_report` or `resource_projection_report` for the same branch-local replay path.

### From contact allocation reports

Prior `source_contact_allocation_report` or `contact_allocation_report` rows — plus `source_contact_allocation_report` or `contact_allocation_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers — can likewise derive branch-local downlink-completion-gap refresh events from deferred, blocked, or policy-blocked downlink allocation outcomes.

These preserve station identity, including:

- nested provider-shaped station objects and clean timing aliases
- `source_contact` / `contact_candidate` handoff aliases
- contact, throughput, allocation-status, and review/approval status
- embedded policy-decision classification
- `downlink_demand_sources`
- `downlink_completion_source` / `downlink_completion_sources`
- `capacity_pack_*` reduced-capacity packing evidence
- station reservation identity/status/match evidence
- row- or report-level trust-boundary evidence

### From link capacity reports

Prior `source_link_capacity_report` and `link_capacity_report` rows — plus `source_link_capacity_report` or `link_capacity_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers — can derive branch-local downlink-completion-gap refresh events from selected or actual downlink shortfalls.

These preserve:

- selected-capacity, actual-throughput, and requirement-status
- contact IDs from flat arrays or nested selected/source contact objects
- nested provider-shaped station identity and clean timing aliases
- planned-contact counts inferred from selected contact IDs/objects
- `source_window_id` / `source_window_ids` from rows or nested contact context, with the same source-window lineage copied into branch risk and repair feasibility context
- `downlink_demand_sources` from rows or nested contact context
- `downlink_completion_source` / `downlink_completion_sources`
- trust-boundary evidence

### From objective satisfaction reports

Prior `source_objective_satisfaction_report` or `objective_satisfaction_report` rows — plus `source_objective_satisfaction_report` or `objective_satisfaction_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers — with partial or unmet status can derive branch-local refresh events.

**Status normalization** — case/whitespace/hyphen variants, common unsatisfied aliases, and provider pressure aliases such as `shortfall`, `below_target`, `at_risk`, `needs_replan`, and `late` are normalized into canonical objective statuses. Status is drawn from:

- `status`, `objective_status`, `satisfaction_status`, `objective_satisfaction_status`, `completion_status`, `requirement_status`
- requirement-scoped fields such as `downlink_requirement_status`, `coverage_status`, and `delivery_requirement_status`
- JSON-style satisfaction booleans

The normalized provider alias is preserved as `source_objective_status`.

**Event mapping** — downlink-completion rows become downlink-completion gaps, while target-coverage and target-commitment rows become urgent-target refresh events.

**Contact and target inference** — provider contact lists/objects such as `required_downlink_contacts`, `selected_contacts`, `satisfied_contact`, `source_contact`, and `missed_contact` can infer contact counts and source activity IDs when explicit count fields are absent, including provider `source_activity_id` and `downlink_activity_id` contact-object identifiers. Target-list/object aliases such as `candidate_targets`, `required_targets`, and `selected_targets` can infer required and planned observation counts when explicit count fields are absent, and nested provider source/selected/satisfied/candidate observation or activity objects preserve stable source activity IDs on the derived event.

**Collection latency** — collection-latency rows become latency-scoped downlink-completion-gap refresh events. Provider delivery aliases such as `target_latency_s`, `delivery_latency_s`, `actual_delivery_latency_s`, `collection_end_s`, and `delivery_deadline_s` feed the same latency fields, while data-volume aliases such as `target_data_volume_mb`, `required_volume_mb`, `min_downlink_mb`, and `selected_data_volume_mb` feed the same downlink-demand fields.

These preserve objective status, selected-contact, selected-target, source-observation, latency, data-volume, and trust-boundary evidence, including stable lineage IDs from nested source/selected/satisfied/candidate observation or activity objects and missed/selected/source contact or downlink objects.

**Score-term fallback** — when objective-satisfaction provider rows carry deterministic `score_terms` instead of top-level requirement fields, downlink shortfall, contact-count gap, and target-gap terms are normalized into the same branch-local refresh events, including score-term map key case/whitespace/hyphen variants.

**Executable refresh objectives** — prior candidate-refresh `source_objective_satisfaction_report` replay now consumes direct reports, result-artifact embedded reports, and preserved operator-review / Cadence-import objective-satisfaction rows as executable refresh objectives:

- non-passing downlink-completion rows become `downlink_completion` objectives
- target coverage/commitment rows become target revisit/coverage objectives
- collection-latency rows become `collection_latency` objectives
- met/selected rows remain report evidence only

### From objective tradeoff reports

Prior `source_objective_tradeoff_report` or `objective_tradeoff_report` rows — plus `source_objective_tradeoff_report` or `objective_tradeoff_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and objective-tradeoff rows preserved in operator-review packages or Cadence-import manifests — can derive branch-local refresh events when rows carry explicit downlink, collection-latency, or target-gap fields.

**Score-term gap inference** — required downlink volume, contact count, or target-observation count can be inferred from deterministic `score_terms` gap evidence such as `downlink_shortfall_mb`, `contact_count_gap`, `missing_observation_count`, `target_gap_count`, `target_coverage_gap_count`, `missing_revisit_count`, `revisit_shortfall_count`, or `coverage_gap_count` when the row does not promote those gaps to top-level fields. Score-term map key case/whitespace/hyphen variants are normalized before lookup.

**Revisit/coverage target identity** — target identity can also arrive through revisit/coverage-specific aliases such as `missing_revisit_targets`, `required_revisit_target_ids`, `missing_coverage_targets`, and `selected_coverage_target_ids`; these are treated like the generic target-gap aliases while preserving inline target priority and geometry.

**Collection-latency tradeoff rows** — these also accept provider delivery aliases such as `target_latency_s`, `delivery_latency_s`, `actual_delivery_latency_s`, `collection_end_s`, and `delivery_deadline_s` before deriving latency-window events, plus the same provider data-volume aliases before deriving downlink-demand fields. Nested source-observation metadata can now supply the target, collection, product, payload, and instrument selectors for those latency-scoped downlink-refresh requests, along with collection-end, delivery-deadline, target-latency, and actual-delivery-latency timing evidence and target/selected data-volume demand, when the tradeoff row does not flatten them at top level.

**Downlink tradeoff rows** — these accept the same provider contact list/object aliases as objective-satisfaction rows, including `required_downlink_contacts`, `selected_contacts`, and `satisfied_contact`, to infer required/planned contact counts and source activity IDs when explicit count fields are absent.

**Target tradeoff rows** — these accept provider target lists/objects such as `required_targets`, `candidate_targets`, and `selected_targets` to infer required/planned observation counts when explicit observation-count fields are absent, while nested provider source/selected/satisfied/candidate observation or activity objects preserve the singular observation source activity ID even when nested contact objects also add lineage IDs.

**Pressure-row normalization** — objective-tradeoff pressure rows also normalize JSON-style `selected` booleans before preserving unselected-branch rationale, objective label case/whitespace/hyphen variants are normalized before branch-local refresh derivation, and prior/source report ingestion accepts adapter-facing `rows` as a read-only alias for canonical `tradeoffs`.

**Target-gap aliases** — target-gap aliases such as `uncovered_target_ids`, `unsatisfied_target_ids`, `missing_target_ids`, and `target_gap_ids`, plus inline target specs in `targets`, `target_specs`, `required_targets`, `committed_targets`, `priority_targets`, `candidate_targets`, `uncovered_targets`, `unsatisfied_targets`, `missing_targets`, `missed_target`, `missed_targets`, or `target_gap_targets`, are normalized into urgent-target refresh events.

Derived events preserve branch/scenario identity, score deltas, score terms, source activity IDs, inline target priority/geometry, latency-window evidence, data-volume evidence, derivation reasons, and trust-boundary evidence.

### From score-term reports

Prior `source_score_term_report` or `score_term_report` rows — plus `source_score_term_report` or `score_term_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and score-term rows preserved in operator-review packages or Cadence-import manifests — can also derive branch-local downlink-completion-gap or urgent-target refresh events when they carry explicit station-routed downlink/contact gap evidence or target-routed observation/coverage gap evidence.

**Collection-latency score-term rows** — these accept the same provider delivery aliases for latency limits, actual delivery latency, collection-end timing, delivery deadlines, and data-volume demand, including nested source-observation/source-activity station, scenario, collection/product/payload/instrument selectors, data-volume evidence, and target identity/priority/geometry for score-term collection-latency and urgent-target replay.

Score-term key case/whitespace/hyphen variants are normalized while preserving:

- score-term key/value evidence
- source activity IDs, keeping nested observation/activity IDs as the primary collection-latency source activity while contact objects remain additional lineage, including provider `downlink_activity_id` contact-object identifiers
- downlink-demand source lineage
- inline target spec priority/geometry, including `missed_target` / `missed_targets` aliases
- derivation reasons
- trust-boundary context

### From constraint reports

Prior or mission-state `source_constraint_report` or `constraint_report` rows — plus `source_constraint_report` or `constraint_report` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and constraint rows preserved in operator-review packages or Cadence-import manifests — feed two derivation paths.

**Resource-margin pressure** — failed or warning resource-margin constraints normalize status, severity, and metric case/whitespace/hyphen variants before becoming branch-local resource-margin-pressure refresh events when they carry a numeric margin value, including campaign constraint-key metric aliases such as `min_projected_*_margin` and fuel / `thermal_margin_c`.

**Downlink-completion gaps** — failed or warning selected-downlink-shortfall or provider data-volume-shortfall constraints become downlink-completion-gap refresh events from `value` or row-local shortfall fields such as `selected_downlink_shortfall_mb`, only when explicit station routing is present. Nested `ground_station` / `station` objects and nested selected/source/contact station objects are accepted as routing evidence.

These preserve constraint ID, metric, value, threshold, severity, source activity, required/planned downlink volume and shortfall evidence — including provider data-volume aliases — from top-level fields, nested `throughput_model` / `activity_context`, or nested selected/source/contact objects, including nested contact scenario, time-window, and contact-count evidence, exact downlink-demand/completion source lineage, time windows, contact-count evidence, and source contacts from flattened IDs or nested contact objects.
