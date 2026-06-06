# Overview, Contact Filter, and Contact Contention

Status: **implemented**.

## Ground-station model and contact data

- `GroundStation` definitions.
- Access windows.
- V1 proposed downlink contacts with explicit `downlink` direction.
- Fixed-rate throughput estimates.
- Station availability markers.
- Cadence import IDs.
- V2 contact repair.
- V3 ground-station outage, reserved-station, and reduced-capacity branch events.

## `contact_intent.v1` rows

`contact_intent.v1` rows cover:

- V1 campaign proposed contacts.
- Refreshed downlink/contact candidates.
- Typed command/tracking activities that carry ground-station timing and station capacity context.

### `ContactIntent.capabilities/0`

`ContactIntent.capabilities/0` advertises:

- Accepted direct and source station-calendar capacity fraction/percent paths.
- Typed fraction/percent capacity-value metadata.
- Provider contact direction aliases.
- Station-calendar direction aliases.
- Provider-result map keys used for contact/command result labels.
- Activity stable-identity fields.
- Station-calendar ID-list fields used by invalid-input review.

## `command_window_report.v1`

Standalone `command_window_report.v1` required window/classification/review/source-lineage counters export and validate as non-negative integers.

Existing `command_window_report.v1` artifacts are also accepted by
`CommandWindow.report/1` and `OrbitalDynamics.command_window_report/1` as
idempotent handoff inputs before any raw-activity command-window rows are
derived.

CandidateRefresh source and replay summaries preserve command-window direction
routing as row-derived direction counts plus activity/window IDs by direction,
and preserve required-action counts from row evidence before stale aggregate
fields, so command, uplink, tracking, health-check, and operator-action review
pressure remains visible without reopening full command-window rows.

## Contact filter

### `contact_filter_report.v1` rows

V1 campaign artifacts and refreshed-candidate artifacts include `contact_filter_report.v1` rows that:

- Suppress malformed downlink/tracking-like filter inputs missing identity, station, or timing fields, or carrying malformed stable-ID contact/station/source-window/scenario identity, into invalid-input review handoffs instead of keeping them as ordinary candidates.
- Publish non-negative scalar candidate counters in executable validation and JSON Schema exports.
- Preserve suppressed contact direction routing in CandidateRefresh source/replay summaries as deterministic direction counts and contact IDs by direction.

Standalone filter reports preserve malformed non-map handoffs as `invalid_contact_shape` evidence (instead of crashing).

Existing `contact_filter_report.v1` artifacts are also accepted by
`ContactFilter.report/1` and `OrbitalDynamics.contact_filter_report/1` as
idempotent handoff inputs before any raw-candidate filtering is derived.

Resource-filter triage uses the same artifact-only boundary:
`ResourceFilter.summary/1`/`2`/`3` and
`OrbitalDynamics.resource_filter_summary/1`/`2`/`3` publish the validated
`resource_filter_summary.v1` contract over suppressed-candidate review rows,
invalid resource-summary inputs, reason/blocking-dimension/source-quality/trust
boundary count maps, grouped candidate ID routing, and no-schedule-mutation
assumptions. The summary validates its aggregates from embedded review evidence
so review/import routing does not depend on stale top-level counts.

### `ContactFilter.capabilities/0`

`ContactFilter.capabilities/0` advertises:

- The direct station/contact capacity fraction and percent paths.
- Typed fraction/percent capacity-value metadata used for zero-capacity suppression.
- Contact stable-identity fields.
- Provider direction aliases.
- Provider-result map keys.
- Provider-counteroffer handoff fields, including offered start/end seconds and
  start/end/duration timing deltas.

### Provider-counteroffer review handoff

Provider-counteroffer review handoff semantics apply for `review_provider_counteroffer` suppressions. These preserve the following through contact-filter rows, operator-review rows, and Cadence-import rows (instead of crashing):

- Counteroffer ID.
- Status.
- Negotiation state.
- Reason.
- Cost delta.
- Lock deadline.
- Offered timing and start/end/duration timing deltas.

### Downlink inference

Standalone filter reports also infer downlink filtering for provider-shaped station/time rows without explicit type or direction, so those rows do not bypass declared station rules.

## Contact contention

### `contact_contention_report.v1` rows

V1 campaign artifacts also include `contact_contention_report.v1` rows for same-station overlapping contacts and same-spacecraft overlaps across multiple stations, including:

- Direction-only command/uplink/tracking/health-check/downlink station rows.
- Typed health-check contacts.
- Provider-shaped station/time rows without explicit type or direction.

Existing `contact_contention_report.v1` artifacts are accepted by
`ContactContention.report/1` and
`OrbitalDynamics.contact_contention_report/1` as idempotent handoff inputs
before any raw-contact contention groups are derived. Existing
`contact_contention_resolution_report.v1` artifacts are accepted by
`ContactContention.resolution_report/1` and
`OrbitalDynamics.contact_contention_resolution_report/1` before any advisory
recommendations are derived from contacts plus a contention report.

These use planner-native `scenario_id` as spacecraft scope when no explicit `spacecraft_id` is present.

CandidateRefresh source and replay summaries preserve contact-contention
direction routing as row-derived direction counts and contact IDs by direction,
so mixed downlink, command/uplink, tracking, and health-check conflict pressure
stays visible without regenerating contention groups.

### Resolution recommendations and review routing

- Advisory `contact_contention_resolution_report.v1` recommendations.
- CandidateRefresh source and replay summaries preserve recommendation
  required-action counts from row evidence before stale aggregate fields, so
  contention-resolution action pressure remains visible without reopening full
  recommendation rows.
- Embedded V1 campaign contention groups now lift into `contact_contention_review` and Cadence `review_contact_contention` rows with campaign-source provenance.
- The same standalone `ContactContention` public API.

**Artifact-only facades** — `OrbitalDynamics.contact_contention_report/2`, `OrbitalDynamics.annotate_contact_contention/2`, and `OrbitalDynamics.contact_contention_resolution_report/3` / `contact_contention_resolution_summary/3` provide artifact-only contention review outside a full campaign build.

### Counters and `ContactContention.capabilities/0`

Contention report counters, conflict-group counters, and advisory recommendation candidate counters export and validate as non-negative integers.

`ContactContention.capabilities/0` advertises resolution-summary semantics before they feed review/import routing:

- Conflict group.
- Recommendation.
- Review-recommendation.
- Resource-scope.
- Selection-reason.
- Action-count row semantics.
- Required-capacity fraction/percent paths and typed value-path metadata used
  to derive capacity-pack demand totals.

### Invalid-input and malformed handling

Contention reports:

- Preserve contact-like rows missing identity, station, or timing fields as `invalid_contact_inputs` that flow into operator-review and Cadence-import handoff instead of being dropped before overlap detection.
- Validate malformed stable-ID contact/station/source-window/scenario/spacecraft identity as invalid-input review evidence before grouping.
- Turn malformed non-map handoffs into `invalid_contact_shape` rows rather than crashing the standalone contention API.

### Resolution summaries

Contention resolution summaries publish the validated
`contact_contention_resolution_summary.v1` contract, deriving group and
recommendation counts from recommendation rows before exposing:

- Selected, deferred, review, and ambiguous duplicate contact ID sets.
- Group/action/reason count maps for review/import routing.
- Capacity-pack required-capacity demand totals, selected/deferred demand
  totals, by-status demand maps, and selected/deferred per-station demand maps
  derived from source contact candidates using advertised direct and nested
  throughput/capacity/activity-context required-capacity fraction/percent paths.
- Required-capacity source counts and contact-ID routing by source, derived
  from recommendation rows instead of stale summary fields.
- CandidateRefresh replay preserves selected/deferred recommendation direction
  counts and contact IDs by direction from recommendation source-contact rows,
  so mixed downlink, command/uplink, tracking, and health-check resolution
  pressure remains visible without reopening full recommendation payloads.

The summary contract validates its routing/count maps, capacity-pack totals, and
source-count/contact-ID maps from the compact summary fields so review/import
handoffs do not trust stale top-level aggregates. Generated summaries also carry
the exact `ContactContention.capabilities/0` `model_limits`, pinned by
executable validation and JSON Schema export. Existing
`contact_contention_resolution_summary.v1` artifacts are accepted as idempotent
compact handoff inputs when adapters already hold the summary. This is done
**without candidate suppression, provider reservation, or schedule mutation**.

Executable resolution validation checks each recommendation's `candidate_count` against `source_contact_candidates` and selected plus deferred contact IDs before review/import handoff.

### Priority fields

Contention resolution recommendations also expose:

- Requested custom priority fields.
- Per-field numeric evidence counts.
- `priority_fields_without_numeric_evidence_count` / `priority_fields_without_numeric_evidence`, so review/import queues can see when any declared priority field was unusable for that candidate set.

### Review status constraint

Contention invalid-input rows and resolution recommendations constrain `review_status` to `operator_review_required` in executable validation and exported JSON Schema, so review/import queues cannot invent readiness labels.

### Approval and policy evidence

Contention groups and deterministic resolution recommendations can optionally carry the following when supplied an approval policy:

- `approval_requirements`.
- Approval-rule matches.
- `policy_decision.v1` evidence.

They also:

- Aggregate source contact/command success evidence and feedback confidence factors through policy, review, and import rows.
- Apply priority-aware selection rules that can prefer explicitly prioritized command/contact rows while preserving selected/deferred priority evidence through allocation, operator-review, and Cadence-import rows.
- Schema-validate report-level and generated summary `model_limits` arrays
  against `ContactContention.capabilities/0`.

That capability metadata also names:

- The provider direction aliases.
- Provider-result map keys.
- Default priority field order.
- Accepted priority-override aliases.
- Contact stable-identity fields.

Duplicate contact IDs inside a conflict group are surfaced as ambiguous contact identity rather than being resolved to an arbitrary selected contact.

### Overlap-pressure metrics

Contact-contention groups and deterministic resolution recommendations now compute overlap-pressure metrics from contact intervals, including:

- Contention-window seconds.
- Summed contact duration.
- Active-overlap seconds.
- Maximum concurrent contacts.
- Pairwise overlap count.

These metrics carry through operator-review and Cadence-import rows so ground-network queues can route severity without unpacking source candidates.

### Conservative station capacity context

Contention policy/review/import rows now preserve conservative station capacity context (`capacity_fraction`, `capacity_fraction_min`, and `capacity_fraction_max`) from declared station capacity fractions or provider percent aliases such as:

- `capacity_percent`.
- `capacity_pack_capacity_fraction`.
- `station_capacity_percent`.
- Nested throughput/capacity/activity context variants.

`ContactContention.capabilities/0` advertises those direct and source station-calendar capacity paths plus typed fraction/percent capacity-value metadata, so reduced-capacity evidence remains visible even when contention, rather than allocation, is the reviewed artifact boundary.
