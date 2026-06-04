# Mission-State Fallbacks and Feedback Overlays

## Mission-state fallback inputs for refresh requests

- V2 repair can run a repair-level `candidate_refresh_request` when a prebuilt
  refresh artifact is not supplied. It inherits the normalized repair mission
  state into the executable refresh request when the request omits its own
  mission-state fallback inputs.
- Study-manifest candidate-refresh metadata preserves the optional
  `mission_state` object, so file-backed and repair/strategy-generated
  refreshes keep mission-state objective and feedback fallback context through
  execution.
- Standalone candidate-refresh manifests can also use mission-state spacecraft
  states, target catalogs, and ground-station definitions as executable
  run-input fallbacks. This includes nested objective target selectors and
  provider-shaped ground-network station geometry — even when the corresponding
  mission-state catalogs or manifest-level refresh run-input lists are present
  but empty.

## Run-input provenance and source maps

- Manifest metadata and emitted `candidate_refresh.v1` provenance now record
  `run_input_sources` for accepted planning state, target geometry, and
  ground-station geometry. This lets Cadence-facing review/import tooling
  distinguish explicit refresh inputs from orbit-data adapters and
  mission-state fallback catalogs before acting on refreshed windows.
- Operator-review rows and Cadence-import rows now preserve the same source
  map, and Cadence import manifests lift it into provenance for queue-level
  routing.

## Objective normalization and branch derivation

- Mission-state objective rows canonicalize `type`, `objective_type`, or
  `objective` tokens for case, whitespace, hyphen, and atom variants before V3
  branch derivation. As a result:
  - Provider-style `target revisit` evidence becomes an executable
    `target_revisit` candidate-refresh branch.
  - Delivery-latency objective aliases become executable collection-latency
    refresh branches.
- **Collection/downlink data selectors** accept nested `collection`,
  `product`, `data_product`, `products`, `payload`, and `instrument` objects
  before branch-local refresh. Generated downlink additions promote those
  provider identities to canonical `collection_id` / `product_id` /
  `product_ids` / `payload_id` / `instrument_id` fields.
- **Downlink-completion objectives** also accept provider contact-count aliases
  plus required contact ID lists, so generated additions satisfy the declared
  contact demand instead of defaulting to one contact.

### Singular vs. plural data identities

- When a broad objective lists multiple data products, collection-latency
  branch events preserve the intersecting source-observation product as
  `product_id` while keeping the full selector set in `product_ids`.
- Objective-only downlink-completion events omit singular data-identity fields
  until a selector is truly singular, while retaining full normalized plural
  sets such as `collection_ids`, `product_ids`, `payload_ids`, and
  `instrument_ids`.
- `strategy_branch.v1` / nested `campaign_strategy.v3` event validation and
  exported JSON Schema provide coverage for those plural stable-ID arrays.

### Window cardinality evidence

- Standalone `refreshed_window.v1` exports and validates `sample_count` as a
  non-negative integer, so window cardinality evidence cannot cross the
  refresh/review boundary as a negative or float-shaped count.

## V3 branch refresh overrides

- V3 branches can override the shared refresh input with schema-valid
  branch-specific `candidate_refresh.v1` artifacts, or run branch-local
  `candidate_refresh_request` manifests.
- The checked-in V3 strategy request is regression-tested as JSON input, so
  embedded branch refresh windows cannot drift behind the current
  candidate-refresh contract.

## Branch-local refresh derivation from mission state

When mission state carries accepted planning-state data plus station/target
catalogs, V3 can:

- Derive a branch-local refresh request from branch events.
- Overlay ground-station outage, reserved-station, and reduced capacity events
  into `ground_network`.
- Synthesize planning-grade resource summaries from global or per-spacecraft
  mission-state resource maps when explicit summaries are absent, normalizing
  clean numeric-string margins and capacity-derived storage/downlink inputs
  before low-resource branch derivation.
- Overlay degraded-spacecraft plus low-fuel, low-power, low-storage,
  low-downlink, and low-thermal resource-pressure, payload-unavailable, and
  antenna-unavailable events into resource summaries.
- Derive low-resource branches and branch-comparison risks from explicit
  `mission_state.resource_summaries` when those summaries are the stronger
  planning-grade source, including degraded-state branches plus payload and
  antenna availability risk columns in branch-comparison rows.

### Maneuver execution deltas

- Encode missed/delayed maneuver branch events and realized
  missed/failed/delayed maneuver telemetry as `maneuver_execution_delta` rows
  on the generated accepted planning state.
- Resolve sparse realized maneuver rows through a unique prior-plan activity ID.
- Preserve repeated realized source activity evidence as stable
  `source_activity_ids` arrays on derived branch events while keeping
  `source_activity_id` as a stable primary ID.
- Standalone `maneuver_execution_delta.v1` rows can flow directly through
  `OrbitalDynamics.operator_review_package/1` and
  `OrbitalDynamics.cadence_import_manifest/2` as `realized_only` maneuver
  feedback until planned maneuver context is supplied.

## Operational feedback overlays

- Apply station-throughput, contact-success, observation-success,
  target-priority, and downlink-demand operational feedback to generated
  contact and observation candidates, while preserving command-success and
  maneuver-success feedback in candidate-refresh provenance for
  branch-generated refresh artifacts.

### Timeline feedback report ingress

- Standalone and branch-generated refresh requests can consume ready
  `source_timeline_feedback_report` or `timeline_feedback_report` artifacts
  directly from top-level, mission-state, or accepted-planning-state inputs,
  and can unwrap those reports from `source_result_artifact` / `result_artifact`
  wrappers at the same levels. The same operational-feedback maps are derived
  from report rows before explicit `operational_feedback` overrides are applied.
- Standalone refresh also accepts wrapper-level `operational_feedback` maps as
  the same lower-priority replay source, preserving source paths, input keys,
  and wrapper trust-boundary summaries plus per-field/key trust-boundary
  routing.

### Operational timeline report ingress

- Refresh now consumes `source_operational_timeline_report` /
  `operational_timeline_report` rows from top-level, mission-state,
  accepted-planning-state, result-artifact, operator-review, and Cadence-import
  handoffs. These act as lower-priority contact, station-throughput,
  observation, command, and maneuver success feedback before explicit request
  feedback takes final precedence.
- **Timeline-feedback provenance** preserves report paths, row counts, input
  keys, status/count maps, row-derived station-reservation evidence and
  expiration evidence counts, and report or wrapper provenance/metadata
  trust-boundary summaries.
- The public source-report summary facade exposes total and by-family
  reservation-evidence counts for audit-only inspection.

### V3 branch-generated refresh carry-through

- V3 branch-generated refreshes now carry mission-state
  `source_timeline_feedback_report` / `timeline_feedback_report` and
  `source_operational_timeline_report` / `operational_timeline_report` payloads
  into generated `candidate_refresh.v1` requests as typed top-level source
  reports. Refresh provenance therefore records report paths, row counts, and
  trust evidence instead of only flattened `operational_feedback`.
- Low branch-local feedback events for station throughput, contact success,
  observation success, target priority, command success, and downlink demand
  are folded into the branch-generated refresh request even when they were
  supplied as explicit branch events instead of top-level
  `operational_feedback`. This lets hand-authored what-if branches regenerate
  candidates without prebuilt refresh artifacts.

## Provider alias canonicalization

### Resource and availability aliases

- Branch-authored resource events now canonicalize provider-style
  `storage_capacity_margin`, `downlink_capacity_margin`, `battery_soc`,
  `battery_state_of_charge`, `payload_available?`, `antenna_available?`, and
  `spacecraft_available?` aliases before branch-local candidate refresh,
  resource filtering, resource scoring, and risk generation.
- This includes provider-style unavailable status words such as `down`,
  `outage`, and `maintenance` on branch or operational availability feedback.

### `CandidateRefresh.capabilities/0`

`CandidateRefresh.capabilities/0` advertises:

- The resource margin aliases, battery-to-power source aliases, resource
  availability aliases, status aliases, and accepted status tokens used for
  those feedback overlays.
- Station unavailable aliases/tokens used by station-calendar refresh ingress,
  and the station-availability precedence used when unavailable, reserved, and
  reduced-capacity station evidence overlap.
- The station capacity fraction and capacity-percent paths, plus typed capacity
  `unit` / `path` metadata used to derive reduced-capacity contacts.
- Provider direction aliases such as `sband_command`, `s_band_command`,
  `downlinking`, `dl`, and `tracking_pass` used when normalizing prior
  candidate contact rows and station-calendar direction scopes.
- Event-timing metadata keys, prior-candidate optional stable-identity fields,
  station-calendar ID-list fields, and operational-timeline integrity issue
  field families used by refresh provenance and review routing.
- `thermal_margin_c` as an operational-feedback resource-margin input rather
  than only as a direct resource-summary overlay.

### Downlink-demand branch

- Downlink-demand feedback can derive its own generated refresh branch with
  required-demand scoring evidence before candidate-budget selection.
- Branch-level feedback score/risk fields use that same branch-local merge, so
  comparison rows explain the confidence factors and demand evidence applied to
  the branch.

## Bounds and schema enforcement

- Top-level and mission-state success feedback require clean `[0, 1]`
  candidate-refresh factors.
- Branch-authored unit-interval event factors are preserved as invalid
  branch-event evidence and warnings instead of being clamped into refreshed
  candidates.
- Branch-local target-priority and required-downlink demand inputs remain
  bounded to non-negative planning values before refresh.
- Exported branch event schemas enforce those same bounds, branch-authored
  feedback confidence/sample weight fields, and downlink-demand and
  downlink-completion source lineage list shapes.
- Comparison row schemas enforce the applied confidence boundary for contact,
  command, observation, and maneuver success evidence.

## Feedback-driven branch generation

When branch derivation is enabled:

- **Station throughput** — low station-throughput feedback can derive its own
  branch-generated refresh.
- **Contact success** — low contact-success feedback can do the same for
  generated contact-confidence review.
- **Observation success / target priority** — low observation-success feedback
  and high target-priority feedback can each derive target-specific
  branch-generated refreshes and stage validated observation candidates for
  operator review.

### Target-coverage objectives

Target-coverage objectives can now derive one branch-local refresh per
uncovered requested target. These:

- Preserve objective time-window bounds.
- Honor explicit `target_id`, `target_ids`, and `required_target_ids`
  selectors without expanding them to the full target catalog.
- Carry inline target latitude/longitude specs when no separate target catalog
  row exists.
- Normalize per-target branch events without dropping coverage-objective IDs,
  candidate windows, scenario scopes, or spacecraft constraints.
- Count only scoped matching planned observations.
- Consume refreshed observation candidates inside those bounds through the same
  review-gated strategic-addition path.

### Maneuver-success feedback

- Maneuver-success feedback now applies to maneuver/impulsive-burn activities
  and missed/delayed maneuver events during branch scoring.
- Low explicit or realized maneuver-success feedback can derive
  maneuver-confidence review branches when branch derivation is enabled,
  including explicit feedback keyed by timeline identity and branch-authored
  provider feedback keys aliased back to the planned maneuver activity.

### Command-success feedback

- Command-success feedback now applies to command and health-check activities,
  including provider-shaped `planned_contact` / `contact` rows with
  `direction: health_check` or provider hyphen/whitespace variants, during
  branch scoring.
- Realized command/health-check telemetry can derive
  `operational_feedback.command_success_rate` from sparse rows when a unique
  prior-plan activity identity supplies the activity type. This includes:
  - Provider rows that carry their own external ID plus `planned_activity_id`
    or an explicit `timeline_id` match that is keyed back to the selected
    planned activity.
  - Explicit feedback maps keyed by timeline identity.
  - Provider `command_result` aliases such as rejected, failed, timeout,
    accepted, acknowledged, and succeeded — including list-valued, map-valued,
    or comma-delimited mixed provider outcomes that are normalized to
    schema-safe result strings in branch-local review events.
- Timeline-feedback and V3 maneuver-success feedback accept the same
  provider-result alias grammar through `maneuver_result`, with failure aliases
  winning over success aliases when mixed and realized maneuver outcomes taking
  precedence over planned maneuver-confidence factors, while list- and
  map-valued provider results are flattened at the artifact boundary.
- Branch-authored provider feedback keys are also aliased back to the planned
  command activity.
- Low command-success feedback can derive command/health-check confidence
  review branches when branch derivation is enabled, scoped only to selected
  command or health-check activities.

### Priority-commitment objectives

- Unscheduled priority-commitment objectives can derive branch-local refreshes
  even when they are not marked urgent.
- Priority commitments now honor explicit `target_id`, `target_ids`, and
  `required_target_ids` selectors without treating the objective ID as a
  target, including inline target specs when no separate target catalog row
  exists.
- Priority-commitment branch scoring now counts required, planned, and missing
  observations rather than only target presence, with the resulting ratio
  flattened through branch-comparison, operator-review, and Cadence-import rows.

### Target-revisit and target-observation objectives

- Target-revisit and target-observation objectives use the same explicit target
  selector and inline target-spec handling when planned observations are below
  the required count.
- Multiple scoped target objectives for the same target now keep distinct
  branch IDs with base-branch lineage instead of collapsing into one refresh,
  with that lineage flattened through branch-comparison, operator-review, and
  Cadence-import rows for adapter routing.
- Target-revisit staging can consume multiple non-overlapping validated
  observation candidates before using an approval-required placeholder for any
  unmet observation count.

## Staging, review reasons, and realized telemetry

- Validated additions carry objective-specific repair reasons for priority
  commitments, target coverage, target revisit, feedback, and urgent-target
  sources, so operator-review rows can explain why an observation was staged.
- Urgent-target staging can consume validated observation candidates from the
  branch-generated refresh instead of falling back to placeholders when a
  non-overlapping candidate window exists.
- Realized missed/failed observation feedback in mission state now reduces
  effective planned target coverage, derives target-revisit refresh branches,
  and carries source activity/status context into the staged urgent-target
  event. However, sparse realized rows only infer observation target context
  from the prior plan when the planned activity ID resolves to one unique
  planned row.

## Realized telemetry to feedback factors

- Realized contact telemetry in mission state can derive station-throughput and
  contact-success feedback factors for branch-local candidate refresh.
- Realized observation telemetry can derive target-level observation-success
  factors, and realized maneuver telemetry can derive maneuver-success factors.
- Branch feedback scoring and risks apply those contact-success and
  station-throughput factors to native downlinks and direction-`downlink`
  `planned_contact` rows selected in the branch repair result. They fall back
  to branch-generated source candidates for refresh-only feedback branches
  before a candidate is selected into the repaired activity list, and surface
  that activity-source distinction through branch-comparison, review, and
  Cadence-import rows.
