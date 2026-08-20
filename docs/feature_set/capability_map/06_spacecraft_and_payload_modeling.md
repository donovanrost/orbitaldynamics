# 6. Spacecraft and Payload Modeling

## Status overview

- **implemented** — see "Implemented" below.
- **partial** — see "Partial" below.
- **near-term** — broaden subsystem-specific constraints when calibrated data exists.
- **later** — continuous or calibrated subsystem dynamics, subsystem-specific constraints, payload pointing models, link availability, and thermal constraints.
- **out of scope** — detailed spacecraft simulation unless needed to produce planning-grade resource constraints.

## Implemented

Status: **implemented**.

### Spacecraft identity and `ResourceSummary` normalization

- `Spacecraft` exposes identity, dry mass, propellant mass, area, and drag coefficient fields. `ForceModels.AtmosphericDrag`, the public `OrbitalDynamics.atmospheric_drag_acceleration/4` facade, and opt-in scalar `Propagators.TwoBodyDrag` and `Propagators.J2Drag` consume the mass, area, and coefficient with validated atmosphere-density evidence. `J2Drag` captures those ballistic parameters once for its bounded run. Generated `circular_leo` manifest scenarios preserve those fields for `TwoBodyDrag`; `J2Drag` remains programmatic-only. Other propagators leave them as metadata.
- `SubsystemModel` exposes `subsystem_model_capability.v1` records through
  `OrbitalDynamics.subsystem_model_capabilities/0`,
  `OrbitalDynamics.battery_energy_storage_model/1`, and
  `OrbitalDynamics.data_storage_buffer_model/1`, plus
  `OrbitalDynamics.validate_subsystem_model_capability/1`. The built-in
  records declare the planning-grade battery energy-storage and data-recorder
  storage-buffer models used by selected-activity resource-flow evidence,
  including model identity, provenance, fidelity tier, state variables,
  activity-effect fields, parameters, and exact known limits. These are
  declarative model contracts, not continuous power-bus, thermal, degradation,
  partition-priority, deletion-rule, latency, or charge-dynamics simulation.
- `ResourceSummary` normalizes planning-grade fuel, power, storage, downlink, payload, antenna, degraded-mode, assumptions, and provenance rows, plus declared or provenance-inferred source quality.
- Top-level facades `OrbitalDynamics.resource_summary_from_map!/1`, `OrbitalDynamics.resource_summary_to_map/1`, and `OrbitalDynamics.resource_summaries_to_maps/1` provide standalone `resource_summary.v1` normalization. This includes:
  - clean numeric-string resource quantities and margins;
  - nested `spacecraft` / `satellite` identity aliases advertised through `ResourceSummary.capabilities/0` stable-identity metadata, with capability row semantics also naming provenance aliases and activity-type constraint lists, plus availability aliases/status tokens, degraded aliases, and margin aliases;
  - JSON-style availability booleans normalized into typed artifact fields.
- `ResourceSummary.roll_forward/3` and `OrbitalDynamics.resource_summary_roll_forward/3` expose a ResourceSummary-centered convenience facade over the schema-validated `ResourceProjection.flow_report/3` model, returning compact selected-activity storage/downlink/battery flow evidence without schedule mutation, subsystem simulation, realized-state reconciliation, or Cadence import authority. Station-calendar pressure routing preserves provider IDs, provider-entry IDs, directions, and capacity fractions for review queues. Battery flow evidence is derived only from declared activity energy consumption/generation and externally supplied resource summaries; `ResourceSummary.capabilities/0` advertises this thin selected-activity projection boundary separately from unsupported continuous subsystem propagation.
- ResourceSummary roll-forward capability metadata now also advertises the
  row-derived pressure direction and capacity-fraction maps exposed by compact
  flow summaries, so callers using the ResourceSummary facade can rely on the
  same provider/station pressure routing checks as direct ResourceProjection
  callers. The facade capability metadata also exposes the direct,
  `throughput_model`, and nested `metadata` selected-activity aliases used by
  the underlying projection for planned storage production, audit-only actual
  data volume, downlink throughput, and battery consumed/generated energy before
  flow roll-forward, with row semantics naming those storage/data-volume,
  downlink-throughput, and battery-energy alias groups for discovery.
- Resource-summary facade constructors normalize canonical and alias spacecraft identities into stable string IDs and reject unstable IDs before emitting `resource_summary.v1` rows.

### Tier 1 battery and recorder state trace

- `ResourceStateTrace.trace/3` and the public
  `OrbitalDynamics.resource_state_trace/3` facade emit an immutable,
  schema-validated `resource_state_trace.v1` from one initial
  `resource_summary.v1` battery/storage state and explicit selected-activity
  `resource_effects`. Existing trace artifacts are accepted as idempotent
  handoff inputs.
- Trace rows order effects by activity end time, start time, and stable activity
  ID. Every row carries stable trace/transition/activity identity, activity time,
  declared and applied energy/data effects, battery and recorder state before
  and after the effect, assumptions, and source provenance. Reversing source
  activity order does not change the artifact or its content-derived trace ID.
- The single Tier 1 approximation applies the complete declared effect
  atomically at activity end (or start when no end is supplied). Battery energy
  and recorder use saturate at zero and declared capacity while preserving the
  unconstrained result and exact battery/recorder overflow or depletion amount
  on the responsible activity row.
- Explicitly ignored activities retain their declared effects and ignored reason
  while applying zero effect. Malformed shapes, identity/time fields, duplicate
  activity IDs, cross-spacecraft activities, and malformed/negative effect
  quantities become deterministic operator-review rows and do not enter state
  arithmetic.
- `ResourceStateTrace.capabilities/0`, the operations capability catalog, the
  executable artifact registry, and runtime JSON Schema export declare the
  exact four effect fields, ordering, statuses, subsystem capability IDs, and
  model limits. The checked-in generated schema integration seam must be
  regenerated after lane integration. The trace does not infer undeclared
  generation or data transfer, continuously integrate overlapping activities,
  model thermal or fuel behavior, mutate schedules, claim mission calibration,
  or represent digital-twin state.

### Ground-network contact filtering (`ContactFilter`)

- `Communications.ContactFilter` plus the public facades `OrbitalDynamics.filter_contact_candidates/3` and `OrbitalDynamics.contact_filter_report/3` expose the **artifact-only** ground-network availability filter for standalone downlink, tracking, and health-check candidate lists.
- Accepts either normalized ground-network rows or singular/list-valued declared `station_calendar_provider.v1` artifacts **without provider API calls**.
- Preserves unavailable, reserved, and zero-capacity suppression rows **without provider reservation or schedule mutation**, aligning outage/maintenance precedence with station-calendar resolution while preserving reservation overlap evidence.
- **Reservation handling** — downlink candidates with a declared `station_reservation_id` or `reservation_id` matching the provider reservation continue into allocation review. Candidates with matching `station_reserved_by` / `reserved_by` ownership are treated as `station_reservation_match_status: owner_matched`, while unmatched reservation overlaps remain suppressed. `station_reservation_match_status` is carried through suppression approval, review, and import rows.
- Suppressions can optionally be classified with approval-policy evidence for blocked outage contacts, reserved-station operator review, and severe capacity reduction review.

### Resource candidate filtering (`ResourceFilter`)

- `ResourceFilter` plus the public facades `OrbitalDynamics.filter_resource_candidates/3` and `OrbitalDynamics.resource_filter_report/3` apply the same deterministic resource-summary availability/margin suppression model to standalone candidate lists. Existing `resource_filter_report.v1` artifacts are accepted as idempotent handoff inputs when adapters already hold the suppression report.
- `ResourceFilter.summary/1`/`3` and `OrbitalDynamics.resource_filter_summary/1`/`3` expose a compact artifact-only suppression summary over `resource_filter_report.v1`, including exact ResourceFilter `model_limits`, suppressed candidate IDs, suppression reason and resource-blocking-dimension counts, source-quality/trust-boundary routing maps, invalid input IDs, duplicate suppression counts, review rows, and explicit no-schedule-mutation/no-resource-propagation assumptions. Existing `resource_filter_summary.v1` artifacts are accepted as idempotent handoff inputs for compact-review adapters that already hold the summary. The schema export pins the artifact-only summary model and exact capability limits used by runtime validation. CandidateRefresh accepts direct, accepted-state, mission-state, and result-artifact-wrapped `resource_filter_summary.v1` handoffs as compact resource-filter provenance, preserving the summary contract, review rows, invalid resource-summary inputs, suppression routing, source paths, and trust boundaries without rerunning resource filtering.
- **Scoping** — single spacecraft-specific summaries are scoped to matching spacecraft or scenario IDs, retaining wildcard behavior only for ID-less single summaries.
- **Optional approval-policy evidence** — for payload/degraded-resource blockers; antenna-unavailable contact/tracking/command/uplink/health-check blockers; and margin-pressure suppressions.
- **Availability normalization** — normalizes `payload_available?`, `antenna_available?`, `spacecraft_available?`, `spacecraft_availability`, payload/antenna/spacecraft status aliases, and provider-style availability status words before suppression.
- **Activity-type constraints** — accepts explicit `suppressed_activity_types` and `incompatible_activity_types` declarations from atoms, strings, comma-separated strings, or typed maps before suppressing matching observation, contact, command/uplink, tracking, and health-check candidates as activity-type resource blockers. This includes provider activity-direction aliases such as `commands`, `sband_command`, `downlinking`, `dl`, and `tracking_pass` before those summary rows feed ResourceFilter or ResourceProjection, with schema-visible activity-type risk and blocking-dimension evidence.
- `ResourceSummary.capabilities/0` advertises the same resource availability aliases plus accepted true/false status tokens used by the normalizer.
- **Reservation/station-calendar passthrough** — preserves station reservation identity, owner/status, and `station_reservation_match_status` through resource-filter approval, review, and Cadence-import rows when candidate context supplies it, and flattens station-calendar entry identity from nested provider source evidence on suppressed rows, approval context, review rows, and import rows.

### Resource risk evidence and invalid-input preservation

- Availability suppressions carry explicit resource risk indicators into `policy_decision.v1` evidence with suppressed-row spacecraft, scenario, station, target, and direction scope, while every suppressed row carries a deterministic resource blocking dimension for operator triage even without policy classification.
- Malformed map candidates are preserved as invalid resource-filter review/import rows instead of clamping malformed feedback confidence into suppression, review, or import evidence, when they:
  - are missing stable identity;
  - carry malformed stable-ID candidate/scenario/spacecraft/station/target/source-window identity;
  - declare out-of-range contact/command success factors; or
  - are missing a usable activity kind.
- For those preserved rows, schema-facing fields are sanitized, provider station-calendar entry evidence is preserved when supplied, and optional `policy_decision.v1` evidence comes from the degraded-payload guard invalid resource-filter input rules instead of leaking through as kept candidates or weak suppressed rows.

### `resource_filter_report.v1` model limits and counts

- Emits schema-visible `model_limits` from `ResourceFilter.capabilities/0` with executable validation and JSON Schema export constants against the same capability metadata, including:
  - resource availability alias/status-token and degraded-alias metadata;
  - capability row semantics for availability suppression, margin-policy suppression, source-quality and trust-boundary count maps, station-context passthrough, invalid input review rows, candidate stable identity fields, station-calendar ID-list fields;
  - resource-margin aliases such as `storage_capacity_margin`, `downlink_capacity_margin`, and `battery_soc` before policy suppression, with `battery_soc` also feeding `power_margin` when no explicit power margin is supplied.
- `resource_filter_report.v1` carries optional capability-derived assumptions for policy fields, availability aliases and status tokens, degraded and margin aliases, provider/station direction aliases, provider result-map value keys, candidate identity fields, station-calendar ID-list fields, suppression reasons, and review statuses. Executable validation rejects stale present values while preserving older reports that omit the additive capability fields.
- Its input-summary and suppressed-resource count maps are schema-exported non-negative integer count maps, and executable validation rejects negative values before adapters consume the report.

### `contact_filter_report.v1` model limits and counts

- Emits schema-visible `model_limits` from `ContactFilter.capabilities/0`, with executable validation checking those limits against the same capability metadata, so its ground-network, provider-reservation, schedule-mutation, and link-budget limits are inspectable without assumptions prose.
- Exposes row-derived `station_reservation_match_status_counts` so Cadence-facing adapters can route reserved-station matches and overlaps without scanning suppressed rows.

### Ambiguity handling in contact and resource suppression

- Contact and resource suppression preserve same-priority direct ground-network ambiguity evidence, so overlapping outage or reserved rows still suppress contacts without choosing arbitrary entry or reservation metadata, while conflicting reduced-capacity ties stay review-visible without inventing a single capacity value.

### Contact/antenna boundary and review gating

- Contact and resource suppression treat the following as the same contact-schedule/antenna-resource boundary:
  - native downlink, tracking, command, uplink, and health-check rows;
  - direction-bearing `planned_contact` or provider `contact` rows, including `station_id`-only provider rows and nested `station` / `ground_station` identity objects;
  - provider-shaped station/time rows that omit explicit type or direction, plus direction-only command/uplink/health-check station windows.
- Command/uplink suppressions are lifted as `command_review` requirements and health-check suppressions as `health_check_review` requirements onto operator-review and Cadence import rows for adapter routing.
- Command/uplink contacts are left out of downlink-margin suppression, and command-result rows without command type/direction are kept review-gated.
- **Duplicate-ID disambiguation** — contact-filter suppressed rows disambiguate duplicate suppressed candidate IDs with deterministic suffixes while preserving the original candidate ID as `base_candidate_id`.
- Contact-filter suppressed rows also preserve station-calendar overlap, reservation-list, and ambiguous-entry metadata plus schema-safe provider result labels, contact/command success flags, feedback confidence factors, and source labels through approval-policy context, operator-review rows, and Cadence-import rows without creating new suppressions from valid feedback alone. Out-of-range contact/command feedback confidence is review-gated as invalid contact input instead of being clamped into policy, review, or import evidence.

### Resource-filter suppressed-row handling

- Uses the same deterministic duplicate-ID disambiguation so review/import artifacts do not collapse separate resource suppressions with the same source candidate ID.
- Resource-filter suppressed downlink/contact rows preserve schema-safe provider result labels, contact/command success flags, feedback confidence factors, command results, and source labels through approval-policy context, operator-review rows, and Cadence-import rows without turning feedback evidence into a new resource suppression. `ResourceFilter.capabilities/0` exposes the provider-result map keys used to derive those schema-safe result labels.
- Resource-filter reports keep input-summary source-quality and trust-boundary counts distinct from row-derived `suppressed_resource_source_quality_counts` and `suppressed_resource_trust_boundary_status_counts`, while invalid external resource summaries are preserved as `invalid_resource_summary_input` review evidence and excluded from suppression decisions (including explicit storage or battery derived margins that contradict supplied capacity/used evidence).

### Cross-checking validation

- Executable validation cross-checks:
  - contact/resource filter suppressed-candidate totals;
  - contact-filter kept counts;
  - invalid-input IDs;
  - non-negative input-summary resource count maps;
  - contact-filter station trust-boundary counts;
  - resource-filter invalid-candidate counts/IDs;
  - invalid-summary counts/IDs;
  - suppressed-resource count maps;
  - duplicate suppressed-ID summaries plus duplicate-row group size/index coverage against emitted suppressed rows.
- Keeps suppressed-row reservation-overlap counts aligned with reservation ID lists.

### V3 branch ground-station events

- V3 branch ground-station outage/reservation and reduced-capacity events apply to the same native-downlink plus direction-`downlink` `planned_contact` boundary for downlink capacity.
- Outage/reservation events also mark typed tracking and health-check station activities as missed and remove matching branch-local tracking/health-check candidates, preserving ground-station and reservation context on the synthesized realized-feedback rows.
- Reduced-capacity events populate the station-capacity fields consumed by link-capacity and resource-projection artifacts.
- V3 downlink-completion objectives use the same direction-aware downlink predicate when counting planned contacts, staging branch-local candidates, calculating completion ratios, and emitting proposed-contact handoff rows.
- V3 branch ground-station outage/reservation/capacity events accept `station_id` as an alias for `ground_station_id` in branch-local refresh filters, capacity adjustments, and risk explanations.
- Downlink completion and collection-latency objectives preserve that station alias plus nested `spacecraft` / `satellite` selector identity through derived gap events and candidate matching.

### `candidate_refresh.v1` and station inputs

- Standalone `candidate_refresh.v1` turns station-scoped collection-latency objectives into the same required-downlink demand fields, score terms, throughput-model context, and activity context used by explicit downlink-completion objectives, including the campaign-compatible `required_throughput_mb`, `required_volume_mb`, and `min_downlink_mb` demand aliases.
- Declared `ground_network` rows that use `station_id` feed standalone contact filtering, candidate-refresh station capacity/availability annotations, and V3 mission-state derived branch generation instead of being treated as unrelated stations.
- Candidate refresh treats provider `capacity_percent` / `station_capacity_percent` aliases and nested throughput/capacity/activity context as station-capacity evidence before scoring generated downlinks.
- `study_manifest.v1` exposes the same alias for campaign and candidate-refresh ground-network inputs while normalizing campaign entries into canonical `ground_station_id` metadata.
- Mission-plan contact activities in study manifests accept `station_id` for downlink, tracking, command, and planned-contact station context while preserving canonical activity metadata.

### Candidate-refresh fallbacks from mission/accepted state

- Candidate refresh consumes mission-state and accepted-state fallback targets, resource summaries, ground-network rows, and station-calendar providers when the explicit refresh request omits those top-level inputs, so branch-local refreshes can derive candidate priority, resource filtering, and station suppression from the current mission snapshot without duplicating all inputs at the refresh boundary.
- Accepted-state target, ground-network, and resource-summary fallbacks are advertised and regression-tested so durable planning-state snapshots can drive target value, suppress branch-local contacts, and suppress branch-local resource candidates while preserving source-quality and trust-boundary evidence.
- Mission-state spacecraft identity takes precedence over accepted-state spacecraft identity for objective and resource scoping, while accepted-state spacecraft rows remain the fallback when mission-state rows are absent.
- Accepted-state current-epoch and remaining-horizon fallbacks are likewise advertised and regression-tested so mission-state or durable planning snapshots can provide freshness timing and bound branch-local refreshes when the executable request omits those timing fields.

### Feedback-derived constraints and prior activities

- Operational feedback resource-availability overrides can add summary-level `suppressed_activity_types` and `incompatible_activity_types` constraints before refresh filtering, so branch-local resource restrictions derived from feedback suppress matching refreshed candidates through the same `resource_summary.v1` and `resource_filter_report.v1` evidence path as explicit resource summaries.
- Candidate-refresh manifest `prior_candidate_activities` expose provider-shaped `station_id`, nested `station` / `ground_station` identity objects, and direction fields — including provider direction aliases and direction-only command/uplink/tracking/health-check station windows with station and time context — so stale prior contact rows can use the same semantic diff path as runtime refresh requests.

### `candidate_refresh.v1` resource emission and replay provenance

- `candidate_refresh.v1` emits `resource_summary.v1` rows and a `resource_filter_report.v1` when resource summaries suppress unavailable payload candidates, antenna-unavailable downlink/tracking candidates, or configured fuel, power, storage, downlink, and externally supplied thermal margin thresholds.
- Replayed resource-projection and resource-filter margin feedback supersedes stale capacity/used derivation inputs on the affected summary, so reviewed storage-margin pressure still drives suppression instead of becoming an invalid resource-summary input (including resource source-quality counts for the input summaries).
- Source `resource_projection_report.v1` artifacts — including rows replayed from operator-review packages and Cadence-import manifests — preserve projected resources and direction-scoped activity routing separately from invalid projection activity or summary inputs in candidate-refresh source-report provenance, so reviewed invalid projection evidence remains audit-visible without being replayed as resource feedback.
- Candidate-refresh storage/downlink pressure replay preserves all-contact plus selected/deferred capacity-pack station contact-ID maps, capacity-pack contact counts, per-status demand maps, status contact-ID maps, requirement-source counts/contact IDs, packed/deferred ID sets, reduced-capacity pack group counts/status/ID routing, all/selected/unused capacity-adjusted throughput row counts plus station/direction maps, and actual-throughput row-count pressure alongside resource-projection direction counts, activity-ID maps by direction, ground-station, source-window, station-calendar entry, provider ID, and provider-entry ID routing by pressure type, allowing branch-local station, access-window, direction, and provider-adapter pressure queues to inspect the composed replay summary without reopening activity-resource flow rows.
- Candidate-refresh contact-intent replay now exposes a compact direction-routing map that groups contact count, contact IDs, capacity-pack contact IDs, and required-capacity fraction by direction, so branch-local downlink, command, tracking, and health-check refresh queues can route contact-intent pressure without reopening raw intent rows.
- Candidate-refresh contact-allocation replay preserves provider-reservation request-ready, review-required, and no-request contact-ID maps by direction and by direction/ground station, letting branch-local station and direction queues separate downlink, command, tracking, and uplink reservation pressure without reopening provider request rows.
- Source `resource_filter_report.v1` artifacts replayed from review/import handoffs likewise preserve invalid resource-summary inputs separately from suppressed candidates in candidate-refresh provenance, keeping invalid resource-state evidence review-visible without turning it into operational feedback.
- Candidate-refresh resource-filter replay preserves suppressed-candidate
  direction counts and candidate-ID maps by direction, so downlink, command,
  tracking, and health-check resource suppression pressure can be routed without
  reopening suppressed rows.
- Standalone resource-filter reports preserve malformed non-map candidate handoffs as `invalid_candidate_input` review/import evidence instead of crashing or dropping them before resource checks.

### Operational-readiness gates and reusable activity context

- Operational-readiness and quality-gate reports surface unavailable resource evidence as an explicit `resource_availability` gate with row-derived unavailable-resource reason counts and station-specific availability reason count maps, so import-readiness queues can route spacecraft, payload, antenna, degraded-payload, station-reservation, and station-availability pressure from direct quality-gate row IDs/counts without reopening projection or suppression rows.
- Refreshed candidate-activity rows carry reusable `activity_context` with stable activity/timeline identity and source-window provenance, so downstream diff, review, and import paths can consume the same identity shape without reconstructing it from raw candidate fields.

### V1 campaign resource projection

- V1 campaign artifacts can project selected activities against campaign-manifest `resource_summaries` in `resource_projection_report.v1`, carrying:
  - source-quality and declared-vs-missing trust-boundary status onto each projection row;
  - non-negative scalar resource/activity counters;
  - top-level row-derived `resource_source_quality_counts` and trust-boundary status counts;
  - capability row semantics for both count maps;
  - JSON Schema-exported non-negative integer counters and count maps with executable negative-value rejection;
  - runtime and JSON Schema model identity checks for the thin standalone,
    campaign, repair, strategy-branch, and battery-handoff projection variants;
  - schema-typed payload and antenna availability flags.
- Consumes station-capacity-adjusted downlink throughput when contact calendars
  or contact-allocation rows reduce usable transfer, including top-level,
  metadata, or nested throughput-model estimated downlink aliases. Contact
  allocation `capacity_pack_capacity_fraction` rows feed the same typed
  unit-interval capacity path before projection. Deferred, blocked, or
  policy-blocked contact-allocation rows remain visible as ignored flow evidence
  instead of relieving storage or consuming projected downlink capacity, while
  delivered/received realized data-volume aliases remain **audit-only evidence**
  rather than resource-state reconciliation.

### Compact resource-flow summaries

- Compact resource-flow summaries can be derived either directly from selected activities plus `resource_summary.v1` rows or from an existing `resource_projection_report.v1`, so adapters can inspect storage/downlink roll-forward, projected remaining storage/downlink capacity, pressure evidence, and row-derived actual-vs-planned data-volume variance without reopening original planner inputs.

### Invalid external summaries in projection

- Malformed external resource summaries are preserved as `invalid_resource_summary_input` review evidence and excluded from projection math when they have: invalid stable identity; negative capacity or used quantities; out-of-range margins; or explicit derived storage/battery margins that disagree with supplied capacity/used evidence. Invalid activity and invalid resource-summary `review_status` is constrained to `operator_review_required` by executable validation and exported JSON Schema.
- Duplicate valid external summaries for the same spacecraft or wildcard projection scope are also excluded from projection math and preserved as invalid-summary review/import rows with source-summary evidence instead of silently choosing one summary as authoritative.
- ID-less wildcard summaries mixed with scoped summaries are review-gated before projection so the wildcard fallback cannot double-count activities or compete with spacecraft-specific state.

### Resource-pressure approval and provider-calendar direction context

- Projected storage overflow and downlink shortfall rows preserve typed `review_resource_projection` approval requirements plus deterministic resource-pressure status/type context when an approval policy is supplied, including the first pressure activity's contact direction, ground station, station-calendar entry, provider ID, provider-entry ID, and normalized `station_calendar_directions`, so resource-pressure policy matches, review rows, and Cadence import rows can route provider-calendar direction evidence without reopening nested flow rows.
- Source station-calendar entry/overlap capacity fractions, provider
  `capacity_pack_capacity_fraction`, and provider `capacity_percent` /
  `station_capacity_percent` aliases feed the effective downlink roll-forward,
  first-pressure capacity context, and overlap-sourced provider entry/direction
  context, while out-of-range capacity fractions or percentage aliases are
  review-gated before roll-forward.

### `ResourceProjection` and flow artifacts

- `ResourceProjection` plus the public facade `OrbitalDynamics.resource_projection_report/3` expose the same thin storage/downlink projection model for standalone selected-activity lists. Existing `resource_projection_report.v1` artifacts are accepted as idempotent handoff inputs when adapters already hold the full projection report.
- `ResourceProjection.flow_report/3`, `ResourceProjection.flow_summary/1`, `OrbitalDynamics.resource_projection_flow_report/3`, and `OrbitalDynamics.resource_projection_flow_summary/1` provide a compact schema-validated `resource_projection_flow_summary.v1` selected-activity flow artifact derived from a new or existing projection. Existing `resource_projection_flow_summary.v1` artifacts are accepted as idempotent handoff inputs so adapters that already hold compact flow evidence do not need to reopen full projection rows, including:
  - row-derived storage/downlink/battery pressure evidence;
  - flattened `activity_resource_flow` rows;
  - resource-pressure type counts;
  - spacecraft ID routing by pressure type;
  - activity ID routing by pressure type;
  - ground-station ID routing by pressure type for station-scoped downlink
    pressure;
  - source-window ID routing by pressure type for collection/access-window
    pressure;
  - station-calendar entry ID routing by pressure type for provider-calendar
    pressure;
  - station-calendar provider ID and provider-entry ID routing by pressure type
    for provider adapter pressure queues;
  - ignored zero-effect activity counts, reason counts, IDs, and IDs by
    ignored-effect reason;
  - aggregate selected-flow storage/downlink/battery quantities;
  - row-derived invalid activity and invalid resource-summary counts plus ID lists;
  - first-pressure ground-station, direction, and source-window payloads;
  - explicit no-schedule-mutation / no-subsystem-simulation assumptions and the
    status-aware ignored-effect model for terminal or approval-rejected
    activities **without introducing a new propagated state model**;
  - schema-validated `model_limits` copied from `ResourceProjection.capabilities/0`.
- `ResourceProjection.capabilities/0` and the ResourceSummary roll-forward
  capability metadata advertise the exact `subsystem_model_capability.v1`
  battery and storage record IDs behind the selected-activity flow assumptions,
  so discovery clients can link flow evidence to declarative model contracts
  without treating the roll-forward as propagated subsystem state.
- Generated `resource_projection_report.v1` artifacts and derived
  `resource_projection_flow_summary.v1` artifacts also carry those exact
  subsystem capability contract/ID assumptions, and runtime validation rejects
  stale assumption values when adapters provide them, while keeping the fields
  additive for older artifacts.
- V1 `campaign_plan.v1` artifacts attach that compact flow summary whenever
  selected-activity resource projection is available, letting campaign-level
  review/import queues route storage, downlink, ignored-activity, and pressure
  evidence without reopening full projection rows or mutating schedules.
- Capability metadata advertises the report and flow-summary public facades plus operator-review/Cadence-import handoff artifact contracts and `resource_projection_review` / `review_resource_projection` action names, plus:
  - resource availability alias/status-token metadata;
  - degraded-alias metadata;
  - station/source station-calendar and contact-allocation capacity
    fraction/percent path metadata used before downlink projection roll-forward,
    including typed fraction/percent capacity-value path metadata for both
    direct activity and source station-calendar evidence;
  - resource-margin aliases such as `storage_capacity_margin`, `downlink_capacity_margin`, and `battery_soc` used before storage/downlink/battery roll-forward;
  - resource-provenance aliases (`resource_source_quality`,
    `provenance.source_quality`, `provenance.resource_source_quality`,
    `provenance.quality`, `resource_trust_boundary`,
    `provenance.trust_boundary`, and `provenance.resource_trust_boundary`)
    accepted before source-quality and trust-boundary routing;
  - planned data-volume aliases (`planned_data_volume_mb`, `data_volume_mb`,
    `estimated_data_volume_mb`, and nested `metadata` variants) that can feed
    storage production when explicit storage estimates are absent, plus
    audit-only actual data-volume aliases (`actual_data_volume_mb`,
    `actual_storage_mb`, `actual_downlink_mb`, `delivered_data_mb`,
    `received_data_mb`, and nested `metadata` variants);
  - estimated/planned downlink throughput aliases (`estimated_throughput_mb`,
    `estimated_downlink_mb`, `planned_throughput_mb`, and nested
    `throughput_model` / `metadata` variants) consumed before station capacity
    adjustment;
  - declared battery-energy consumed/generated aliases
    (`estimated_energy_used_wh`, `estimated_battery_energy_used_wh`,
    `planned_energy_used_wh`, `battery_energy_used_wh`,
    `estimated_energy_generated_wh`, `estimated_battery_energy_generated_wh`,
    `planned_energy_generated_wh`, `battery_energy_generated_wh`, and nested
    `metadata` variants) consumed before battery state projection;
  - the activity stable-identity fields used for invalid-input review.
- Carries consumed/generated/net battery-energy aggregates and peak battery overuse through schema-visible, executable-validated handoff rows, plus declared collection-to-delivery latency evidence with planned/actual latency values, latency margin/status, aggregate latency review counts, late activity routing, and a declared-timestamp-only latency-model assumption.
- Carries projected remaining storage/downlink capacity through operator-review and Cadence-import rows, and preserves the flow-summary total/minimum remaining-capacity context alongside source flow-summary evidence.
- **Scoping** — single spacecraft-specific summaries are scoped to matching spacecraft or scenario IDs while retaining wildcard behavior only for ID-less single summaries, with wildcard rows using stable `all_spacecraft` identifiers and mixed wildcard/scoped summary inputs routed to invalid-summary review instead of emitting a competing `unscoped_resource_summary` projection row.

### Maneuver-review artifact boundary

- `maneuver_review_report.v1` exposes its artifact-only no-command-execution and
  no-schedule-mutation model limits as an exact runtime and JSON Schema export
  boundary, so maneuver review handoffs cannot rely on stale free-form
  assumptions when routing finite-burn or execution-uncertainty review evidence.

### `activity_resource_flow` roll-forward

- Includes deterministic `activity_resource_flow` rows that order selected activities by schedule time and stable ID while rolling forward: storage used, storage delta, planned downlink capacity, storage-limited downlinked volume, unused downlink capacity, running downlink demand, declared battery energy consumption/generation, projected battery state of charge, margin-after, overflow, shortfall, and battery-depletion values from externally supplied summaries and activity estimates.
- Estimated downlink throughput aliases (`estimated_throughput_mb`,
  `estimated_downlink_mb`, `planned_throughput_mb`, and nested
  `throughput_model` / `metadata` variants) feed planned downlink capacity
  before station capacity fractions are applied.
- Selected observation activities use planned data-volume aliases
  (`planned_data_volume_mb`, `data_volume_mb`, and `estimated_data_volume_mb`)
  as storage-production inputs when explicit storage estimates are absent, while
  actual/delivered/received data-volume evidence remains audit-only and does
  not reconcile projected resource state.
- Declared battery-energy consumed/generated aliases
  (`estimated_energy_used_wh`, `estimated_battery_energy_used_wh`,
  `planned_energy_used_wh`, `battery_energy_used_wh`,
  `estimated_energy_generated_wh`, `estimated_battery_energy_generated_wh`,
  `planned_energy_generated_wh`, `battery_energy_generated_wh`, and nested
  `metadata` variants) feed battery consumption/generation before projected
  battery state and overuse are derived.
`ResourceProjection.capabilities/0` advertises the direct and nested metadata
paths used for planned storage-production inputs, audit-only realized
data-volume evidence, and declared battery-energy roll-forward evidence.
- Explicit flow `completed_fraction` values and completion aliases are accepted only as clean unit-interval evidence, while out-of-range declarations are preserved as invalid activity inputs for review/import instead of being clamped into flow rows.
- Malformed declared storage/downlink/battery resource estimate strings are likewise review-gated instead of being projected as zero-effect evidence.
- Externally supplied negative `thermal_margin_c` is promoted to planning-grade thermal resource pressure through policy/review/import handoffs **without thermal propagation**.
- Actual/planned completion ratios remain visible as ratios.
- Preserves station-calendar entry/direction context on the flow row that first creates resource pressure, including provider and provider-entry identity when the pressure came from provider-calendar context, plus the effective station capacity fraction used for reduced-capacity downlink relief. The first-pressure source-window identity remains visible in strategy tradeoff, risk, operator-review, and Cadence-import rows without reopening nested flow evidence.

### Availability pressure rows

- Summaries that declare `spacecraft_available: false`, `spacecraft_available?`, `spacecraft_availability`, or `spacecraft_status`/provider-style unavailable status words become `spacecraft_unavailable` resource pressure rows with selected activity effects ignored at zero storage/downlink impact.
- Payload/antenna availability status aliases likewise zero out affected observation/contact effects as resource-availability pressure.
- Explicit summary-level `suppressed_activity_types` and `incompatible_activity_types` declarations zero out matching selected activity effects as resource-availability pressure, with flow-row, projection-row, policy-review, operator-review, and Cadence-import preservation of the declared activity-type lists and ignored-effect reasons.
- First-pressure activity context, policy-review classification, and review/import preservation of the spacecraft, payload, and antenna availability evidence are retained.

### Invalid resource-projection inputs

- Malformed selected activity inputs are preserved as invalid resource-projection input review/import rows with schema-facing fields sanitized — instead of raising, disappearing, or improving projected state before per-spacecraft roll-forward — when they are:
  - missing stable identity;
  - carrying malformed activity/scenario/spacecraft/station/target/source-window stable-ID values;
  - missing activity type;
  - declaring malformed station-capacity evidence; or
  - declaring malformed or negative storage, throughput, or battery energy quantities.
- Those invalid activity and resource-summary rows can carry approval-policy evidence through operator-review and Cadence-import handoffs.
- Executable validation cross-checks resource-projection invalid-input counts, valid-input counts, and invalid activity IDs against those preserved invalid-input rows, while also validating projected-resource activity/observation/downlink counters as non-negative integers and deriving input resource-summary counts and top-level warnings from `projected_resources`.

### Provider-shaped downlink rows and direction aliases

- Provider-shaped direction-`downlink` contact rows — including `station_id`-only rows and nested `station` / `ground_station` identity objects, and provider-shaped station/time rows that omit explicit type or direction — consume downlink capacity and relieve projected storage through the same roll-forward path as native downlinks and planned downlink contacts.
- Provider direction aliases such as `down`, `downlinking`, `dl`, `commands`, `sband_command`, `s_band_command`, and `tracking_pass` canonicalize before resource filter suppression, resource-projection roll-forward, resource-summary activity-type suppression, and station-calendar direction context preservation, while command/uplink contacts and command-result rows without command type/direction remain resource-neutral or review-gated.

### Projection policy classification

- Resource projection rows can optionally carry `policy_decision.v1` evidence for projected storage overflow, downlink shortfall, or battery depletion, and V1/V2/V3 planner embedded resource projections pass their approval policy into that row-level classification.
- Operator-review and Cadence-import rows lift the effective/ignored activity counts and ignored activity IDs so terminal or rejected zero-effect activities remain visible without unpacking the nested resource flow. Flow summaries also expose ignored activity reason counts and IDs by ignored-effect reason for review/import triage.
- Executable validation cross-checks resource-pressure status/type fields plus first-pressure activity pointers against projected overflow/shortfall/battery-depletion fields and `activity_resource_flow` while rejecting duplicate nested flow activity IDs.

### Planner integration (V1/V2/V3)

- V1 campaign planning applies the same thin resource summary availability/margin filter before ranking, emitting `resource_filter_report.v1` with source-quality and trust-boundary status counts when summaries are supplied and preserving campaign approval-policy evidence on suppressed resource rows.
- V2 repair and V3 branch repair preserve source resource summaries and source
  resource-filter reports from candidate-refresh artifacts. V2 declares its
  optional `source_resource_summaries` array with direct `resource_summary.v1`
  item-contract evidence in the generated schema and runs the standalone row
  validator before consuming those summaries.
- V3 branch products emit `resource_projection_report.v1` when branch repair has source resource summaries.
- Resource projection roll-forward is status-aware, preserving terminal or approval-rejected activities in the flow audit while assigning them zero projected resource effect, preserving approval rejection as the ignored reason even when the activity is also terminal. The same flow rows preserve planned/actual data-volume and completion-fraction evidence without using realized feedback to reconcile projected resource state, and compact summaries derive actual-volume evidence counts, total actual volume, total data-volume delta, and under/over/exact activity ID routing from those rows for audit-only review.
- Capacity-only downlink resource summaries do not synthesize branch-level low-downlink risk for observation-only missions without a declared downlink-completion requirement.

### Branch-comparison and branch-risk surfacing (V3)

- Branch-comparison rows surface projected storage/downlink/power margins,
  projected remaining storage/downlink capacity, storage-limited downlink
  utilization, unused downlink capacity, first-pressure direction,
  ground-station, station-calendar entry, and station-calendar directions, plus
  first-pressure source-window identity and payload evidence, plus explicit
  overflow/shortfall/battery-overuse values for operator review.
- V3 branch risk indicators promote projected storage overflow, downlink shortfall, battery depletion, externally supplied negative thermal margin pressure, and resource-summary activity-type suppression/incompatibility pressure into branch-level risks with the same first-pressure direction and station-calendar context where present, including provider and provider-entry identity.
- They also promote `spacecraft_unavailable`, payload-unavailable, degraded-payload, and antenna-unavailable projection rows into branch-level availability risks, so approval policy and recommendation ranking can block or route resource-pressure futures with the same first-pressure activity context.
- Branch-comparison rows flatten unavailable-spacecraft, payload-unavailable, degraded-payload, antenna-unavailable, and availability-pressure-type counts and stable IDs from resource projection rows for operator scanning.
- Branch-derived station risks preserve canonical `ground_station_id` evidence so station-scoped policy can classify branch risk indicators without crossing provider stations.

## Partial

Status: **partial**.

- Resource summaries remain normalized artifact inputs with the existing thin
  availability/margin filter and status-aware `ResourceProjection` defaults.
  The opt-in `resource_state_trace.v1` advances battery/recorder behavior to a
  time-indexed discrete state sequence, but no campaign, repair, strategy, or
  search path consumes that trace as hard pre-selection feasibility yet. That
  planner-eligibility integration belongs to the separate constraints/search
  lane.

### Map input normalization

- Map inputs accept:
  - the struct-style `payload_available?`, `antenna_available?`, and `degraded?` aliases;
  - payload/antenna/spacecraft status aliases;
  - JSON/provider status words such as `available`, `unavailable`, `offline`, `down`, `outage`, `maintenance`, and `enabled` for availability booleans, while exporting the canonical JSON field names used by artifacts.
- Preserve optional `spacecraft_available` as a schema-visible resource-summary field.
- Preserve optional battery capacity, energy-used, generated-energy, and state-of-charge fields while accepting `battery_soc` as a caller-facing alias for the canonical `battery_state_of_charge` and common generated-energy aliases such as `estimated_battery_energy_generated_wh` for `battery_energy_generated_wh`.
- Preserve optional externally supplied `thermal_margin_c`.
- Reject negative capacity/used resource quantities.
- Enforce unit-interval persisted margin and battery state-of-charge fields in executable validation and exported JSON Schema.
- Reject explicit `storage_margin` and `battery_state_of_charge` values that contradict supplied capacity/used evidence.
- Standalone and nested `resource_summary.v1` schemas expose the same battery, thermal, spacecraft availability, trust-boundary, non-negative capacity, and bounded margin fields.
- Derive planning-grade `power_margin` from battery state of charge only when an explicit power margin is absent.
- `storage_capacity_margin` and `downlink_capacity_margin` are accepted as caller-facing aliases for the canonical `storage_margin` and `downlink_margin`, with `ResourceSummary.capabilities/0` advertising degraded, margin, and unit-interval aliases alongside resource availability alias/status-token metadata.

### Provenance and activity-type constraint ingress

- Flattened resource-handoff provenance aliases (`resource_source_quality` and `resource_trust_boundary`, including nested provenance forms) are accepted at resource-summary, resource-filter, and resource-projection ingress and exported back to the canonical `source_quality` and `trust_boundary` fields. `ResourceProjection.capabilities/0` advertises the exact source-quality and trust-boundary alias paths used before row-derived routing counts.
- Standalone resource-summary facades normalize and export explicit `suppressed_activity_types` and `incompatible_activity_types` declarations as deterministic string arrays so those summary-level activity constraints remain schema-validated before resource filtering or projection consumes them.

### Resource-filter unavailable/ambiguous handling

- Resource-filter reports treat explicit, refresh-feedback, and branch-generated spacecraft-level unavailable summaries as `spacecraft_unavailable` suppressions with `spacecraft_health` blocking evidence carried through operator-review and Cadence-import rows.
- Duplicate valid resource summaries for the same spacecraft or wildcard scope become explicit `ambiguous_resource_summary` suppression rows for matching candidates instead of letting source order choose a hidden resource state, preserving the source summary rows and quality/trust-status sets through operator-review, Cadence-import, and candidate-refresh handoffs.
- Resource suppressions preserve externally supplied battery capacity, energy-used, state-of-charge, thermal margin, and spacecraft mode through resource-filter rows, approval-policy activity context, contact-allocation rows, operator-review rows, and Cadence-import handoff, and kept candidates are annotated with the source resource summary that made the resource check pass, with contact allocation advertising thermal-margin evidence preservation as an executable row semantic.

### Thermal-margin policy threshold

- Resource filters can apply `min_activity_thermal_margin_c` as an artifact-level policy threshold, emitting `thermal_margin_below_policy` suppressions with a `thermal` blocking dimension while still treating the margin as externally supplied evidence rather than propagated thermal state.
- `ResourceFilter.resource_filter_policy/1` and `OrbitalDynamics.resource_filter_policy/1` normalize the advertised policy threshold fields before filtering, so callers can inspect the effective fuel, thermal, observe-power/storage, and downlink threshold map without running candidate suppression.
- V3 campaign strategy branch derivation recognizes those prior resource-filter suppressions as `thermal_margin_c` pressure, carries the report policy threshold into branch-local refresh, and exposes the resulting thermal margin on branch comparison rows.

### Caveats

- Capability metadata labels the summary as **externally supplied and planning-grade**.
- Drag and area fields are consumed by the atmospheric-drag evaluator and opt-in
  scalar two-body-drag and J2-drag propagators; they are not used by the
  existing J2 default, accelerated propagators, or resource simulation.

## Near-term

Status: **near-term**.

- Broaden subsystem-specific capability records and constraints when calibrated
  data exists.
- Consume typed trace limit evidence at the owned constraint/search boundary
  without changing the existing greedy planner or projection defaults.
- Add `spacecraft_model.v1` once enough subsystem records exist to justify a
  composed spacecraft configuration artifact.

## Later

Status: **later**.

- Continuous resource propagation, overlap/concurrency dynamics,
  subsystem-specific constraints, payload pointing models, link availability,
  thermal constraints, and calibrated spacecraft-specific behavior.

## Out of scope

Status: **out of scope**.

- Detailed spacecraft simulation unless needed to produce planning-grade resource constraints.
