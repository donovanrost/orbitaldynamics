# Resource, Contact, and Objective Pressure Replay

## Realized contact and observation context recovery

- Sparse realized contact or observation rows can now recover activity type, station, target, and expected-throughput context from the prior plan by activity ID before deriving those feedback factors.
- Sparse missed/failed downlink feedback treats unique direction-`downlink` `planned_contact` or provider `contact` rows as downlink-completion evidence.
- Terminal provider `contact_result` failure aliases such as `dropped` can create the same downlink-completion gap even when the provider status says `completed`. This includes list-valued or comma-delimited mixed result evidence, where any terminal failure wins.
- When those provider result failures carry required downlink demand, they also synthesize `downlink_demand_mb` feedback for generated replacement contacts.
- Collection-latency objectives treat the failed provider contact as an unsatisfied latency downlink when selecting recovery contacts. This includes array/object missed-downlink lineage such as `missed_downlink_activity_ids` and nested failed contact objects.
- Successful provider result aliases such as `delivered` suppress status-only downlink gap and demand derivation, so provider outcomes take precedence over coarse status fields.
- Station-feedback derivation accepts station-identifier-only planned contacts.
- Sparse missed/failed observation feedback also recovers planned spacecraft and timing context, so scoped target coverage or revisit objectives do not count a missed in-window observation as satisfied.
- **Caveat** — this recovery only happens when the prior activity ID resolves to one unique row.

## Feedback ingress and provenance

- Mission-state embedded `operational_feedback` is accepted as a Cadence-facing snapshot input.
- Top-level explicit `operational_feedback` remains the override.
- Standalone candidate-refresh provenance records whether feedback came from the top-level request, mission-state snapshot, or accepted planning-state snapshot, including the source path for malformed embedded feedback.

## Realized resource telemetry into margin/availability overrides

- Mission-state realized resource telemetry with spacecraft/scenario identity now derives `resource_margin_overrides` and `resource_availability_overrides`.
- Derived margin aliases include `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`, and `battery_state_of_charge` as planning-grade margin aliases, while preserving battery capacity and energy-used evidence.
- Availability provider aliases `payload_available?` and `antenna_available?` are preserved.
- This lets resource-pressure and availability branch refresh be driven directly from realized resource snapshots.

## Resource-margin and fuel pressure branch refresh

- `operational_feedback.resource_margin_overrides` can derive branch-local resource-margin-pressure refreshes that propagate into source resource summaries, branch resource-projection reports, and branch-comparison resource score/risk fields.
- Duplicate mission-state resource branch IDs for the same spacecraft are disambiguated for independent power, thermal, payload, or antenna pressure rows, so one resource snapshot does not hide another before branch comparison.
- **Fuel-preservation branch refresh** — preserves every low-fuel spacecraft/source summary as branch-local resource pressure evidence instead of carrying only the single lowest margin.

## Resource-projection report replay

- Prior source and canonical `resource_projection_report.v1` pressure rows from repaired or planned artifacts can derive branch-local refreshes. This also covers:
  - `resource_projection_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers.
  - `resource_projection_report.v1` rows embedded in mission-state `source_result_artifact` / `result_artifact` wrappers.
  - Resource-projection rows preserved in operator-review packages or Cadence-import manifests.
- These convert projected storage overflow, downlink shortfall, battery depletion, externally supplied negative thermal margin pressure, payload/antenna availability pressure, and resource-summary activity-type suppression/incompatibility pressure into `downlink-demand`, `resource-margin-pressure`, and `resource-availability` branch events, instead of one report shadowing the other.
- Preserves source-activity, first-pressure, and report or wrapper trust-boundary evidence.
- Multiple independent pressure rows for the same spacecraft now receive deterministic source-activity-based branch IDs instead of collapsing behind the spacecraft-only derived branch ID.

## Resource-filter and contact-filter suppression replay

- Prior source and canonical resource-filter or contact-filter suppression rows can likewise replay into branch-local pressure. This includes:
  - `resource_filter_report.v1` and `contact_filter_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers.
  - `resource_filter_report.v1` rows embedded in mission-state `source_result_artifact` / `result_artifact` wrappers.
- Replays without losing independent rows for the same candidate/contact and suppression reason.
- Uses deterministic source-report, source-window, timing, and report or wrapper trust-boundary evidence to disambiguate duplicate filter-pressure branch IDs.
- Resource-availability risks from resource-filter or operational-feedback
  replay contribute to `resource_availability_pressure_penalty` in V3 score
  terms, while resource-margin storage/downlink risks stay in the
  storage/downlink pressure term.
- Fuel, power, and thermal margin risks from replayed resource pressure
  contribute to `resource_margin_pressure_penalty` in V3 score terms.
- Resource-projection battery-depletion risks contribute to
  `battery_depletion_pressure_penalty` in V3 score terms, while projected
  storage/downlink risks stay in the storage/downlink pressure term.
- Contact-filter `downlink_completion_gap` risks contribute to
  `contact_filter_pressure_penalty` in V3 score terms, keeping suppressed
  contact-window pressure visible separately from unrelated generic risks while
  preserving total branch score compatibility.

## Contact-allocation report replay

- Prior `source_contact_allocation_report` or `contact_allocation_report` rows, plus `contact_allocation_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, can derive branch-local refreshes for deferred, blocked, or policy-blocked downlink allocation outcomes.
- Normalizes allocation, review/approval, and policy-classification status case/whitespace/hyphen variants before converting the affected contact into a `downlink_completion_gap` event.
- Preserved evidence with the event:
  - Station, including nested provider-shaped station identity and clean timing aliases.
  - `source_contact` / `contact_candidate` handoff aliases.
  - Contact, throughput, allocation-status, review/approval status.
  - Embedded policy-decision classification.
  - `downlink_demand_sources`.
  - `downlink_completion_source` / `downlink_completion_sources`.
  - `capacity_pack_*` reduced-capacity packing evidence.
  - Station reservation identity/status/match evidence.
  - Row- or report-level trust-boundary evidence.
- Multiple independent allocation-pressure rows for the same contact/status now receive deterministic source-window/source-evidence-based branch IDs instead of collapsing behind the contact-only derived branch ID.

## Contact-contention-resolution report replay

- Prior `source_contact_contention_resolution_report` or `contact_contention_resolution_report` recommendations, plus `contact_contention_resolution_report.v1` recommendations embedded in prior `source_result_artifact` / `result_artifact` wrappers, can likewise derive branch-local refreshes for deferred downlink contacts.
- Preserves the selected contact, selection reason, priority source, priority-override metadata, source-window lineage, required downlink demand, and report or wrapper trust boundary as a `downlink_completion_gap` event.
- The same recommendation payload can be replayed from nested or flattened operator-review source rows, or from top-level Cadence import `source_recommendation` / flattened contact-contention recommendation rows, without resubmitting the original contention-resolution artifact.
- Multiple independent contention recommendations for the same deferred contact now receive deterministic source-window/contention-group/source-evidence branch IDs instead of collapsing behind the contact-only derived branch ID.
- Branch risks and branch-comparison rows flatten that pack evidence for operator scanning.
- Contact-contention and contention-resolution `downlink_completion_gap` risks
  contribute to `contact_contention_pressure_penalty` in V3 score terms,
  keeping contention pressure visible separately from unrelated generic risks
  while preserving total branch score compatibility.

## Wrapper-embedded report replay through live communications paths

- Mission-state `source_result_artifact` / `result_artifact` wrappers can now replay embedded station-calendar, contact-allocation, contact-filter, contact-contention-resolution, and link-capacity reports through the same live branch-local communications pressure paths, while inheriting wrapper trust-boundary evidence.
- Contact-intent rows and review/import handoffs replay blocked, missing-import,
  or invalid intent gates through branch-local `downlink_completion_gap` events.
  Those contact-intent-scoped risks contribute to
  `contact_intent_pressure_penalty` in V3 score terms, keeping review/import
  pressure visible separately from unrelated generic risks while preserving
  total branch score compatibility.

## Link-capacity report replay

- Prior `source_link_capacity_report` and `link_capacity_report` rows, plus `link_capacity_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, can likewise derive branch-local refreshes from selected or actual downlink shortfall.
- Converts the unmet station demand into a `downlink_completion_gap` event while preserving:
  - Selected-capacity, actual-throughput, requirement-status.
  - Capacity-adjusted throughput totals and per-station adjusted-throughput
    totals for source-report provenance review.
  - Contact IDs from flat arrays or nested selected/source contact objects.
  - Nested provider-shaped station identity and clean timing aliases.
  - Planned-contact counts inferred from selected contact IDs/objects.
  - `source_window_id` / `source_window_ids` from rows or nested contact context, with the same source-window lineage copied into branch risk and repair feasibility context.
  - `downlink_demand_sources` from rows or nested contact context.
  - `downlink_completion_source` / `downlink_completion_sources`.
  - Report or wrapper trust-boundary evidence.
- Multiple independent shortfall rows for the same station now receive deterministic source/contact/window-based branch IDs instead of collapsing behind the station-only derived branch ID.
- Link-capacity-derived `downlink_completion_gap` risks contribute to
  `link_capacity_pressure_penalty` in V3 score terms, keeping shortfall pressure
  visible separately from unrelated generic risks while preserving total branch
  score compatibility.

## Objective-satisfaction report replay

- Prior `source_objective_satisfaction_report` or `objective_satisfaction_report` rows, plus `objective_satisfaction_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, with partial or unmet status, can also derive branch-local refreshes.

### Status normalization

- Normalizes case/whitespace/hyphen variants, common unsatisfied aliases, and provider pressure aliases such as `shortfall`, `below_target`, `at_risk`, `needs_replan`, and `late` into canonical objective statuses.
- Status is read from `status`, `objective_status`, `satisfaction_status`, `objective_satisfaction_status`, `completion_status`, `requirement_status`, requirement-scoped fields such as `downlink_requirement_status`, `coverage_status`, and `delivery_requirement_status`, or JSON-style satisfaction booleans, before branch derivation.
- Preserves the normalized provider status as `source_objective_status` on derived branch evidence.

### Branch derivation by row type

- **Downlink-completion rows** — convert contact-count or data-volume gaps into `downlink_completion_gap` events.
- **Target-coverage and target-commitment rows** — convert missing target evidence into `urgent_target` events.
- Provider contact lists/objects such as `required_downlink_contacts`, `selected_contacts`, `satisfied_contact`, `source_contact`, and `missed_contact` can infer contact counts and source activity IDs when explicit count fields are absent, including provider `source_activity_id` and `downlink_activity_id` contact-object identifiers.
- Provider/review aliases such as `uncovered_target_ids`, `unsatisfied_target_ids`, `missing_target_ids`, and `target_gap_ids` are treated as the same target-gap evidence instead of being dropped.
- Objective-satisfaction rows can infer contact, downlink-volume, and target observation gaps from deterministic `score_terms` when provider rows do not promote those gaps to top-level fields, with nested score-term map keys normalized for case/whitespace/hyphen variants.
- Nested or flattened operator-review and Cadence-import objective-satisfaction rows can replay the same downlink, target, and collection-latency branch-local refresh pressure without resubmitting the source report.
- Objective-tradeoff pressure rows normalize JSON-style `selected` booleans so unselected branch rationale is preserved for adapter-shaped inputs, and accept adapter-facing `rows` as a read-only alias for canonical `tradeoffs`.
- Direct provider observation-count aliases such as `required_observation_count` and `selected_observation_count` now drive the required/planned observation counts on derived target refresh branches.
- Direct provider target-gap count aliases such as `observation_shortfall_count`, `missing_observation_count`, `revisit_shortfall_count`, and `coverage_shortfall_count` add to planned observations when explicit required counts are absent.
- Objective-satisfaction row scenario, station, time-window, target-geometry, candidate-window, and spacecraft-selector fields are preserved so branch-local refresh filters can stage scoped replacements instead of broad generic additions.

### Inline target spec objects

- Provider rows can also express target gaps as inline target spec objects such as `targets`, `target_specs`, `required_targets`, `committed_targets`, `priority_targets`, `uncovered_targets`, `unsatisfied_targets`, `missing_targets`, `missed_target`, `missed_targets`, or `target_gap_targets`.
- Target identity, priority, geometry, and minimum elevation are lifted into the derived refresh branch even when the mission-state target catalog does not repeat the target.
- Mission-state target objectives use the same inline target-spec selector aliases for target coverage, target observation, target revisit, and priority commitments, including `target_specs`, `required_targets`, `committed_targets`, and `priority_targets`.
- Objective-satisfaction branch derivation can infer required/planned observation counts from provider target lists/objects such as `candidate_targets`, `required_targets`, and `selected_targets` when explicit observation counts are absent.
- Nested provider source/selected/satisfied/candidate observation or activity objects preserve stable source activity IDs on the derived event.

### Collection-latency rows

- Collection-latency rows convert unsatisfied observation-delivery evidence into latency-scoped `downlink_completion_gap` events.
- Accept provider delivery aliases such as `target_latency_s`, `delivery_latency_s`, `actual_delivery_latency_s`, `collection_end_s`, and `delivery_deadline_s`.
- Plus provider data-volume aliases such as `target_data_volume_mb`, `required_volume_mb`, `min_downlink_mb`, and `selected_data_volume_mb`.
- These paths preserve objective status, selected-contact, selected-target, source-observation, latency, data-volume, and trust-boundary evidence, including stable lineage IDs from nested source/selected/satisfied/candidate observation or activity objects and missed/selected/source contact or downlink objects.

## Objective-tradeoff report replay

- Prior `source_objective_tradeoff_report` or `objective_tradeoff_report` rows, plus `objective_tradeoff_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and objective-tradeoff rows preserved in operator-review packages or Cadence-import manifests, can derive branch-local refreshes when tradeoff rows carry explicit downlink, collection-latency, or target-gap fields.
- Includes inline `target_specs`, `required_targets`, `committed_targets`, and `priority_targets`.
- Collection-latency tradeoff rows accept the same provider delivery aliases (`target_latency_s`, `delivery_latency_s`, `actual_delivery_latency_s`, `collection_end_s`, and `delivery_deadline_s`) plus provider data-volume aliases before deriving latency-window and downlink-demand events.
- Preserved evidence:
  - Branch/scenario identity, score deltas, score terms, source activity IDs, latency-window evidence, data-volume evidence, source objective status aliases.
  - Provider contact lists/objects that infer required/planned contact counts and source activity IDs.
  - Provider target lists/objects and direct observation shortfall aliases that infer required/planned observation counts.
  - Nested source/selected/satisfied/candidate observation or activity objects that preserve the singular observation source activity ID and can provide target, collection, product, payload, instrument, collection-end, deadline, and latency-measurement plus data-volume demand evidence for latency-scoped downlink refresh, even when nested contact objects also add lineage IDs, inline target priority/geometry, and trust-boundary evidence.
- Duplicate tradeoff branch identities from source and canonical reports are retained as independent pressure branches with deterministic suffixes from report source, branch/objective identity, station/target routing, source activities, required work, timing, and trust-boundary evidence, while non-duplicated tradeoff rows keep their historical unsuffixed IDs.
- Nested or flattened operator-review and Cadence-import objective-tradeoff rows use the same replay path, preserving review/import trust-boundary evidence.

## Objective label normalization and duplicate handling

- Prior/source objective-satisfaction and objective-tradeoff pressure rows normalize objective label case, whitespace, and hyphen variants before branch-local refresh derivation.
- Duplicate objective-satisfaction identities from source and canonical reports are kept as independent pressure branches using suffixes from report source, objective/routing identity, source activities, required work, timing, and trust-boundary evidence, while preserving non-duplicated IDs.

## Score-term report replay

- Prior `source_score_term_report` or `score_term_report` rows, plus `score_term_report.v1` rows embedded in prior `source_result_artifact` / `result_artifact` wrappers, and score-term rows preserved in operator-review packages or Cadence-import manifests, can now derive branch-local refreshes when score-term rows carry explicit station-routed downlink/contact gap evidence, collection-latency gap evidence, or target-routed observation/coverage gap evidence.
- Normalizes score-term key case/whitespace/hyphen variants while preserving:
  - Score-term keys, values.
  - Flat or nested provider-shaped source activity/contact/observation IDs, keeping nested observation/activity IDs as the primary source activity for collection-latency score-term events while contact objects remain additional lineage, including provider `downlink_activity_id` contact-object identifiers.
  - Provider delivery aliases for latency limits, actual delivery latency, collection-end timing, and delivery deadlines.
  - Scalar or nested provider-shaped data-identity selectors.
  - Data-volume aliases such as `target_data_volume_mb`, `required_volume_mb`, `min_downlink_mb`, and `selected_data_volume_mb`.
  - Nested source-observation/source-activity station and scenario routing for score-term collection-latency and downlink-gap events.
  - Nested target/scenario evidence for score-term urgent-target refresh, and inline nested target priority/geometry metadata.
  - Downlink-demand source lineage, inline target spec priority/geometry, including `missed_target` / `missed_targets` provider aliases.
  - Trust-boundary evidence, without guessing missing station or target context.
- Duplicate score-term row identities from source and canonical reports are kept as independent pressure branches by adding deterministic suffixes from the report source, station/target routing, source activities, demand/completion lineage, required work, timing, and trust-boundary evidence, while preserving the historical unsuffixed ID for non-duplicated rows.
- Nested or flattened operator-review and Cadence-import score-term rows replay the same branch-local refresh pressure.
