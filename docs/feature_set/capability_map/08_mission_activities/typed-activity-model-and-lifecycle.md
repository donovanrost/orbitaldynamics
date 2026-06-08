# Typed Activity Model and Lifecycle

Status: **implemented**.

## Activity types

`MissionPlan.Activity` supports `coast`, `impulsive_burn`, `observe`,
`downlink`, `slew`, `command`, `tracking`, `health_check`, and
`planned_contact`. `MissionPlan` validates bounds and overlap. Non-dynamics
activities survive as metadata.

## Capability catalog

- `MissionPlan.Activity.capabilities/0` publishes the supported
  activity/status/approval/direction values and boundary limits through the
  top-level capability catalog. This includes first-class attitude activities
  for declared pointing/hold operations.
- The `study_manifest.v1` activity schema derives its type, direction, status,
  and approval-status enums from that same capability surface.
- `Timeline.capabilities/0` publishes the provider status and approval alias
  maps as row semantics, plus candidate-rejection station-capacity fraction
  paths for raw timeline-map adapters.

## Artifact ingress and egress

Typed activities have atom-keyed and JSON/string-keyed `from_map!/1` ingress
and string-keyed `to_artifact_map/1` egress. Both are exposed through
top-level `OrbitalDynamics` facades for Cadence-facing adapter boundaries.

Ingress normalization:

- Accepts top-level `activity_type` as an input alias for canonical `type`.
  Manifest-backed mission-plan activity rows accept the same alias before typed
  activity construction.
- Normalizes clean boolean strings for `locked` and `allow_overlap?`.
- Normalizes provider-style contact direction strings for case, whitespace, and
  hyphen variants, plus command/downlink/tracking/health-check aliases —
  including provider-shaped `s-band command`, `dl`, `downlinking`, and
  `tracking-pass`. Operational timeline reports apply the same direction alias
  normalization before contact/command classification and review routing.
- Normalizes provider-shaped `planned_contact` rows with
  `direction: health_check` into typed `health_check` station activities.
- Accepts provider-shaped singular `target`, `station`, `ground_station`,
  `spacecraft`, and `satellite` objects as identity evidence before emitting
  canonical `target_id`, `ground_station_id`, and `spacecraft_id` artifact
  fields.

Overlap policy is exposed as canonical `allow_overlap` booleans on timeline
rows and activity context, and overlap-policy changes are flagged as reviewable
timeline diffs.

## Identity, scope, and provenance fields

Preserved across string-keyed artifact ingress and egress:

- **Dependencies / exclusivity** — stable-ID arrays
  `dependency_activity_ids`, `dependency_timeline_ids`,
  `exclusive_with_activity_ids`, and `exclusive_with_timeline_ids`. Scalar or
  comma-delimited provider ID strings are accepted at typed-activity and raw
  timeline-map ingress before canonical arrays are emitted.
- **Timeline identity** — explicit `timeline_id`, with `persistent_id`
  accepted as an artifact-ingress alias.
- **Source-window provenance** — explicit `source_window_type` and nested
  `source_window` next to `source_window_id`. Canonical source-window ID/type
  are derived from nested provider windows, and `metadata.source_window` is
  lifted through operational timeline row/activity context, so
  provider/candidate-window evidence survives the typed-activity boundary.
- **Command-window provenance** — explicit `command_window_id`,
  `command_window_type`, and nested `command_window`, so command-window review
  handoffs do not depend on metadata-only context.
- **Resource/product identity** — canonical `resource_id`, `collection_id`,
  `product_id`, `product_ids`, `payload_id`, and `instrument_id`, using the same
  common JSON aliases as operational timeline normalization.
- **Scope** — explicit `scenario_id` and `spacecraft_id`, used by timeline
  identity, policy, review, and branch artifacts.
- **Collection latency objectives** — explicit
  `collection_latency_objective_count`, `collection_latency_objective_ids`,
  `collection_latency_objective_source`, and
  `collection_latency_objective_types` survive typed activity ingress/egress
  and operational timeline context handoff.
- **Station capacity evidence** — explicit `capacity_fraction`,
  `station_capacity_fraction`, and `capacity_pack_capacity_fraction` survive
  typed activity ingress/egress and operational timeline context handoff as
  bounded review/allocation evidence, without reserving station capacity.
- **Station-calendar identity/status evidence** — explicit
  `station_calendar_entry_id`, `station_calendar_provider_id`,
  `station_calendar_provider_entry_id`, `station_availability`,
  `station_calendar_status`, and `station_calendar_trust_boundary_status`
  survive typed activity ingress/egress and operational timeline context
  handoff as provider-calendar review evidence, without creating station
  reservations.
- **Station-calendar direction/source evidence** — explicit
  `station_calendar_directions` and nested `source_station_calendar_entry`
  survive typed activity ingress/egress and operational timeline context
  handoff, so direction-scoped provider-calendar provenance remains available
  for review/import routing without mutating station calendars.
- **Station reservation evidence** — explicit `station_reservation_id`,
  `station_reservation_expires_at_s`, `station_reserved_by`,
  `station_reservation_status`, and `station_reservation_match_status` survive
  typed activity ingress/egress and operational timeline context handoff as
  provider reservation evidence, without creating or extending reservations.

## Evidence and telemetry fields

- Target-priority evidence with source/objective context.
- Observation-objective context with explicit objective count, IDs, source, and
  type labels.
- Contact/command/observation/maneuver feedback success factors and source
  labels.
- Candidate-refresh maneuver-review replay preserves required-operator-action
  counts alongside maneuver success and execution-uncertainty feedback, so
  review queues can route maneuver action pressure without reopening source
  maneuver rows.
- Fixed-rate Mbps and MB/s link aliases.
- Realized actual-rate and contact-duration telemetry.

## Cadence import metadata

Cadence import metadata canonicalizes provider aliases such as `id`,
`import_type`, and `contract` into `external_id`, `activity_type`, and
`schema_contract` before review/import handoff, while preserving the
artifact-only no-schedule-mutation boundary. Artifact-only `cadence_import`
metadata is also carried for downstream adapter preflight.

## Manifest-backed activities (`study_manifest.v1`)

- The `study_manifest.v1` mission-plan activity schema/ingress accepts the same
  explicit scope, durable timeline identity, resource/product identity,
  target-priority evidence, observation-objective context,
  collection-latency objective context, feedback success evidence,
  station-calendar identity/status evidence, station-calendar
  direction/source-entry evidence, station reservation evidence,
  station-capacity fraction evidence, observation-quality evidence, fixed-rate
  and realized link-rate/duration telemetry, source-window and command-window
  context, Cadence import metadata, and dependency/exclusivity arrays.
- Manifest-backed activities inherit the parent mission-plan ID and spacecraft
  ID when omitted, and reject conflicting child scope.
- Each manifest-backed activity carries status, approval status, lock state,
  dependencies, exclusivity group, source-window ID, provenance, direction,
  ground-station fields, station-reservation expiration seconds (from direct and
  source station-calendar evidence), and optional `execution_uncertainty` maps.

## Validation and integrity

- Programmatic `MissionPlan` compilation applies the same inherited scope to
  scenario metadata while rejecting child activity scope that conflicts with the
  parent plan.
- Programmatic `MissionPlan` validation reuses the operational timeline
  dependency/exclusivity integrity checks — missing activity and timeline
  dependencies, dependency order violations, dependency cycles, and explicit
  exclusivity overlaps — before scenario compilation. Manifest-backed and
  API-created typed-activity payloads therefore align with operational timeline
  integrity checks.

## Lifecycle vocabulary and helpers

Typed and manifest-backed activities accept the operational timeline lifecycle
vocabulary: completed/partial execution, missed/failed/cancelled exceptions, and
approval-gated review states such as operator review, not evaluated, and blocked
by policy.

Helpers (all without schedule mutation or command execution):

- Pure lifecycle helpers for validated status updates, approval/rejection,
  locking, execution recording, and cancellation.
- The generic lifecycle-event helper accepts common provider lifecycle tokens —
  `completed`, `executed`, `partially executed`, `in progress`, `succeeded`,
  `failed`, `aborted`, `timed out`, `skipped`, `missed`, and `cancelled` — as
  aliases for the same validated artifact-state transitions.
- `put_status!` accepts the same provider lifecycle status aliases.
- `status_transition/2` and `transition_status!/2` (plus matching top-level
  facades) provide opt-in validation that prevents automatic terminal/executed,
  invalid, or policy-blocked status regressions, without schedule mutation or
  operator authority.
- `Timeline.lifecycle_state_summary/3` and
  `OrbitalDynamics.timeline_lifecycle_state_summary/3` aggregate planned versus
  realized activity sets by timeline identity, deriving record/review/preserve
  counts, required-action maps, import-action maps, review ID sets, and
  duplicate/invalid-input review rows without schedule mutation, Cadence import,
  operator authority, or command execution. They publish the validated
  `timeline_lifecycle_state_summary.v1` contract so counts, review rows, review
  IDs, action/category maps, and Timeline `model_limits` remain row-derived and
  schema-pinned.
- Operator-review packages and Cadence-import manifests accept lifecycle-state
  summaries as artifact-only handoff inputs, carrying lifecycle review rows,
  status/approval transition evidence, protection context, and source rows
  without approving, importing, mutating schedules, or executing commands.

Provider alias normalization:

- Typed activity artifact ingress accepts common provider status aliases such as
  `In Progress`, `succeeded`, `partially executed`, and `timed-out` before
  emitting canonical lifecycle statuses. Operational timeline reports reuse those
  aliases for raw activity-map inputs.
- Provider approval labels such as `Review Required`, `under review`,
  `No Review Required`, and `policy blocked` normalize to canonical approval
  states before timeline review/import routing, with matching canonical values
  preserved in `activity_context`.

## Preconditions

- `precondition_summary/1` (plus its top-level facade) summarizes explicit
  availability, degraded, resource-blocking, depleted-margin, and
  suppression/incompatibility preconditions, without reserving resources or
  changing schedules.
- `Timeline.activity_precondition_summary/1` and
  `OrbitalDynamics.timeline_activity_precondition_summary/1` emit the validated
  `timeline_activity_precondition_summary.v1` contract for timeline-map
  preflights, including no-authority assumptions, Timeline `model_limits`, and
  review-required invalid input evidence.
- V1 `campaign_plan.v1` artifacts attach selected-activity
  `timeline_activity_precondition_summary.v1` rows beside the operational
  timeline report, so campaign-level review/import queues can route clear,
  blocked, or review-required activity preconditions without reopening the full
  timeline rows or granting execution authority.
- `MissionPlan.Activity.capabilities/0` publishes the precondition status
  vocabulary, row semantics, and emitted precondition types, so adapters do not
  infer them from helper output.
- Operational timeline rows derive the same schema-visible precondition status,
  counts, types, and row evidence from their typed-activity context.

## Approval/lock evidence preservation

Typed approval and lock helpers preserve terminal or executed lifecycle statuses
(completed, partial, executed, missed, failed, canceled/cancelled, and rejected)
while updating approval/lock state. An operator approval or lock action
therefore cannot erase execution evidence before timeline reports, repair
protection, or Cadence review/import handoff.

## Planner emission (V1/V2/V3)

- V1/V2/V3 emit selected activities and approval requirements.
- V2 repair deltas, replacement repair metadata, and approval requirements
  preserve operational activity context for status, approval, locks,
  dependencies, exclusivity, provenance, and source-window lineage, plus durable
  `timeline_identity` metadata for repaired source/replacement activities.

## Operational timeline reports

Operational timeline reports separate completed/partial/executed rows from
missed/failed/canceled/cancelled/rejected terminal exceptions, so exceptions
count toward review/import instead of `executed_count`. They keep rejected
approval states and status- or approval-level policy blocks routed to resolve
actions even when the activity is otherwise completed, partial, or executed.
They also expose a schema-visible `operational_kind` classifier — shared with
`Timeline.capabilities/0` — so command/contact/observation/maneuver routing
cannot drift into arbitrary persisted values.
