# Operational Timeline and Normalization

`OrbitalDynamics.operational_timeline_report/2` can build the same
`operational_timeline_report.v1` shape for planned activity lists outside the
campaign planner. `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2` can now normalize standalone
operational-timeline rows that require command review, approval review,
conflict resolution, terminal-exception review, or missing Cadence import
preparation into deterministic artifact-only review/import queues.
When standalone `planned_activity.v1`, `realized_activity.v1`,
`realized_state_snapshot.v1` activity rows, or operational-timeline rows appear
directly in a prior plan, or return through an operator-review package, their
source contact, throughput, observation, command, maneuver, and image-quality
evidence feeds the same strategy `operational_feedback` handoff used by
timeline-feedback artifacts.
Direct command-window, contact-intent, and operator-review builders flatten
list- or map-valued provider result fields
such as `contact_result`, `command_result`, `observation_result`, and
`maneuver_result` to deterministic comma-joined strings before exporting
schema-typed review rows; Cadence import builders apply the same normalization
to schema-typed import rows and activity-context handoffs.
Executable validation checks `operational_timeline_report.v1` report-level
`model_limits` against `OrbitalDynamics.Timeline.model_limits/0`, keeping the
no-mutation and no-command-execution boundary machine-checkable.
Executable validation checks `operator_review_package.v1` package-level
`model_limits` against `OrbitalDynamics.OperatorReview.capabilities/0`, so
review packages cannot drift from the artifact-only no-mutation boundary while
still passing schema lint. `cadence_import_manifest.v1` performs the same
capability-exact check against `OrbitalDynamics.CadenceImport.capability/0`, so
adapter handoff artifacts cannot overstate write, approval, or conflict
resolution authority. Cadence import also advertises the supported
`import_action`, `import_status`, `cadence_import_status`, and
`source_review_type` vocabularies through that capability surface, and
executable validation plus JSON Schema constrain row import actions, import
statuses, flattened `source_review_type` fields, and embedded
`source_review_row.review_type` values to those vocabularies. When a row carries
source review queue evidence, executable validation also checks
`source_review_queue_key` against
`source_review_type|source_review_queue|approval_status`, keeping row routing
aligned with the manifest's derived queue counts. Activity
inputs missing stable identity, carrying malformed activity IDs, or declaring
malformed stable-ID identity fields such as scenario, station, target,
source-window, explicit timeline, product/payload/instrument, provider-calendar,
or scalar station-overlay IDs are preserved as
`review_invalid_activity_input` rows with schema-stable review IDs and source
activity evidence instead of failing report generation or being treated as valid
planned work. Non-stable station-calendar overlap, ambiguous-entry, or
reservation-list IDs are ignored instead of becoming phantom overlay links. Inputs
missing activity type remain review-gated unless they are provider-shaped
station/time contacts with no explicit direction or with `direction: downlink`;
those rows normalize to canonical downlink timeline rows with
`ground_station_id`, `starts_at_s`, and `ends_at_s`.
Top-level `activity_type` is also accepted as the planned activity type alias
for operational timeline input rows, so exported or provider-shaped timeline
rows can round-trip without being rewritten to `type` first.
Provider direction aliases such as `cmd`, `commanding`, `Track-ing`, and
`healthcheck` are normalized before operational kind classification and
operator-action routing, matching typed activity and contact-allocation ingress.
The standalone `planned_activity.v1` contract now exposes and validates command
and maneuver success factors as unit-interval confidence values, accepts
top-level `activity_type` as the type alias already used by operational timeline
ingress, preserves their source labels, preserves provider data-volume
requirement, selected/planned volume, delivered/received volume, shortfall, and
downlink-completion source aliases, and carries raw execution-uncertainty maps
as first-class handoff evidence for timeline, review, and import artifacts.
Operational timeline input rows that declare out-of-range unit-interval activity
context, including resource margins, battery state of charge, quality fractions,
or command/contact/observation/maneuver success factors, are preserved as
`review_invalid_activity_input` rows instead of emitting schema-invalid activity
context.
Command-result shaped rows without an explicit command type or direction stay
invalid for operator review. Malformed non-object `cadence_import` values are
preserved as invalid Cadence import review rows with source import-shape evidence
instead of crashing timeline normalization. Cadence import maps that declare
adapter/provider context without a trust boundary, or that carry a malformed
external ID, are routed to the same invalid-import review path instead of
emitting schema-invalid timeline rows. Missed, failed, canceled/cancelled,
and rejected statuses increment `terminal_exception_count` rather than
`executed_count`. Provider result failure aliases on otherwise completed or
executed contacts and commands, such as `contact_result: dropped` or
`command_result: accepted, rejected`, are also routed to terminal-exception
review. Scalar result values are preserved, and list-valued provider results are
flattened to deterministic comma-joined strings in the operational timeline row,
activity context, operator-review row, and Cadence-import manifest row.
Operational timeline lifecycle statuses are constrained by the same
schema-visible vocabulary published by `Timeline.capabilities/0`; unsupported
provider lifecycle statuses are preserved as `review_invalid_activity_input`
rows instead of being persisted as arbitrary row status values.
Rejected or policy-blocked approval states retain their resolve actions even
when the activity also reports a completed, partial, or executed status, so
terminal lifecycle state cannot hide an approval violation from review/import
routing.
Executable validation rejects duplicate operational-timeline
row IDs so adapter handoffs do not need to resolve ambiguous row identity. This
remains report-only: it does not reserve contacts, mutate schedules, or execute
commands.
Operational timeline reports also expose row-derived
`activity_status_counts`, `approval_status_counts`,
`required_operator_action_counts`, `cadence_import_status_counts`, and
`operational_kind_counts` maps. Executable validation checks those maps against
the rows when present and requires integer count-map values, so adapters can
consume queue/status distributions without recounting rows.
Executable validation also treats operational-timeline and timeline-diff scalar
counts, row-derived count fields, and diff row ranks as integers while timing,
throughput, data-volume, and delta fields remain numeric. Operational timeline
activity contexts and timeline-diff source/replacement contexts preserve
provider data-volume requirement, selected/planned volume, delivered/received
volume, and shortfall aliases so review/import rows can feed branch-local
downlink replay without adapter-side field rewriting.
Cadence import manifests now also include row-derived
`import_action_counts`, `import_status_counts`,
`cadence_import_status_counts`, `source_review_type_counts`, and
`source_review_action_counts`, and `source_review_queue_counts` maps, with
executable validation checking that the maps match the manifest rows when
present and that count-map values are integers. Manifest scalar counts such as
`row_count`, `ready_count`,
`review_required_count`, `blocked_count`, and `missing_import_count` are
executable integer counts, matching the exported JSON Schema instead of
accepting float-shaped count values.
Operator-review packages now advertise their supported
`source_artifact_type` contracts through `OperatorReview.capabilities/0`, and
the exported `operator_review_package.v1` schema plus executable validation
reject unsupported source artifact types instead of treating arbitrary provider
labels as valid review provenance. The public
`OrbitalDynamics.operator_review_package/1` facade now also accepts already-built
operator-review packages as pass-through artifacts and rejects non-map or
unsupported artifact-contract inputs with explicit boundary errors.
Cadence import row ranks and schema-integer row count evidence are also
validated as integers so adapter queues do not accept float-shaped counts;
throughput, capacity, timing, score, and margin fields remain numeric. The
manifest capability now advertises import-status and Cadence-import-status
vocabularies, and executable/schema validation constrains row-level
`cadence_import_status`, source, and replacement status fields to
present/missing/invalid/not-applicable values. The exported
`cadence_import_manifest.v1` schema also constrains top-level
`source_artifact_type` to the capability-advertised supported source contracts,
and executable validation rejects unsupported manifest source artifact types.
The public Cadence import manifest builder rejects non-map inputs and maps with
unsupported `schema_contract` values with explicit `ArgumentError` messages that
list the supported artifact contracts, preserving the adapter/import boundary
instead of exposing function-clause failures to callers. Already-built
`cadence_import_manifest.v1` artifacts pass through the public manifest facade,
with atom-key maps normalized to string-key JSON shape.
Rows with duplicate derived or persistent timeline identities are counted and
marked `review_duplicate_timeline_identity`, preserving the colliding activity
IDs and normalized source rows so review/import consumers do not treat the
identity as unique.
Rows with dependency or exclusivity integrity issues are counted and marked
`review_timeline_integrity`. The report checks dependency ordering and
explicit exclusivity overlaps when referenced rows are present, can opt into
missing-dependency validation for closed-world imports, detects deterministic
dependency cycles across activity-ID and timeline-ID dependency graphs, and
preserves shared `exclusivity_group` overlap evidence without changing the
activity list. Cycle evidence is flattened as
`dependency_cycle_activity_ids` / `dependency_cycle_timeline_ids` and preserved
through operator-review and Cadence-import rows.
Activities that declare `execution_uncertainty` now preserve that map as
artifact-only review metadata, derive `timing_3sigma_s`,
`delta_v_3sigma_km_s`, `delta_v_3sigma_magnitude_km_s`, and
`execution_uncertainty_source` when present, and increment
`execution_uncertainty_declared_count`; maneuver rows without uncertainty are
marked `execution_uncertainty_status: missing` and counted separately. The raw
map is also schema-visible as a typed object for timing 3-sigma, delta-v
3-sigma vectors, and source labels rather than an unconstrained blob. Timeline
activity normalization also parses clean numeric-string timing aliases and known
execution-uncertainty numeric fields before report validation; the reusable
activity context likewise parses clean numeric strings for known throughput,
data-volume, resource-margin, latency, pointing, and capacity fields while
normalizing JSON-style resource availability/degraded booleans and dropping
malformed optional typed values as missing evidence. The
same metadata flows through operator-review and Cadence-import rows without
implying command execution, finite-burn propagation, or schedule mutation.
`OrbitalDynamics.normalize_timeline_activity/2` exposes the same typed activity
normalization for a single planned activity without adding a report-row ID, and
`OrbitalDynamics.normalize_timeline_activities/2` applies it to a list while
preserving duplicate timeline identity and dependency/exclusivity integrity
review markers. Repair, approval, review, and import code can share
command/contact classification, operator action, protection, and timeline
identity semantics without constructing a full report.
Operational timeline, command-window, timeline-diff, and operator-review rows
that carry timeline identity objects use the same stable-ID-compatible nested
shape in executable validation and exported JSON Schema. Operational timeline
rows now carry the same reusable `activity_context` shape directly, and approval
requirements, plan deltas, operator-review rows, and Cadence import rows share a
permissive nested activity-context schema for durable `timeline_identity`,
dependency, and exclusivity stable-ID arrays, plus timing, target, station
availability, schedule-conflict, score, throughput, target-priority, and
observation/contact-feedback, command-success-factor, and command result/success
context when present. Operational activity context also preserves resource, product, and
collection IDs, payload/instrument IDs, resource source/trust/provenance,
resource blocking dimension, margin, battery, availability evidence, and
declared/measured thermal evidence with zone identity, operating bounds,
derived margin, status/model/source/confidence, and planned/actual data-volume evidence
such as planned volume, delivered volume aliases, delta, completion fraction,
estimated storage, downlink, and required downlink megabytes, plus planned and
actual throughput aliases with throughput delta and completion fraction, and
collection/delivery latency evidence including collection end time, planned and
actual delivery time, max latency, planned/actual latency, latency delta, and
latency margin. Link profile and quality context is preserved as artifact
evidence as well, including protocol, frequency band/RF-band aliases,
modulation, coding, polarization, data rate, link margin, SNR, Eb/No, bit error
rate, packet/frame loss, carrier/symbol lock, and link-quality/RF status
aliases. Declared pointing/attitude context is also preserved as
artifact evidence: pointing mode, pointing target, boresight axis, off-nadir and
slew angles, pointing error/status/model/source/confidence, explicit attitude
mode/target, roll/pitch/yaw, attitude error/status/model/source/confidence, and
planned-versus-realized pointing target/mode/delta fields flow through
timeline-feedback, operator-review, and Cadence-import rows without claiming an
attitude propagator. `MissionPlan.Activity` and `study_manifest.v1` now accept
declared product data-volume, required downlink, collection/delivery latency,
planned/actual throughput, resource source/trust/provenance, margin, battery,
availability/degraded mode, incompatible/suppressed activity type, pointing,
attitude, link profile/quality, and thermal fields as first-class activity inputs, with
the manifest schema exposing explicit attitude mode/target, roll/pitch/yaw,
attitude error/status/model/source/confidence fields. Common provider-style
volume, delivery, throughput, link/RF, resource
availability, attitude, and temperature aliases normalized at the typed
activity ingress boundary; first-class planned activities with
`type: "attitude"` also promote pointing aliases into explicit attitude fields
when canonical attitude fields are absent, and operational timeline rows
classify them as `operational_kind: "attitude"`;
station-calendar overlap, reservation, trust-boundary, and source provider
evidence also flows through planned-activity operational timeline review/import
rows when supplied by the activity context; reusable activity context flattens
`station_calendar_entry_id` from nested `source_station_calendar_entry.id` when
the canonical field is absent, while retaining the full source entry and overlap
evidence;
executable validation enforces those
stable-ID fields plus numeric/object types for score, throughput, feedback, and
station-calendar overlap/reservation fields while still allowing
adapter-specific context keys. The public
`OrbitalDynamics.timeline_identity/1`,
`OrbitalDynamics.timeline_activity_context/1`, and
`OrbitalDynamics.timeline_link/2` helpers expose that durable identity, context,
and source-to-replacement link shape for repair, approval, review, and import
rows without requiring consumers to rebuild planner-local identity logic. Generic
Cadence import rows preserve activity context and source/replacement timeline
identity when the operator-review row carries them, so review-only adapter
handoffs retain dependency and exclusivity evidence.
Operational-timeline Cadence import rows are typed
`review_operational_timeline` adapter gates that surface the source timeline row
as `source_operational_timeline`, along with dependency/exclusivity evidence,
schedule status, source approval state, and Cadence import presence plus the
declared adapter external ID and schema contract when present. When policy
evidence is present, the same rows preserve matched escalation authority, rule,
queue, role, level, SLA, and source escalation metadata for adapter routing. Invalid
operational activity input rows carry the same source timeline row and source
activity evidence for adapter cleanup. V3 branch derivation can replay usable
standalone planned-activity rows, direct operational-timeline rows, and
operational-timeline review rows, including flattened Cadence import rows, as
row-local contact-success, station-throughput, observation, command, or maneuver
feedback branches while preserving the source path and trust boundary. Rows
with dependency-order, dependency-cycle, missing-dependency, or exclusivity
issues also replay as `timeline_integrity_feedback` branch events, so V3 branch
risk and review summaries expose the concrete integrity issue instead of
treating it as passive row metadata. Branch-comparison rows, strategy
operator-review rows, and Cadence strategy import rows flatten the affected
activity IDs, timeline IDs, dependency buckets, and exclusivity groups for
adapter routing without reopening raw branch events. Maneuver execution
uncertainty branch rows likewise flatten affected activity/timeline/maneuver
IDs, declared uncertainty status/source, and max timing and delta-v 3-sigma
evidence into the same strategy handoff rows, with selected-recommendation risk
rows retaining the underlying threshold, source, and trust-boundary evidence.
Policy-escalation Cadence import rows are typed `review_policy_escalation`
adapter gates rather than generic handoffs; they expose policy bundle, rule,
queue, role, required authority, SLA, source escalation, and source decision
context alongside the full source review row.
Resource-projection Cadence import rows are also typed adapter gates; they
surface storage/downlink pressure rollups, first pressure activity fields,
resource source quality, warnings, effective/ignored activity counts,
ignored activity IDs, matched policy-escalation routing fields, and the
original `source_resource_projection` row without requiring adapters to unpack
`source_review_row`.
Link-capacity Cadence import rows are typed `review_link_capacity` gates with
ground-station throughput rollups, selected-contact IDs, unused adjusted
capacity, selection-utilization status, policy evidence, matched
policy-escalation routing fields, and the original
`source_link_capacity` row. V1 campaign artifacts route embedded
`link_capacity_report.v1` rows through those same operator-review and Cadence
import gates with `campaign_plan.link_capacity_report` provenance.
Operational timeline rows now carry station-calendar entry, overlap,
ambiguous-entry, reservation identity, reservation owner/status, and
`station_reservation_match_status` context directly through timeline rows,
activity context, operator-review rows, and Cadence-import rows. Timeline diffs
treat changed station reservation identity or ownership-match status as
review-significant instead of hiding it inside generic activity metadata.
Newly generated operational-timeline, timeline-diff, timeline-feedback,
command-window, maneuver-review, station-calendar, station-contention,
contention-resolution, link-capacity, contact-allocation, resource-projection,
operator-review, contact-intent, Cadence import, and scoring/comparison
artifacts include
top-level `model_limits` arrays so downstream tools can inspect the
artifact-only boundary without scraping assumptions prose; the field is optional
for backward compatibility with older fixtures. The standalone JSON Schema
exports for contact intent, command-window, link-capacity, contact-allocation,
contact-filter, contact-contention, contention-resolution, station-calendar,
resource-filter, and resource-projection reports now constrain those top-level
`model_limits` as exact string sets matching the executable capability
validators. Policy decisions/bundles, operator-review packages, maneuver-review
reports, execution reports, Monte Carlo reproducibility reports, study
benchmarks, timeline reports, Cadence import manifests, and planner explanation
reports follow the same export rule where their executable contracts already
check exact model-limit values.
`contact_filter_report.v1` also emits top-level `model_limits` copied from
`OrbitalDynamics.Communications.ContactFilter.capabilities/0`, making its
externally supplied ground-network, no-provider-reservation,
no-schedule-mutation, and no-link-budget boundaries visible to import gates;
executable validation checks the field against that capability metadata so
filter reports cannot silently drift from the advertised artifact boundary.
Contact-like filter inputs missing identity, station, or timing fields, or
carrying malformed stable-ID contact, station, source-window, scenario, or
station-overlay identity, or declaring out-of-range contact/command feedback
confidence,
are emitted as `invalid_contact_input` suppressed rows with
`invalid_contact_input_reason`, `review_invalid_contact_filter_input`, and the
original source contact candidate, so malformed downlink/tracking handoffs
become operator-review and Cadence-import evidence instead of passing through as
kept rows or clamped confidence evidence. Contact filtering parses clean
numeric-string contact timing aliases,
station capacity fractions, and top-level or metadata-supplied contact/command
trimmed case-insensitive success booleans, results, factors, and source labels before suppression
decisions, and normalized source station-calendar evidence is kept numeric for
schema-validated review rows; malformed numeric strings remain missing evidence
and continue through the existing invalid/review paths. Those
invalid-contact rows also preserve nested provider station-calendar entry
evidence as a flattened `station_calendar_entry_id` and source calendar payload
when supplied. Top-level `activity_type` is accepted as a contact type alias before
filtering, allocation, contention, and link-capacity grouping, so exported
timeline-style command/tracking/downlink rows preserve their explicit contact
kind instead of being inferred as provider downlinks. Provider-shaped
station/time rows without explicit `type` or
`direction` are inferred as downlink filter inputs, so valid rows are filtered
against declared station state and malformed rows keep the invalid-input review
path. Malformed non-map candidate handoffs are retained as
`invalid_contact_shape` rows with raw input evidence instead of crashing direct
filter report generation. Suppressed contact rows preserve station-calendar overlap, reservation-list,
ambiguous-entry metadata, and declared-or-missing station-calendar trust
boundary status so review/import queues can see provider-calendar uncertainty
and trust provenance without reopening a nested station-calendar report.
Direction-scoped station-calendar context is schema-visible as
`station_calendar_directions` on filter/allocation review rows, proposed
contacts, candidate activities, contact intents, station-calendar rows, and
provider evidence entries; executable validation requires those arrays to
contain strings.
Suppressed contact rows also flatten `station_calendar_entry_id` from nested
provider source evidence when the applied station row only carried its provider
entry under `source_station_calendar_entry`.
Suppression
review/import rows also carry singular reservation identity, owner/status, and
`station_reservation_match_status` when present, preserving whether a blocked
contact was the reservation owner or an intruder. The same reservation context
is included in contact-filter approval requirements so policy evidence does not
hide reservation ownership or match status.
Direct ground-network filtering now uses the same ambiguity evidence when
multiple highest-priority rows overlap a candidate: unavailable and reserved
states still suppress the contact, while capacity ties with conflicting values
avoid choosing an arbitrary capacity.
Downlink candidates that already carry a matching `station_reservation_id` or
`reservation_id` for the declared provider reservation are not suppressed as
reserved intruders; they keep reservation-overlap review evidence and are marked
with `station_reservation_match_status: matched`. Candidates that do not yet
know the provider reservation ID but carry a matching `station_reserved_by` or
`reserved_by` owner are treated as owned reservation overlaps and marked with
`station_reservation_match_status: owner_matched`; non-matching overlaps remain
suppressed as `ground_station_reserved`.
`OrbitalDynamics.timeline_activity_transition/2`,
`OrbitalDynamics.timeline_status_transition/2`, and
`OrbitalDynamics.timeline_approval_transition/2` expose the same typed status
and approval transition objects used by timeline diff rows. Transition objects
include lifecycle categories, a deterministic transition category, and an
operator-review recommendation/reason so downstream adapters do not need to
guess whether an executed-status change, terminal exception, or protected
approval regression is routine. Status and approval values are trimmed and
case-normalized, with whitespace and hyphen separators folded to underscores,
before those transition/protection decisions are classified, so provider casing
or separator style does not create spurious lifecycle changes. Unsupported
status or approval values in source or replacement activities are classified as
operator-review-required `unsupported_status` or `unsupported_approval_status`
transitions instead of being treated as routine planned-status changes,
approval grants, or removals. Status or approval transitions into
`blocked_by_policy` are also classified as review-required `status_blocked` or
`approval_blocked` transitions, matching the operational timeline rows that
route policy-blocked activities to explicit resolution actions.
`OrbitalDynamics.timeline_transition_decision/3` wraps the same diff semantics
for a single proposed source/replacement activity change and returns the
artifact-only `none`, `record`, `review`, or `preserve_source` decision surface
with changed fields, required operator action, review-required flag, and
protection evidence. Timeline-identity changes are always review-required
because they alter the durable join key used by repair, review, and import
adapters.
`OrbitalDynamics.timeline_transition_application/3` adds a pure application
plan over that decision: protected source changes retain the normalized source
activity with `source_preserved_pending_review`, unchanged rows retain the
normalized source activity, record-only decisions select the normalized
replacement activity, and review-only changes omit a selected activity so
callers cannot accidentally apply an identity-changing or otherwise review-gated
replacement. The single-activity helper now reuses the same selected-activity
dependency/exclusivity integrity gate as the batch report, including the
explicit selected-dependency validation opt-out, so a preserved or unchanged
activity with missing selected dependency evidence is returned as
`selected_timeline_integrity_review_required` instead of being treated as a
silent safe selection.
`OrbitalDynamics.timeline_transition_application_report/3` applies those same
semantics across a source and replacement timeline, returning deterministic
application rows, selected safe activities, withheld-review counts, and the
source diff evidence for each row without mutating any schedule. The report is
now an executable `timeline_transition_application_report.v1` contract with a
checked-in fixture and JSON Schema export. Report-level status and transition
decision count maps are validated against the emitted application rows, selected
activities expose their normalized operational payload fields in the schema and
validator, and the selected subset is rechecked as its own artifact-only
timeline for dependency/exclusivity integrity so preserved or unchanged rows
cannot silently lose a dependency that was withheld for review. Source and
replacement protection decisions remain nested
schema-visible decision objects. Application rows now also carry the
status/approval transition maps, activity types, operator-action reason, and
duplicate timeline-identity collision evidence from the source diff row, with
report-level required-action, transition-type, and transition-category count
maps checked from the same deterministic application evidence.
`OrbitalDynamics.timeline_transition_selected_activities/1` and
`/3` expose that selected safe subset directly from an existing report or from
source/replacement activity lists, so adapters can consume the artifact-only
application result without traversing review-gated application rows or selecting
withheld replacement activities.
`OperatorReview.from_timeline_transition_application_report/2` and
`CadenceImport.from_timeline_transition_application_report/2` route the
review-required application rows through the established timeline-diff
review/import lane while preserving `application_status`, selected safe
activity evidence, transition metadata, and the source transition-application
row for adapters. When supplied, approval-policy rules can classify those
standalone transition-application review rows by transition decision,
application status, required operator action, protection category, or timeline
integrity context; the resulting rule matches and `policy_decision.v1` evidence
are preserved through the import row. The top-level
`OrbitalDynamics.operator_review_package/2` and
`OrbitalDynamics.cadence_import_manifest/2` facades dispatch the same contract.
V3 strategy branch derivation replays those standalone review/import rows back
into timeline-diff pressure while preserving `approval_rule_matches`,
`source_policy_decision`, and policy classification context on the generated
branch event.
`OrbitalDynamics.timeline_protection_decision/2` classifies locked, approved,
executed, review-required, and mutable activity states with the same
artifact-only preservation vocabulary used by repair metadata. Timeline
protection normalizes JSON-style `locked` and `approved` true flags before
classification. Unsupported `realized_status` values passed into the protection helper are now
`review_change` decisions with `unsupported_status` protection evidence rather
than mutable or preserved timeline work.
`OrbitalDynamics.normalize_timeline_activity/2` and
`OrbitalDynamics.normalize_timeline_activities/2` now share the same invalid
input preservation path, so a single malformed activity missing identity or type
becomes a reviewable `invalid_activity_input` payload instead of crashing while
batch normalization would have preserved it. The single-activity identity,
context, and protection helpers use the same path, returning synthetic invalid
timeline identity, invalid-input context, and a `review_change` protection
decision instead of raising before review/import code can inspect the handoff.
`OrbitalDynamics.timeline_link/2` also preserves malformed source or replacement
activity inputs with side-specific invalid-input metadata, so repair/import
callers can still emit a deterministic link row for operator review.
Timeline-diff rows now carry source and replacement protection-decision
evidence directly, and the same fields are preserved through operator-review
and Cadence-import rows so adapters can see whether a proposed change touches
locked, approved, executed, or otherwise mutable timeline work without
recomputing planner-local rules.
