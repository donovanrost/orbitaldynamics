# V2 Repair Artifact

`campaign_repair.v2` preserves the source plan boundary while showing the
operator what changed.

## Top-level fields

- `source_plan_id`, `current_epoch_s`, and `remaining_horizon`
- repaired `activities`, `deltas`, and `change_summary`
- `approval_requirements`, `approval_status`, and `policy_decision`
- `realized_state_snapshot` and repair-time operational context
- `repair_metadata` with deterministic repair identity and timeline-protection
  summaries

All fields emitted by the checked V2 repair artifacts are represented in the
generated `campaign_repair.v2` property surface. The additive `study_id`,
`source_planner`, `change_summary`, `preserved_activities`, and
`approval_rule_matches` fields remain optional for older repairs, but populated
values are executable-validated. Change counts must equal the delta
`repair_action` frequencies, preserved activities must equal the preserved
subset of repaired activities in order, study identity must be stable, and
approval rule-match rows run the shared policy validator.

### `realized_state_snapshot`

- **Nested spacecraft-state rows** require a scenario identity and are validated
  for:
  - stable spacecraft/scenario identifiers
  - mode/status/payload-status strings
  - degraded flag
  - payload/antenna availability
  - incompatible-activity string arrays
  - source path/object provenance
  - metadata object shape
- **Request normalization** — repair/strategy request normalization maps legacy
  row `id` into `scenario_id` and records dropped identity-less and
  invalid-identity rows as separate snapshot metadata counts.
- **Metadata** exposes typed snapshot/source/feedback-boundary fields and
  non-negative dropped-row accounting for invalid realized spacecraft-state
  inputs. When snapshot metadata declares provider or adapter identity,
  executable validation requires a direct or provenance-supplied
  `trust_boundary` before accepting the snapshot as provider feedback.
- **`model_limits`** declares that the snapshot is provider feedback evidence,
  not ground-truth reconstruction, schedule mutation, or subsystem state
  estimation.

## Embedded reports

### `source_timeline_feedback_report`

Emitted when realized activities are supplied. It preserves planned-vs-realized
timing, status, contact, command, and normalized source activity reconciliation
for review/import rows.

- **Exported schemas** also type this nested report's rows, status counts, and
  operational-feedback maps when a repair result is embedded in a V3 strategy
  branch, so downstream tools can inspect the feedback handoff without treating
  it as an opaque object.
- **Carry-forward to V3** — if the repair artifact becomes a V3 strategy source
  plan, its `operational_feedback` maps are carried forward as normalized
  strategy feedback before explicit V3 request overrides. This includes
  downlink-demand feedback derived from realized observation data volume or
  partial/failed station contacts with declared required downlink.
  Source-derived downlink demand can create a branch-local generated refresh
  with station-specific required-downlink evidence.
- **V3 mission-state realized observation telemetry** can derive default
  downlink demand from:
  - actual data volume
  - provider-style delivered/received data aliases
  - completed fractions over planned/estimated data-volume aliases
- It can also derive target-priority overrides from realized observation
  priority. Realized downlink telemetry can derive station-specific demand when
  a partial/failed contact carries required-downlink evidence plus
  actual-throughput/downlink/delivered/received aliases.
- It can also derive station-throughput feedback when required downlink is the
  only available expected-throughput denominator. Delayed or otherwise
  non-success telemetry rows emit only the feedback facets they actually
  support instead of fabricating contact or observation success rates.
- **Timeline feedback reports** use the same required-downlink denominator for
  station-throughput feedback when planned throughput is absent.
  `operational_feedback_provenance` records:
  - merge order
  - input keys
  - source counts
  - source-level input keys for mission-state realized telemetry
  - source-report counts and row counts
  - operator-review source type/action/queue counts
  - trust-boundary status
- Executable validation rejects provenance that claims zero source reports
  while carrying source-report rows.

### `operational_timeline_report`

Over the repaired activity list, with V3 branch repair rows promoted to
strategy operator-review and Cadence import queues using branch-scoped
provenance.

### `timeline_transition_application_report`

Compares source-plan activities to repaired activities. It preserves the
artifact-only selected safe subset and withholds review-gated replacements from
automatic application. It routes review-required transition applications into
the embedded operator-review and Cadence-import queues with repair
approval-policy evidence when a policy rule matches transition status,
application status, action, or protection context.

### `command_window_report`

Over repaired command/tracking/health-check/uplink windows, so
command-boundary reviews are visible at the repair artifact boundary.

### `constraint_report`

Over inherited planner-local max-timeline-activity, minimum-duration, and
eclipse-avoidance constraints evaluated against the repaired activity set.

- **Planner-local constraints** accept legacy scalar or boolean values, plus
  `{value, severity}`, `{threshold, severity}`, or `{enabled, severity}` maps
  that route violated local constraints as warning rows when severity is
  `warning`.
- **Embedded V3 branch** repair constraint violations are promoted with
  `branch_id` into `constraint_review` and `review_constraint` gates.

### `score_term_report` and `objective_tradeoff_report`

Over repaired activity value, churn, and schedule-move score terms.

- These rows are also lifted into top-level repair `score_term_review`,
  `objective_tradeoff_review`, `review_score_term`, and
  `review_objective_tradeoff` queues.
- When embedded in V3 branch repair results, the same rows lift into strategy
  operator-review and Cadence import queues with `branch_id` and
  `campaign_strategy.branches.repair_result.*` source provenance.

### `link_capacity_report`

Over repaired downlink activities and fixed-rate throughput assumptions. Those
rows are also lifted into top-level repair `link_capacity_review` and
`review_link_capacity` queues.

### `contact_allocation_report`

Over repaired contact activities. It preserves allocated/deferred/blocked
repair-plan contact rows for review without provider reservations, and
preserves supplied actual-throughput evidence on realized blocked rows without
claiming provider reconciliation.

### `operator_review_package`

With approval, repaired plan-delta, realized-feedback, timeline-protection,
repaired-plan contact-allocation, source contact-allocation, source
contact-suppression, source resource-suppression, and warning rows for
artifact-only operator import/review workflows.

### `cadence_import_manifest`

With review-gated schedule/import adapter rows for repaired plan deltas.

## Source-input reports

These are present when those inputs are present, with refresh provenance,
freshness, contact/resource preservation, and station calendar reports.

- **Source freshness reports** from `candidate_refresh.v1`, preserving stale or
  unknown accepted-state freshness gates in top-level repair review/import
  queues.
- **Mission-state source freshness reports**, preserving stale or unknown
  accepted-state freshness pressure in branch-local refresh derivation.
- **Source candidate-diff reports** from `candidate_refresh.v1`, preserving
  invalidated, semantically changed, and ambiguous candidate rows in top-level
  repair review/import queues.
- **Mission-state source candidate-diff reports**, preserving concrete
  replacement rows as branch-local validated replacement candidates.
- **Source refresh budget reports** from `candidate_refresh.v1`, preserving
  post-filter kept/dropped candidate counts and IDs when refresh cost controls
  were applied before repair, plus top-level `refresh_budget_review` and
  `review_refresh_budget` rows for repair import queues.
- **Mission-state source refresh budget reports**, preserving deterministic
  kept/dropped counts for branch-local relaxed-budget comparisons.
- **Source resource projection reports** over repaired activities and source
  resource summaries, preserving storage/downlink pressure rows in top-level
  repair `resource_projection_review` and `review_resource_projection` queues.
- **Source contact allocation reports** from `candidate_refresh.v1`, preserving
  allocated/deferred/blocked contact rows for repair review without station
  reservations.
- **Source compact contact-allocation summaries** — V2 preserves the separately
  versioned `contact_allocation_summary.v1` at
  `source_contact_allocation_summary`, including exact review rows and
  row-derived allocation, trust, reservation, resource, station, capacity, and
  provenance aggregates. The compact boundary remains review-only and can be
  supplied independently of the full report.
- **Source contact-allocation station-pressure summaries** — V2 preserves the
  exact `contact_allocation_station_pressure_summary.v1` review subset at
  `source_contact_allocation_station_pressure_summary`. Operator review and
  Cadence handoff retain row-derived station, availability, precedence,
  status, direction, and reservation context without reserving provider time,
  mutating schedules, granting operator authority, or performing imports.
- **Source contact-allocation reservation-conflict summaries** — V2 preserves
  `contact_allocation_reservation_conflict_summary.v1` at
  `source_contact_allocation_reservation_conflict_summary`, including the exact
  conflict/review subset and row-derived contact/reservation identity routes by
  match status, reservation status, owner, expiration, direction, and station.
  The adapter creates review evidence only and performs no provider or Cadence
  write.
- **Source contact-allocation capacity-pack summaries** — V2 preserves
  `contact_allocation_capacity_pack_summary.v1` at
  `source_contact_allocation_capacity_pack_summary`, including exact contact
  review rows, reduced-capacity pack groups, capacity fractions,
  selected/deferred identities, required-capacity provenance, and status,
  direction, and station routes. The resulting contact/group adapter rows are
  review-only and cannot mutate provider or Cadence state.
- **Source contact-allocation provider-reservation request summaries** — V2
  preserves `contact_allocation_provider_reservation_request_summary.v1` at
  `source_contact_allocation_provider_reservation_request_summary`, including
  exact request-ready/review-required rows and match-status, ground-station,
  direction, reservation-ID, and contact-ID routing. The handoff creates only
  review actions; it performs no provider reservation or schedule mutation.
- **Source contact filter reports** can preserve reserved-station suppression
  rows with station availability, contention status, reservation ID, owner, and
  reservation status.
- **V3 branch station outage and reservation events** synthesize
  realized-feedback rows for affected downlink, tracking, and health-check
  activities, and the resulting operator-review and Cadence import rows preserve
  station availability, contention status, reservation identity, owner, and
  status.
- **Branch risk indicators and branch-comparison rows** also flatten
  reservation availability, contention, identity, owner, match status,
  station-calendar entry/provider IDs, calendar status, trust-boundary status,
  direction, and ground-station context. This lets reservation-scoped policy
  rules and adapter queues inspect branch authority evidence from
  operator-review and Cadence-import rows, including selected
  strategy-recommendation handoff rows, without reopening the nested filter
  report.

## Preserved executed activities

- Preserved executed activities keep realized execution evidence in their
  per-activity repair metadata when available, including `completed_fraction`
  and actual timing fields for partial executions.
- **Status mapping** — `completed` and `executed` statuses are both treated as
  completed feedback for repair and strategy feedback, while
  `canceled`/`cancelled`/`rejected` realized rows are treated as failed
  terminal feedback that can drive branch refresh demand.
- The same evidence is also present in the source timeline-feedback report and
  downstream review/import rows.
- **Plan deltas** retain `preserved_executed` as the repair action so
  operator-review rows and Cadence import manifests can distinguish
  already-executed preservation from generic preserved timeline items. Import
  manifests use `record_preserved_executed_activity` for that adapter handoff.

## Ambiguous realized feedback

If V2 repair receives multiple realized activity rows with the same planned
activity ID, it preserves the planned activity and emits
`review_realized_feedback` repair metadata instead of choosing one status. The
plan delta carries all normalized `realized_feedback_rows`, a
`realized_feedback_count`, and a `realized_feedback_review` approval requirement
so the ambiguity remains visible to operator-review and Cadence import gates.

## Missed-contact repair

Missed-contact repair uses the same downlink boundary as the communication
reports:

- native `downlink` rows
- `planned_contact` rows whose direction is `downlink`
- provider-shaped prior-plan station/time rows that omit explicit type or
  direction, including nested `station` / `ground_station` identity objects plus
  nested `spacecraft` / `satellite` identity objects

These can move to later downlink contact windows after canonical
downlink/station/time normalization.

- **Out of scope** — command, uplink, and tracking planned contacts remain
  outside that missed-downlink movement path.
- **V3 reuse** — the same normalization feeds V3 branch objective satisfaction
  and no-viable-downlink risk checks, so already-selected provider contacts are
  not treated as missing downlink capacity.
- **Pressure replay** — objective-satisfaction and objective-tradeoff pressure
  replay also accepts station, scenario/spacecraft, and planned downlink-volume
  evidence from nested source-observation/source-activity maps when deriving V3
  collection-latency downlink-gap branches, so provider summaries do not need to
  duplicate those routing fields at the report-row top level. The same nested
  source context is accepted for coverage and target-gap urgent-target replay,
  including target identity, scenario scope, source activity, and inline target
  geometry/priority metadata.
- **Replacement identity** — replacement selection requires stable replacement
  identity: if multiple otherwise eligible replacement candidates share the same
  activity ID, those duplicate-ID candidates are excluded from automatic
  move/replacement selection instead of choosing one by score or sort order.
- **Replacement ranking evidence** — moved downlinks and reassigned observations
  preserve `repair.replacement_ranking` with the selected candidate ID, viable
  unique candidate count, and ordered compact rows. Each row carries semantic
  candidate-diff priority/match, candidate score, churn and move penalties,
  calibrated station-calendar, projected link-capacity, and projected resource
  penalties, the resulting greedy ranking score, rank, and selected flag. The
  metadata copies no full alternative payloads and declares
  `global_optimization: false`.

## Exported JSON Schema

Its exported JSON Schema includes nested repaired-activity, source-candidate,
plan-delta, approval-requirement, score-term, objective-tradeoff, and
link-capacity rows. `plan_delta.v1` is also checked as a standalone fixture for
focused repair-action regressions.

### Plan deltas

- Plan deltas preserve planned and realized activity context plus
  source/replacement timeline IDs, explicit source/replacement
  activity-context maps, and timeline links.
- Approval requirements expose action, reason, requirement type, policy
  classification, and rule-match rows for import/review gates.
- Standalone plan-delta validation now checks nested planned-activity snapshot
  identity/timing and nested realized activity feedback, so malformed stable IDs
  or completion evidence cannot pass by hiding inside the delta handoff.
- **Operator-review rows** lift the same timeline identities so import tooling
  can correlate repaired timeline changes without unpacking nested planned
  activity snapshots. They also flatten source and replacement Cadence import
  status, type, external ID, contract, and presence flags from the preserved
  activity contexts so review queues can distinguish missing import preparation
  from an import-ready replacement.
- Operator-review package scalar totals, typed review counts, and row-derived
  count-map values are executable integers matching the exported JSON Schema
  instead of accepting float-shaped counts.

### `cadence_import_manifest.v1`

- Sourced from the full repair operator-review package, so plan-delta, approval,
  contact-allocation, suppression, timeline-protection, and warning rows become
  deterministic adapter-facing actions and statuses such as `ready_for_import`,
  `review_required_before_import`, and `blocked_missing_cadence_import` without
  writing to Cadence.
- Contact-intent, operational-timeline, and generic operator-review import rows
  derive `has_cadence_import` from explicit source-row import identity when a
  source row does not already provide the presence flag, so adapter queues do
  not see an import ID paired with `has_cadence_import: false`.
- **V1 campaign artifacts** use the same manifest contract for proposed
  contacts, embedded operational-timeline review rows, and station-contention
  resolution recommendations, with contacts ordered by start time and review
  rows preserving source review order.
- **V1 and V2 embedded `operator_review_package.v1` artifacts** also lift
  operational-timeline rows that require operator action before the
  contact-allocation or repair-delta review rows.
- Those operational-timeline review and Cadence-import rows now lift product,
  collection, payload, instrument, spacecraft, product-list, planned/actual
  throughput, estimated/required downlink demand, planned/actual data-volume
  evidence, collection/delivery latency evidence, resource
  source/trust/provenance, blocking dimension, resource margins, battery state,
  availability flags, thermal evidence, lighting/eclipsing evidence, and Cadence
  import provider/adapter/trust provenance to row level along with score terms,
  target priority, and command/contact, observation, and maneuver feedback
  evidence, while still preserving the full source operational timeline row and
  nested activity context.

### Standalone fixtures and Cadence import trust

- **Standalone `planned_activity.v1` and `proposed_contact.v1` fixtures** now
  lint the same direction, source-window, timeline-identity, resource evidence,
  product, latency, throughput context, dependency/exclusivity IDs, and Cadence
  import metadata outside the full campaign artifact while preserving the
  artifact-only no-write boundary.
- **Trust-boundary requirement** — if planned/candidate activity,
  proposed-contact, contact-intent, realized-activity, or nested
  activity-context Cadence import metadata declares a provider, adapter, or
  adapter version, executable validation requires a `trust_boundary` directly or
  in `cadence_import.provenance`.
- **Malformed import metadata** — malformed non-object Cadence import metadata
  in operational timeline, proposed-contact, realized-feedback, and V2
  plan-delta activity-context paths is preserved as invalid import evidence for
  operator review instead of crashing the artifact boundary.
- The planned-activity, candidate-activity, proposed-contact, contact-intent,
  realized-activity, reusable activity-context, and plan-delta nested
  planned-activity JSON Schemas expose the same nested Cadence import adapter
  rule. Generated operator-review package rows and Cadence import manifest rows
  lift the adapter/provider/trust fields so import queues do not need to unpack
  the full activity or contact context.
- **Unsupported statuses** — unsupported upstream `cadence_import_status` values
  are normalized to `cadence_import_status: invalid`, `import_status:
  review_required_before_import`, and `invalid_cadence_import_reason:
  unsupported_cadence_import_status` while preserving the raw provider status on
  `unsupported_cadence_import_status`. Operator-review normalization also clears
  the matching top-level, source, or replacement `*_has_cadence_import` flag so
  invalid statuses cannot be counted as ready handoffs; they are never treated
  as `ready_for_import`.

### Promoted nested activity schemas

- The promoted nested activity schemas also name the dependency/exclusivity,
  timeline-integrity, link profile/quality, pointing/attitude, thermal, resource
  availability, station-calendar reservation/overlap, Cadence-import status,
  source-window status, planned throughput, and realized provider/result fields
  already present in command-window, operational-timeline, operator-review, and
  timeline-feedback fixtures.
- They also name candidate-refresh objective context fields such as
  `observation_objective_ids`, `observation_objective_count`,
  `collection_latency_objective_ids`, and `collection_latency_objective_count`,
  so branch-local objective handoffs do not fall back to opaque
  `additionalProperties`. Regression checks keep those fixture fields covered by
  exported JSON Schema.

### Stable-ID and unit-interval validation

- Executable schema validation also checks stable-ID scalar fields and
  stable-ID arrays inside reusable `activity_context` maps on operational
  timeline, timeline feedback, command-window, plan-delta, approval-requirement,
  operator-review, and Cadence-import rows, including station-calendar
  entry/provider/reservation identity arrays, candidate-refresh objective ID
  arrays, and non-negative station-calendar, timeline-integrity, and objective
  counts.
- Known nested activity-context completion fractions, success factors,
  confidence values, link error/loss rates, cloud/eclipse fractions, and battery
  state-of-charge fields are likewise constrained to the unit interval, as are
  planning-grade fuel, power, storage, and downlink margin fields.

## Row fixture schema-visibility guard

- **Operator-review rows** — checked-in operator-review row fixture fields are
  also covered by the same schema-visibility guard, including timeline
  protection decisions, realized provider handoff fields,
  dependency/exclusivity arrays, queue keys, and resource pressure rollups.
- **Operational-timeline and timeline-feedback rows** now share that guard for
  dependency/exclusivity arrays, integrity status, protection decisions,
  identity-match status, feedback exclusion status, delta-v evidence, and
  realized-provider handoff metadata.
- **Command-window rows** likewise expose dependency/exclusivity arrays,
  activity context, approval requirements, and approval-rule matches through the
  exported row schema instead of relying on `additionalProperties`.
- **Contact-allocation rows** expose station-calendar overlay and reservation
  metadata, selected-contact identity, resource-suppression context, resource
  trust/source fields, and reduced-capacity evidence through the exported row
  schema as well.
- **Link-capacity rows** expose selected utilization, unused capacity-adjusted
  throughput, ignored contact IDs, ambiguous selected contact IDs, and
  duplicate contact IDs plus station-calendar entry, provider, and
  provider-entry ID arrays through the exported row schema, with stable-ID
  validation for those contact and provider-calendar arrays.
- **Timeline-diff, objective-satisfaction, and maneuver-review rows** now expose
  activity/protection context, downlink satisfaction quantities, selected
  identity arrays, and execution-uncertainty status through exported row schemas
  instead of relying on `additionalProperties`.

## Top-level report schemas

- **Link-capacity report** — the top-level link-capacity report schema also
  exposes selected-utilization, downlink-shortfall,
  ignored/unmatched/ambiguous selected contact, duplicate-contact, and
  model-limit summary fields from the checked-in fixture.
- **Source link-capacity report** — V2 preserves CandidateRefresh's upstream
  `link_capacity_report.v1` independently from the repaired-plan report,
  validates it at `source_link_capacity_report`, and routes its existing exact
  review fields into review-gated Cadence import without scoring the evidence a
  second time.
- **Source compact link-capacity summary** — V2 preserves the separately
  versioned `link_capacity_summary.v1` at `source_link_capacity_summary`.
  Existing adapters synthesize one review-gated station row with exact
  selected/actual/required contact identity, throughput, shortfall,
  reservation, station-calendar provider, trust, and provenance evidence; the
  summary does not feed repair scoring or execution.
- **Source relay data-path summary** — V2 preserves
  `relay_data_path_summary.v1` at `source_relay_data_path_summary`. Existing
  adapters retain exact route, source/relay spacecraft, ground contact/station,
  custody, latency, risk, and provenance evidence in review-gated rows without
  scheduling a relay, delivering custody acknowledgement, reserving a provider,
  mutating a schedule, or granting operator authority.
- **Source station-reservation report** — V2 preserves CandidateRefresh's
  upstream `station_reservation_report.v1` independently from the repair-time
  station calendar, validates the nested contract, and routes affected-contact
  and provider-contention rows into review-gated Cadence import without any
  provider reservation write or acceptance.
- **Source station-reservation hold import-readiness summary** — V2 preserves
  `station_reservation_hold_import_readiness_summary.v1` at
  `source_station_reservation_hold_import_readiness_summary`, including exact
  hold/provider/expiration evidence and review actions without accepting,
  renewing, reserving, importing, or writing a hold.
- **Source station-reservation hold summary** — V2 preserves
  `station_reservation_hold_summary.v1` at
  `source_station_reservation_hold_summary`, including aggregate hold counts,
  earliest expiration, provider ownership, and complete review rows without
  creating, accepting, renewing, expiring, or mutating a reservation.
- **Source station-reservation review summary** — V2 preserves
  `station_reservation_review_summary.v1` at
  `source_station_reservation_review_summary`, including row-derived
  reservation counts, expiration routing, provider ownership, and complete
  review rows without creating, accepting, renewing, expiring, or mutating a
  reservation.
- **Source station-calendar precedence summary** — V2 preserves
  `station_calendar_precedence_summary.v1` at
  `source_station_calendar_precedence_summary`, including applied/overlap
  availability, affected contacts, and reserved-under-higher-precedence
  ownership/status routing without provider reservation or schedule mutation.
- **Source station-calendar provider** — when repair receives a declared
  `station_calendar_provider.v1` object directly, V2 preserves it at
  `source_station_calendar_provider`, including entries that affect no repair
  candidate plus top-level provider identity, provenance, and assumptions. The
  raw source remains distinct from the derived station-calendar report and does
  not create review/import rows, provider reservations, or schedule mutations.
- **Source provider-counteroffer review summary** — V2 preserves
  `provider_counteroffer_review_summary.v1` at
  `source_provider_counteroffer_review_summary`, including status,
  negotiation-state, lock-deadline, review-ID, and exact review-row evidence
  without accepting an offer, provider writes, or schedule mutation.
- **Operational-timeline report** exposes status/action/kind count maps,
  dependency and exclusivity issue counts, duplicate timeline-identity counts,
  invalid activity IDs, and model limits, with executable validation that
  cross-checks those summaries against row evidence.
- **Operator-review package** exposes review type, queue, approval,
  required-action, Cadence-import status, and model-limit summaries with the
  same row-derived count validation.
- **Cadence import manifest** exposes import action/status, Cadence-import
  status, source-review type/action/queue, and model-limit summaries with
  row-derived count validation for adapter handoff manifests.
- **Resource-filter report** exposes invalid-candidate, duplicate-suppression,
  resource-source, and trust-boundary summaries; suppressed resource
  quality/trust counts are validated against suppressed candidate rows.
- **Resource-projection report** exposes valid/invalid resource-summary and
  activity counts plus resource quality/trust maps, with row-derived validation
  for projected resource summaries.
- **Source operational import eligibility** — V2 preserves CandidateRefresh's
  `operational_import_eligibility_summary.v1` at
  `source_operational_import_eligibility_summary`, including exact eligibility,
  classification, readiness status, gate counts, source identity, assumptions,
  and no-approval/no-import model limits. The Cadence manifest is an artifact
  handoff only and performs no write.
- **Source operational-readiness gate summary** — V2 preserves the normalized
  `operational_readiness_gate_summary.v1` at
  `source_operational_readiness_gate_summary`, including exact gate rows,
  status/classification routing maps, non-passed gate IDs, source lineage,
  assumptions, and summary-only model limits without changing readiness or
  approving an import.
- **Source operational execution-boundary summary** — V2 preserves the compact
  `operational_execution_boundary_summary.v1` at
  `source_operational_execution_boundary_summary`, including the exact
  handoff-only flag, execution/write/operator-authority denials, classified
  execution boundary, operational-mode gate, assumptions, and artifact-only
  model limits without executing a command or performing an import.
- **Source operational quality-gate summary** — V2 preserves the normalized
  `operational_quality_gate_summary.v1` at
  `source_operational_quality_gate_summary`, including exact gate rows,
  status/classification routing maps, non-passed gate and row IDs, non-passed
  rows, source report identity, assumptions, and model limits without
  recalculating a gate or approving an import.
- **Source unavailable-resource quality-gate summary** — V2 preserves
  `operational_quality_gate_unavailable_resource_summary.v1` at
  `source_operational_quality_gate_unavailable_resource_summary`, including
  resource pressure reasons and blocked contact IDs grouped by dimension,
  spacecraft, and status without changing allocation or reserving a station.
- **Source operator-training quality-gate summary** — V2 preserves
  `operational_quality_gate_operator_training_summary.v1` at
  `source_operational_quality_gate_operator_training_summary`, including typed
  requirement counts and stable role, training, certification, and qualification
  IDs without granting certification, approval, or operator authority.
- **Source schema-validation quality-gate summary** — V2 preserves
  `operational_quality_gate_schema_validation_summary.v1` at
  `source_operational_quality_gate_schema_validation_summary`, including exact
  validation counts and blocked/review row IDs without treating validation
  evidence as approval or performing an import.
- **Source import-readiness quality-gate summary** — V2 preserves
  `operational_quality_gate_import_readiness_summary.v1` at
  `source_operational_quality_gate_import_readiness_summary`, including exact
  freshness, preparation, blocked/missing/invalid-import counts, row IDs, and
  publication lineage without approving or performing an import.
- **Source constraint report** — V2 preserves CandidateRefresh's upstream
  `constraint_report.v1` independently from the recomputed repaired-plan
  report, validates it at `source_constraint_report`, and routes exact non-pass
  rows into review-gated Cadence import without changing feasibility or scores.
- **Source objective-satisfaction report** — V2 preserves CandidateRefresh's
  upstream `objective_satisfaction_report.v1`, validates it at
  `source_objective_satisfaction_report`, and routes exact partial, unmet, and
  no-candidate-window rows into review-gated Cadence import without changing
  objective evaluation, scores, or ranking.
- **Source objective-tradeoff report** — V2 preserves CandidateRefresh's
  upstream `objective_tradeoff_report.v1` independently from the recomputed
  repaired-plan report, validates it at `source_objective_tradeoff_report`, and
  routes exact ranking rows into review-gated Cadence import without changing
  repair scores or ranking.
- **Source score-term report** — V2 preserves CandidateRefresh's upstream
  `score_term_report.v1` independently from the recomputed repaired-plan report,
  validates it at `source_score_term_report`, and routes exact term/value rows
  into review-gated Cadence import without changing repair scores or ranking.
- **Source timeline-diff report** — V2 preserves CandidateRefresh's upstream
  `timeline_diff_report.v1` independently from derived repair deltas, validates
  it at `source_timeline_diff_report`, and routes exact review-required timeline
  rows into review-gated Cadence import without applying source transitions.
- **Source timeline-integrity report** — V2 preserves CandidateRefresh's
  upstream `timeline_integrity_report.v1` independently from repaired timeline
  state, validates it at `source_timeline_integrity_report`, and routes exact
  dependency, exclusivity, invalid-input, and stable timeline identity evidence
  into review-gated Cadence import without mutating the repaired schedule.
- **Source timeline-preservation report** — V2 preserves CandidateRefresh's
  upstream `timeline_preservation_report.v1` independently from derived
  `preserved_activities`, validates it at `source_timeline_preservation_report`,
  and routes exact preserve/review decisions, protection reasons, locks,
  lifecycle status, and invalid-input evidence without mutating the schedule.
- **Source schema-validation report** — V2 preserves CandidateRefresh's upstream
  `schema_validation_report.v1`, validates it at
  `source_schema_validation_report`, and routes exact errors, warnings, and
  remediation into review-gated Cadence import without changing V2 validity or
  import eligibility.
- **Source model-acceptance report** — V2 preserves CandidateRefresh's upstream
  `model_acceptance_report.v1`, validates it at
  `source_model_acceptance_report`, and exposes exact review-required and
  blocked rows for operator review. Model-acceptance review remains excluded
  from Cadence import and does not certify a model or change planning.
- **Source validation safety case** — V2 preserves CandidateRefresh's upstream
  `validation_safety_case_summary.v1`, validates it at
  `source_validation_safety_case_summary`, and exposes exact review-required
  and blocked evidence for operator review. Safety-case review remains excluded
  from Cadence import and does not grant certification or execution authority.
- **Source provider-counteroffer report** — V2 preserves CandidateRefresh's
  upstream `provider_counteroffer_report.v1`, validates it at
  `source_provider_counteroffer_report`, and routes exact reviewable offers into
  review-gated Cadence import without requesting, accepting, reserving, or
  executing a provider offer.
- **Source provider-counteroffer plan impact** — V2 also preserves the upstream
  `provider_counteroffer_plan_impact_summary.v1` at
  `source_provider_counteroffer_plan_impact_summary`, including exact proposed
  timing/cost deltas, lock-deadline status, affected calendar identity, and
  source lineage. Reviewable impact rows remain review-gated and do not alter
  the repaired schedule or provider state.
- **Source provider-counteroffer import readiness** — V2 preserves the upstream
  `provider_counteroffer_import_readiness_summary.v1` at
  `source_provider_counteroffer_import_readiness_summary`, including exact
  import classification/status, required action, lock-deadline evidence, and
  source lineage. A review-required row remains an instruction for review, not
  an import, provider write, offer acceptance, reservation, or execution.
- **Timeline-diff report** also exposes status/action/changed-field count maps,
  duplicate timeline-identity counts, and model limits from the checked-in
  fixture.

## Additional standalone schema surfaces

- **Standalone contact-intent JSON Schema** exports also type station
  availability and schedule-conflict status as strings so adapter-facing contact
  handoffs match the same executable validation surface used in nested refresh
  and campaign artifacts.
- **Planned command activities** also expose optional command-success feedback
  factors so standalone command rows retain the same confidence evidence used by
  operational timeline and command-window handoffs.
- **Standalone `approval_requirement.v1` fixtures** also lint activity-context,
  policy-classification, and rule-match evidence outside a full repair or policy
  decision artifact.
- **Standalone `contact_contention_report.v1` and
  `contact_contention_resolution_report.v1` artifacts** can be normalized into
  the same manifest contract for review-only station-conflict handoff. Prior
  `contact_contention_resolution_report.v1` recommendations embedded in
  `source_result_artifact` / `result_artifact` wrappers can also replay as
  branch-local downlink-completion pressure with wrapper trust provenance.
- **Contentious provider-shaped contacts** now preserve station-calendar
  provider IDs, provider entry IDs, overlap/reservation IDs, reservation
  owner/status lists, and trust-boundary status lists through contention groups,
  deterministic resolution recommendations, operator-review rows, and Cadence
  import rows.

## Command-window and station-calendar overlays

- **Command-window reports** can consume declared station-calendar overlays
  directly, embed the nested `station_calendar_report.v1`, and promote
  otherwise monitor-only command, tracking, uplink, or health-check windows to
  `review_command_window_station_calendar` when unavailable, maintenance,
  reserved, or reduced-capacity station time affects the window.
- Command-window and station-calendar reports can also be normalized into
  review-gated manifest rows so command/contact boundaries and provider calendar
  conflicts carry adapter-facing status counts without granting execution
  authority.

## Contact allocation and contention

- **Contact-allocation reports** normalize through `contact_allocation_review`
  rows and `review_contact_allocation` manifest actions so ground-network
  allocation decisions stay review-gated before any adapter write. Branch-local
  contact-allocation pressure also normalizes allocation, review/approval, and
  policy-classification status case/whitespace/hyphen variants before deriving
  deferred, blocked, or policy-blocked downlink pressure.
- **V2 source contention reports** preserve the exact conflict groups and
  invalid contact inputs alongside the paired resolution recommendations,
  validate both source artifacts at their V2 paths, and route their existing
  review rows into review-gated Cadence import without applying group evidence
  to candidate eligibility or schedules.
- **V2 compact contention-resolution summaries** preserve the separately
  versioned `contact_contention_resolution_summary.v1` at
  `source_contact_contention_resolution_summary`. Existing adapters synthesize
  one review-gated recommendation per group with exact selected, deferred, and
  review contact identity, resource scope, selection reason, action, and
  capacity provenance; the summary never feeds repair scoring or execution.
- **Standalone contention-resolution recommendations** can also feed
  branch-local refresh by converting deferred downlink recommendations into
  `downlink_completion_gap` events with selected contact, priority source,
  priority-override metadata, source-window lineage, required downlink demand,
  and trust-boundary evidence preserved.
- **Replay sources** — the same recommendation payload can be replayed from
  `operator_review_package.v1` `source_recommendation` rows, flattened
  operator-review recommendation rows, or top-level
  `cadence_import_manifest.v1` `source_recommendation` / flattened
  recommendation rows, so review/import queues remain artifact-only but still
  provide branch-local refresh pressure without reopening the original
  contention-resolution artifact.
- **Reduced-capacity station overlays** can block contacts whose declared
  `required_capacity_fraction` exceeds available station capacity, with the
  required and available fractions promoted through allocation, operator-review,
  Cadence import, and JSON Schema validation. Allocation can also promote
  additional deferred same-station contacts when explicit per-contact capacity
  requirements fit within declared reduced station capacity, while still
  avoiding provider reservation or link-budget claims.
- **`default_required_capacity_fraction`** — when callers declare a
  planning-grade `default_required_capacity_fraction`, that default participates
  in the same pack ledger before any row is returned as allocated, so selected
  contacts that cannot fit reduced capacity are deferred rather than
  over-allocating the station.
- **Approval policy** — when an approval policy is supplied, the embedded
  contact-contention group and deterministic recommendation reports inside the
  allocation artifact also retain policy-decision, approval-requirement, and
  rule-match evidence instead of leaving conflict evidence policy-blind.

## Review-row normalization

- **Timeline-diff reviews** normalize into typed `review_timeline_diff` manifest
  rows that preserve source/replacement timeline identities, source activity
  context, transition fields, changed fields, and the source diff row for
  adapter handoff, including station-calendar trust/source evidence when it
  changed between source and replacement activity context. Those transition
  fields preserve the same operator-review recommendation metadata emitted by
  `timeline_diff_report.v1`; source and replacement protection decisions
  preserve the same typed nested activity/timeline ID, lock/approval,
  timeline-identity, decision, category, and reason fields.
- **Timeline-protection rows** normalize into typed `review_timeline_protection`
  manifest rows with protection category, decision, and source protection
  summary so repair preservation decisions remain visible to adapter queues.
- **Remaining generic `operator_review_package.v1` row families** preserve the
  source review row under `source_review_row` while keeping the adapter handoff
  separate from operator approval and Cadence writes.
- **Package-level provenance** — the package-level provenance object also has a
  machine-readable schema for source plan, repair, strategy, source provenance,
  and nested candidate-source fields, with stable-ID validation for those
  handoff identifiers.

## Row-ID integrity and source-review alignment

- **Duplicate row IDs** — executable validation also rejects duplicate
  operator-review row IDs, Cadence import manifest row IDs, and standalone
  report row IDs for branch-comparison, contact-allocation, maneuver-review,
  objective-satisfaction, Pareto-frontier, score-term, operational-timeline,
  timeline-diff, and command-window reports, so downstream review/import queues
  can treat row IDs as stable unique handles rather than shape-only strings.
- **Embedded `source_review_row`** — Cadence import rows that embed a
  `source_review_row` must include its `id`, `review_type`, and `action`, and
  the exported JSON Schema declares those fields plus dependent
  `source_review_type` and `source_review_action` adapter fields.
- Executable validation also keeps `source_review_row_id`, `source_review_type`,
  and `source_review_action` aligned with that embedded row, and import-manifest
  generators populate `source_review_action` from the embedded review row's
  `action` before falling back to any generic `required_operator_action`.
- They also preserve `source_review_queue` and `source_review_queue_key` from
  operator-review rows and expose row-derived source queue counts, preventing
  adapter queues from silently drifting away from the operator-review row they
  reference.
- **Policy bundles** can match those deterministic queue coordinates with
  `review_queue` / `review_queues` and `review_queue_key` / `review_queue_keys`
  action-rule selectors, and matching policy-decision rows carry the resolved
  queue context for adapter handoff.

## Trust-boundary requirements on handoff rows

- **Cadence provider/adapter metadata** — manifest rows, operator-review rows,
  and operational timeline rows that declare Cadence provider, adapter, or
  adapter-version metadata must also declare `cadence_import_trust_boundary`
  directly or through `cadence_import_provenance.trust_boundary`, matching the
  trust-boundary rule on nested proposed-contact and contact-intent import
  metadata.
- **Realized provider/adapter metadata** — timeline-feedback, operator-review,
  and import rows that declare realized provider, adapter, or adapter-version
  metadata likewise require `realized_trust_boundary` or
  `realized_provenance.trust_boundary`.
