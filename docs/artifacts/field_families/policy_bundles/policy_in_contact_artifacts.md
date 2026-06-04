# Policy in Contact Artifacts

## Contact Intent Artifact

`contact_intent.v1` exports timeline identity, nested approval-requirement, and
approval-rule-match arrays, plus schema-visible `model_limits` copied from
`OrbitalDynamics.Communications.ContactIntent.capabilities/0`, so contact
approval metadata follows the same policy, model-boundary, and timeline-link
row shapes; executable validation checks those limits against the same
capability metadata so standalone intent artifacts cannot drift from the
declared no-provider-reservation/no-command-execution boundary. Contact intent
rows also preserve provider result labels as schema-safe scalar strings,
flattening list- or map-valued `contact_result` and `command_result` payloads before
they enter row-local approval context. Command/contact success evidence,
unit-interval confidence factors, and confidence-factor source labels
from either top-level activity fields or metadata likewise flow into
approval-requirement context,
operator-review rows, and Cadence import rows, so policy bundles and import
queues can classify failed or low-confidence contact handoffs without reopening
the source activity payload; out-of-range confidence is review-gated as invalid
contact-intent activity input instead of being clamped into those policy,
review, or import surfaces. Contact intent
generation now consumes
the shared typed activity normalizer as well, preserving dependency/exclusivity
stable-ID arrays, reusable `activity_context`, and dependency ordering,
exclusivity, or opt-in missing-dependency integrity evidence on the
`contact_intent.v1` row. Provider-shaped contact rows with station and timing
evidence but no explicit `type` or `direction` are inferred as downlink contact
intents before timeline normalization, while typed `health_check` activities and
provider-shaped `planned_contact` rows with `direction: health_check` emit
health-check contact intents with `health_check_review` approval requirements,
preserving stable timeline identity and Cadence import context instead of
dropping the handoff. Contact-intent ingress
also parses clean numeric-string timing aliases, estimated throughput, station
calendar overlap counts, reservation-overlap counts, and command/contact
confidence factors before intent inference and schema validation; malformed
numeric strings remain missing numeric evidence rather than being silently
coerced. Rows that use top-level
`activity_type` for command, tracking, downlink, or planned-contact context are
normalized before this inference so explicit adapter activity kinds remain
authoritative. Provider-shaped rows that carry nested `spacecraft` or
`satellite` objects now emit top-level `spacecraft_id` on the
`contact_intent.v1` row and preserve that selector through approval context,
operator-review rows, and Cadence import gates. Malformed `nil`,
boolean, object-without-ID, or non-stable string entries
inside dependency/exclusivity lists are ignored instead of becoming phantom
stable IDs. Malformed contact/command/uplink/tracking activity
inputs that still carry usable station and timing evidence are retained as
`review_invalid_activity_input` contact-intent rows with invalid-input reason
and source activity evidence. Malformed activity, station, scenario, or
source-window stable-ID fields use schema-stable review identities on the
contact-intent row while preserving the raw handoff in `source_activity`, and
the single-row `contact_intent_from_activity!` facade follows the same
validating timeline path as batch generation. Contact intents also preserve station availability,
contention, reservation identity, owner/status, and
`station_reservation_match_status` through the row, nested approval-requirement
context, operator-review rows, and Cadence import rows, so owned reserved
contacts remain distinguishable from reservation conflicts at the approval
handoff boundary. They now carry the same station-calendar trust evidence as
candidate/allocation rows, including `station_calendar_trust_boundary_status`,
`trust_boundary`, `provenance`, `source_station_calendar_entry`, and
`source_station_calendar_overlaps`, through approval context, review rows, and
Cadence import gates. Contact-intent rows also flatten the stable
`station_calendar_entry_id` from nested provider source evidence when the
canonical field is absent, matching operational timeline and allocation
handoffs, and they preserve normalized `station_calendar_directions` from
candidate or nested provider evidence through approval, review, and import
handoffs. Direct contact-intent activity rows that carry `availability` or
`station_calendar_status` outage/maintenance aliases, or nested
`source_station_calendar_entry` / `source_station_calendar_overlaps` status
evidence, now derive the flattened `station_availability` before
approval-policy classification and preserve the canonical status through
approval requirements, operator-review rows, and Cadence import rows.
Contact-intent rows also preserve conservative station capacity context
(`capacity_fraction`, `capacity_fraction_min`, and `capacity_fraction_max`) from
capacity-fraction fields and provider percent aliases such as
`capacity_percent`, `station_capacity_percent`, and nested
throughput/capacity/activity context variants, so contact-intent policy gates
can route reduced-capacity handoffs without implying a provider reservation or
link-budget model. The public
`OrbitalDynamics.contact_intents_from_activities/2` and
`OrbitalDynamics.contact_intent_from_activity!/1` facades expose the same
artifact-only conversion outside a full campaign or candidate-refresh run.
V1 campaign contact intents pass through the campaign approval policy, so
initial contact-review artifacts preserve the same approval requirements,
rule matches, and `policy_decision.v1` evidence as refreshed contact intents.

## Contact Filter Facade

`OrbitalDynamics.Communications.ContactFilter` and the public
`OrbitalDynamics.filter_contact_candidates/3` and
`OrbitalDynamics.contact_filter_report/3` facades expose the artifact-only
ground-network availability model for standalone contact lists. They accept
either normalized ground-network rows or singular/list-valued declared
`station_calendar_provider.v1` artifacts, preserving unavailable, reserved, and zero-capacity suppression rows
without provider reservation or schedule mutation. Invalid downlink/tracking/health-check-like rows missing
identity, station, or timing fields are also suppressed into review
handoff rows instead of being kept as ordinary candidates. Native `downlink`,
`tracking`, and `health_check` rows, `planned_contact` rows whose direction is
`downlink`, `tracking`, or `health_check`, and direction-only station rows for
those directions share the same suppression semantics; health-check suppressions
emit `health_check_review` approval requirements while other contact
suppressions stay contact-schedule reviews, and those requirement types are
lifted onto operator-review and Cadence import suppression rows for adapter
routing. Supplying an `approval_policy` adds row-level policy decisions for
those suppressions, including station-calendar ambiguity and reservation
context in the approval requirement activity context.
When an unavailable or maintenance interval overlaps the same contact as a
station reservation, the unavailable suppression wins while the reservation
overlap evidence remains on the row for audit and import review.
When a downlink candidate declares the same reservation identity as the provider
calendar row, the filter keeps it for allocation review instead of suppressing
it as a reserved-station conflict; the match is still artifact evidence, not a
provider reservation write.
Contact/command feedback evidence from the source candidate remains artifact
data only; it can trigger approval-policy review on an already suppressed row,
but it does not create provider reservations, mutate schedules, execute
commands, or cause otherwise available contacts to be suppressed.
Reports emit schema-visible
`model_limits` so import gates can inspect the model boundary directly.
`OrbitalDynamics.ResourceFilter`
and the public `OrbitalDynamics.filter_resource_candidates/3` and
`OrbitalDynamics.resource_filter_report/3` facades expose that thin
availability/margin model for standalone atom- or string-keyed candidate lists.
The standalone contact filter now applies the same provider-shaped
station-calendar status canonicalization as candidate refresh, so direct
`ContactFilter` callers cannot bypass outage, reservation, or reduced-capacity
suppression by supplying differently cased or hyphenated station states. Direct
contact candidates that already carry station-calendar outage evidence are
suppressed even when no separate ground-network interval is supplied, and nested
source-calendar outage evidence participates in the same severity ordering as
flattened station fields.
Contact allocation applies the same canonicalization to direct contact
station-calendar evidence before allocation status, policy decisions,
operator-review rows, and Cadence-import rows are emitted; direct
`availability` or `station_calendar_status` outage/maintenance evidence is
promoted to flattened `station_availability` so allocation cannot treat it as
ordinary available contact time, and nested source-calendar outage evidence
uses the same precedence over lower-severity direct fields.
Contact-contention and resolution inputs canonicalize direct station-calendar
availability/status plus station-reservation status and match-status evidence
before policy classification and priority-aware ordering, preserving
unavailable-station blocking and owned-reservation priority when provider
adapters use title case, spaces, or hyphenated status values.
Policy decisions apply the same canonicalization to station availability,
contention, reservation status, reservation match status, and provider-calendar
reservation status selectors before action-rule matching.
Operator-review station-calendar packages canonicalize the same direct affected
contact status fields plus nested source station-calendar entry/overlap evidence
before deriving review actions or exporting review rows.
Cadence import manifests built directly from station-calendar reports inherit
that canonical review-package boundary, so import rows expose the same status
tokens without reopening provider-specific casing rules.

## Command Windows and Standalone Planned/Proposed Activities

Command-window rows now use the same timeline activity context for provider
calendar handoffs: command, uplink, and tracking review rows preserve
`station_availability`, `station_calendar_status`, `station_calendar_entry_id`,
provider IDs, normalized `station_calendar_directions`,
trust-boundary/provenance fields, and nested source station-calendar overlays
through approval requirements, operator-review rows, and Cadence-import rows.
Timeline-feedback rows use the same lifted provider-calendar context for
realized feedback: station availability/contention status, station-calendar
entry and direction fields, overlap and reservation lists, trust-boundary
status, and source station-calendar evidence flow through the feedback report,
operator-review row, and Cadence import row.
Standalone `contact_intent.v1` rows can also be normalized directly through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`, producing
`contact_intent_review` rows and `review_contact_intent` Cadence import gates
when approval requirements, approval-rule matches, policy decisions, or
review-required approval statuses are present. Those import gates expose
`contact_intent_gate=contact_intent_policy` and a gate status matching the
review classification so adapters can route contact-intent approval work without
unpacking the source review row; executable validation and JSON Schema constrain
that gate status to the policy classification vocabulary. Contact-intent review
and import rows also lift contact identity, station, direction, timing,
throughput, source-window, approval, and Cadence-import status. V3 branch
derivation treats ordinary approval-required contact intents as review-only, but
direct standalone rows as well as review/import rows replay blocked-by-policy or
missing/invalid Cadence-import downlink intents into branch-local
downlink-completion pressure with source path and trust boundary preserved,
including station-calendar provider and station reservation match evidence for
branch-comparison routing. Operational-timeline review/import rows with usable
feedback factors or provider result/status evidence replay into row-local
contact, throughput, observation, command, or maneuver feedback branches; no-op
monitor rows remain review-only. Contact-intent review and import rows also lift
`requirement_type`, `required_authority`, `policy_bundle_id`, `rule_id`, and
matched policy-escalation level, queue, role, authority, and SLA metadata from
approval requirements, rule matches, and policy-decision escalation metadata so
authority routing remains visible on the handoff row.
Standalone `planned_activity.v1` and `proposed_contact.v1` rows can be replayed
by V3 strategy as branch-local operational-timeline, contact-success, and
station-throughput feedback from either prior-plan or mission-state source
fields, then normalized directly through
`OrbitalDynamics.cadence_import_manifest/2`, producing
`import_proposed_contact` adapter rows without requiring a surrounding
`campaign_plan.v1` artifact. Mission-state standalone planned/proposed rows
preserve `mission_state.source_*` provenance and feed the same operational
feedback merge as prior-plan standalone rows. Mission-state
`source_result_artifact` / `result_artifact` wrappers can bundle the same
`source_planned_activity`, `planned_activity`, `source_planned_activities`,
`planned_activities`, `source_proposed_contact`, `proposed_contact`,
`source_proposed_contacts`, and `proposed_contacts` fields into that live replay
path while nested rows inherit wrapper trust boundaries when they do not declare
their own. The standalone contract now exposes source-window ID, timeline ID,
timeline identity, station availability, schedule conflict status, and
model-limit evidence at the top level so import gates do not have to unpack the
nested source window to route contact proposals. Prior-plan
`source_result_artifact` / `result_artifact` wrappers can now use the same
canonical or adapter-facing `source_*` planned/proposed row keys, and V3
preserves the selected wrapper path plus inherited trust boundary when deriving
command, contact-success, and station-throughput feedback branches. Strategy
operational-feedback provenance now also summarizes standalone planned,
proposed, and realized source rows with deterministic activity-type, direction,
Cadence import status, planned-protection decision, and realized-status counts
where those fields are present, so adapter queues can route replayed source-row
pressure without reopening each nested row.
Proposed-contact import rows preserve
station-calendar trust/source evidence, including
`station_calendar_trust_boundary_status`, `trust_boundary`, `provenance`,
`source_station_calendar_entry`, and `source_station_calendar_overlaps`, so
initial schedule-import queues can route declared provider state without
reopening nested station-calendar reports. Standalone proposed-contact rows may
also declare `model_limits`, and executable validation plus exported JSON Schema
constrain that optional field to the artifact-only, no-provider-reservation,
no-schedule-mutation boundary. Malformed non-object proposed-contact
`cadence_import` values produce review-required import rows with invalid
Cadence import evidence instead of crashing the import manifest builder.
Standalone `planned_activity.v1` rows can be normalized directly through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`, reusing the operational-timeline
classification model to produce `operational_timeline_review` and
`review_operational_timeline` rows for command/contact review, approval review,
conflict resolution, terminal-exception review, or missing Cadence import
preparation.
Malformed non-object `cadence_import` values remain reviewable as
`review_invalid_cadence_import` rows and `invalid` Cadence import status rather
than being treated as valid import identities.
They also preserve an optional raw `execution_uncertainty` map on the standalone
activity contract; timeline/review artifacts derive status and 3-sigma summary
fields from that map, and the exported schema now types its timing, delta-v
vector, and source fields without implying command execution or finite-burn
propagation. Standalone planned activities can also carry
`contact_success_factor`, `observation_success_factor`,
`command_success_factor`, `maneuver_success_factor`, and their source labels so
confidence evidence can flow into timeline/review handoffs without requiring a
full campaign wrapper. Those success factors now use the executable
unit-interval contract at the standalone row boundary as well. Planned-activity
review/import rows also preserve `station_calendar_trust_boundary_status`,
`trust_boundary`, `provenance`, `source_station_calendar_entry`, and
`source_station_calendar_overlaps`, so command/contact timeline queues can
distinguish declared provider state from missing-boundary station data without
reopening nested station-calendar reports.
