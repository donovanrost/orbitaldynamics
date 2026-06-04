# Built-in Bundles

## Mission-Ops Escalation Bundle

The mission-ops escalation bundle classifies command, contact, strategic
addition, and downlink-loss authority boundaries with artifact-only escalation
fields: `escalation_level`, `escalation_queue`, `escalation_role`,
`required_authority`, and `sla_s`. The checked-in `policy_bundle_v1.json`
fixture includes all four built-in mission-ops escalation rules so import gates
can review the full authority-boundary vocabulary.

## Timeline Protection Bundle

The timeline-protection bundle applies the same artifact-only escalation shape
to protected timeline changes: locked and approved source activities route to
mission-planning review, while completed or executed source activities are
blocked with flight-director authority metadata. It still only classifies
planner output; it does not approve work or mutate schedules.

## Degraded Payload Guard Bundle

The degraded-payload guard blocks observation changes when source activity
context declares `degraded: true` or `payload_available: false`, and blocks
contact/downlink/tracking changes when `antenna_available: false`, while
command and health-review requirements can remain `auto_approvable` in degraded
mode. It also routes malformed resource-filter candidate and resource-summary
inputs to resource-planning review when those rows are evaluated through the
same approval-policy bundle. The
checked-in `policy_bundle_degraded_payload_guard_v1.json` fixture covers those
boolean match fields, including explicit `false` values.

## Ground-Network Allocation Bundle

The checked-in `policy_bundle_ground_network_allocation_v1.json` fixture covers
the ground-network allocation bundle. It blocks unavailable/maintenance station
contacts, requires operator review for declared reservation overlaps, and
requires review for severe reduced-capacity contacts using `station_availability`
and `capacity_fraction` rule matches. It also blocks reduced-capacity allocation
rows whose `allocation_reason`/`suppressed_reason` is
`ground_station_reduced_capacity_insufficient`, preserving
`required_capacity_fraction` and available `capacity_fraction` in the matched
policy evidence. It also routes low
`actual_completion_fraction` evidence from link-capacity approval context to
ground-network review, and routes missing station-calendar trust-boundary
evidence from allocation context plus invalid contact-contention input review to
the same contact-scheduling authority. It also routes invalid link-capacity
candidate/selected inputs to ground-network review with
`invalid_link_capacity_input_review` evidence. It
routes any custom contact-priority field with missing numeric evidence through
`missing_priority_field_evidence_review` using
`priority_fields_without_numeric_evidence_count_min`, while preserving the
specific missing field names from scalar or list-valued requirement context as
rule-match evidence. It
also routes same-station contact-contention groups and their deterministic
resolution recommendations to ground-network review without treating the
recommendation as a provider reservation write. It
classifies review boundaries only; it does not reserve station time or mutate
schedules.

## Resource-Projection Authority Bundle

The checked-in `policy_bundle_resource_projection_authority_v1.json` fixture
covers the resource-projection authority bundle. It matches resource pressure
status/types, source quality, trust-boundary status, and first pressure kind
from `resource_projection_report.v1` approval context so Cadence import gates
can route resource pressure review without reopening raw resource rows. It also
routes invalid resource-projection activity and resource-summary inputs through
resource-model authority review with explicit rule-match evidence. It
classifies review/escalation boundaries only; it does not accept a resource
model or mutate mission state.

## Operator-Review Queue Authority Bundle

The checked-in `policy_bundle_operator_review_queue_authority_v1.json` fixture
covers deterministic operator-review queue routing. It matches
`review_queue`/`review_queues` and `review_queue_key`/`review_queue_keys` from
operator-review approval context, routing resource queues to resource planning,
including resource-filter invalid-summary, resource-projection invalid-summary,
and suppressed-candidate queues;
contact/contention/allocation/station-calendar/link-capacity queues to ground
network scheduling, timeline integrity/diff/command-window queues to mission
planning, maneuver queues including invalid maneuver recommendations to flight
dynamics, and policy escalation queues to
mission operations. It still
only classifies queue authority; it does not execute approval workflow.

## Command/Contact Authority Bundle

The checked-in `policy_bundle_command_contact_authority_v1.json` fixture covers
direction-specific command/contact authority boundaries. It sends command and
uplink windows to command authority, tracking windows to tracking operations,
downlink contacts to ground-network scheduling authority, and health-check
commands to command authority. It also routes explicit failed command evidence
and low `command_success_factor` confidence from command-window context to
command authority review, routes normalized scalar, list-valued, or map-valued
raw `command_result` failure
aliases such as `rejected` or `timed-out` to the same authority, routes failed
contact evidence or low `contact_success_factor` confidence to ground-network
review, routes normalized scalar, list-valued, or map-valued raw `contact_result` failure aliases such as
`dropped` or `no-contact` to the same ground-network queue, and routes
missing or invalid `cadence_import_status` handoff context to mission-planning
adapter review. It also matches `review_command_window_station_calendar`
requirements emitted from direct command-window station-calendar overlays:
unavailable or maintenance station time is blocked by policy, while reserved or
reduced-capacity station time is routed to ground-network review with
`contact_schedule_authority` escalation metadata. It also routes invalid
command-window activity inputs to mission-planning review with
`invalid_command_window_input_review` evidence. Policy action rules can match
`cadence_import_status`/`cadence_import_statuses`, and `policy_decision.v1`
rule matches preserve the matched status for import gates and operator-review
handoffs. Runtime policy normalization, executable artifact validation, and the
exported JSON Schemas all constrain those selector values to the same
`invalid` / `missing` / `not_applicable` / `present` vocabulary used by
Cadence import rows, with the schema/validation vocabulary derived from
`Policy.capabilities/0` for adapter preflight checks. Direction
selectors are applied consistently to approval requirements, risk indicators,
branch events, and validated strategic-addition feasibility evidence, so a
downlink authority rule does not overmatch command or tracking evidence that
shares the same risk or event type.

## Contact/Command Review Bundle

The checked-in `policy_bundle_contact_command_review_v1.json` fixture covers
the lighter review-gate bundle for contact schedules, command/health-review
boundaries, and invalid contact-intent activity inputs. Malformed contact-intent
rows remain review/import artifacts, and when this bundle is supplied they now
carry `invalid_contact_intent_input_review` rule evidence through the same
operator-review and Cadence-import handoff fields as valid contact intents.
Station-calendar, contact-filter, resource-filter, contact-contention,
link-capacity, contact-allocation, contact-intent, and command-window
validation now keep those contact/command confidence factors in the same unit
interval before they reach policy, review, or import rows, preserving invalid
station-calendar feedback confidence as review evidence rather than sanitized
confidence.
Policy action-rule thresholds for actual completion fraction plus contact,
command, observation, and maneuver success factors use the same unit-interval
contract, so confidence policies cannot be configured with impossible trigger
bounds.
Runtime normalization enforces map-shaped action rules, stable action-rule IDs,
unique action-rule IDs, unit-interval threshold fields, boolean action-rule
fields, selector string fields/lists, and escalation SLA numbers for inline
policies before classification. The executable `policy_bundle.v1` validator
applies the same action-rule ID uniqueness boundary to artifact-backed bundles.
It also validates fallback risk/approval limits and
blocked-risk type lists before applying the fallback classifier, so bad operator
or adapter policy input fails deterministically instead of producing a
misleading `policy_decision.v1`.
Policy rule matching canonicalizes station-calendar availability, contention,
reservation status, reservation match status, and provider-calendar reservation
status tokens on both action rules and approval-requirement context before
classification, so provider title case, spaces, or hyphens cannot bypass
ground-network policy review.
Inline and organization-specific policy inputs accept clean numeric strings for
fallback count limits, unit-interval action-rule thresholds, non-negative
station-calendar ambiguity count thresholds, and escalation SLA seconds before
classification and artifact generation; malformed numeric strings still fail
the same runtime validation instead of being applied as policy.
`policy_decision.v1` rule-match evidence enforces those same unit-interval
bounds for the matched source confidence factors carried forward to review and
import surfaces.
Station provider/calendar, link-capacity, allocation, contact-filter, policy,
operator-review, and import rows also validate station capacity fractions as
unit intervals before applying reduced-capacity evidence. It classifies
review/escalation boundaries only; it does not approve
contacts, send commands, or mutate schedules.

## Maneuver Authority Bundle

The checked-in `policy_bundle_maneuver_authority_v1.json` fixture covers
maneuver timing, impulsive-burn authority, invalid maneuver-recommendation
review boundaries, and failed provider `maneuver_result` aliases such as
`failed` or `timed-out`. It requires operator review with `maneuver_authority`
escalation metadata, but it does not approve burns or mutate schedules.

## Organization-Specific Policy Bundles

Organization-specific policy bundles can be built as `policy_bundle.v1` rows
with adapter provenance and passed inline as `policy_bundle` to
`Policy.decide/5`. Inline bundles remain classification-only; they do not look
up external authorities or execute Cadence workflows. Adapter-shaped
organization policy provenance must declare `provenance.trust_boundary` before
schema validation accepts the bundle.
