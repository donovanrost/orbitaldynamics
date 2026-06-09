# Mission Activities

Typed mission-plan activities are the local operational activity ingress for
planner APIs. `MissionPlan.Activity.from_map!/1` accepts atom-keyed structs/maps
and JSON-style string-keyed maps, including top-level `activity_type` as an
input alias for canonical `type`, plus `start_s`/`end_s` and
`starts_at_s`/`ends_at_s` aliases, while `to_artifact_map/1` emits string-keyed
activity maps with canonical `type` for adapter and artifact boundaries. The top-level
`OrbitalDynamics.mission_plan_activity_from_map/1`,
`OrbitalDynamics.mission_plan_activity_from_map!/1`, and
`OrbitalDynamics.mission_plan_activity_to_artifact_map/1` facades expose that
normalization without mutating timelines or executing commands. Study-manifest
mission-plan activity rows accept the same `activity_type` input alias while
archiving canonical typed activities. Contact
direction strings normalize for case, whitespace, hyphen variants, and common
command/tracking/health-check aliases before validation, so provider-shaped
`cmd`, `commanding`, `s-band command`, `dl`, `downlinking`, `tracking-pass`,
or `healthcheck` handoffs enter the same
canonical direction path. Provider-shaped `planned_contact` rows with
`direction: health_check` normalize to typed `health_check` station activities
instead of remaining generic planned contacts. The module-level
`Timeline.normalize_contact_direction/1` helper is the shared contact-direction
normalizer used by planned timeline activity ingress and realized feedback
normalization, so adapters can preflight provider direction labels without
building a full report. Top-level
`mission_plan_activity_*` lifecycle facades expose the same pure approval,
lock, execution, completion, partial, failure, missed, delayed, and canceled
artifact-state helpers for callers that stay on the public API, with non-bang
aliases matching the names advertised in the capability catalog and delegating
to the same validated transitions as the existing bang helpers. Both the module
and top-level facade also expose lifecycle-event helpers that normalize
event tokens such as `record completion` or `record-partial` onto the same
validated artifact-state transitions, including provider-style lifecycle tokens
such as `completed`, `executed`, `partially executed`, `in progress`, `failed`,
`succeeded`, `aborted`, `timed out`, `skipped`, `missed`, and `cancelled`.
Typed activity artifact ingress also normalizes common provider status aliases
such as `In Progress`, `succeeded`, `partially executed`, and `timed-out`
before emitting canonical `executing`, `completed`, `partial`, or `failed`
artifact status values, and operational timeline reports reuse the same aliases
for raw map activity inputs.
Approval-state ingress follows the same pattern for provider review labels such
as `Review Required`, `under review`, `No Review Required`, and
`policy blocked`, yielding canonical `operator_review_required`,
`not_required`, or `blocked_by_policy` timeline/review routing and matching
canonical lifecycle values inside `activity_context`.
The same lifecycle status aliases are accepted by the typed `put_status!`
helpers, so API callers can update activity artifact state from provider labels
without bypassing validation.
For callers that need transition validation instead of only value
normalization, `status_transition/2` and `transition_status!/2` report whether a
status change is safe to apply automatically and block direct regressions from
terminal, executed, invalid, or policy-blocked lifecycle states without
mutating schedules or granting operator authority. Matching top-level
`mission_plan_activity_status_transition/2` and
`mission_plan_activity_transition_status!/2` facades expose the same behavior.
`approval_transition/2` and `transition_approval_status!/2` provide the matching
approval-state preflight, allowing review/escalation transitions while blocking
automatic approval grants or clearing blocked, rejected, or locked approval
states without explicit operator authority; the same behavior is exposed through
top-level `mission_plan_activity_approval_transition/2` and
`mission_plan_activity_transition_approval_status!/2` facades.
Timeline-map adapters can use `Timeline.transition_activity_status/2`,
`Timeline.transition_activity_status!/2`,
`Timeline.transition_activity_approval_status/2`, and
`Timeline.transition_activity_approval_status!/2`, plus
`Timeline.apply_lifecycle_event/2` and `Timeline.apply_lifecycle_event!/2`,
plus the matching `OrbitalDynamics.timeline_*` facades, to get normalized
timeline rows only for transitions that do not require operator review while
preserving timeline identity and activity context.
For callers that need a compact preflight over declared activity conditions,
`precondition_summary/1` reports clear, review-required, or blocked state from
explicit resource availability, degraded mode, resource-blocking dimensions,
depleted unit-interval margins, current-type suppression/incompatibility fields,
command authority/safety evidence, and `activity_template.v1` required
subsystem-state hints. Missing command authority and unchecked command safety
become review-required precondition rows, while explicit unsafe/failed command
safety becomes blocked before review/import handoff. Required subsystem states
become review-required precondition rows with subsystem/state evidence; produced
subsystem states remain template provenance only. The matching
`mission_plan_activity_precondition_summary/1` facade keeps that summary
artifact-only: it does not mutate schedules, reserve resources, execute
commands, simulate subsystem state machines, or grant operator authority.
Timeline-map adapters can use `Timeline.activity_precondition_summary/1` and
`OrbitalDynamics.timeline_activity_precondition_summary/1` for the same
clear/review-required/blocked `timeline_activity_precondition_summary.v1`
preflight without building a full operational timeline report; malformed
activity input remains review-required input evidence rather than a resource
reservation or schedule mutation. The summary contract validates its
precondition status/count fields, typed precondition rows, optional timeline
identity, dependency/exclusivity context arrays, `allow_overlap`, and
no-authority assumptions, and generated summaries pin the Timeline
`model_limits` boundary.
Those compact precondition summaries now route through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as
`timeline_activity_precondition_review` handoffs. Review/import rows preserve
the summary precondition status, counts, typed rows, dependency/exclusivity
arrays, duplicate dependency/exclusivity evidence, `allow_overlap`,
invalid-input evidence, and the source summary whether the artifact is accepted
directly or through CandidateRefresh direct/result artifact wrappers.
Operational timeline review/import handoffs also preserve row-derived
precondition status, counts, type arrays, and typed precondition rows from the
source operational timeline row; schema validation rejects stale copied
precondition values across `source_operational_timeline` and Cadence
`source_review_row` boundaries.
Operational timeline review rows also lift template-derived
`setup_duration_s`, `cooldown_duration_s`, `telemetry_confirmation_required`,
and `telemetry_confirmation_status` fields to top-level adapter metadata while
preserving the same values in the source activity context.
Existing `operational_timeline_report.v1` artifacts are accepted as idempotent
inputs by the operational timeline report facade when queues already hold the
root timeline artifact.
`Timeline.capabilities/0` publishes the same status and approval alias maps as
string-keyed values for raw timeline-map adapters, and advertises the compact
`timeline_activity_state.v1` planned/realized state facade alongside the
single-activity status, approval, and lifecycle-state handoffs.
The same capability surface now declares `candidate_rejection_report.v1`, its
canonical rejection reasons, and review actions. The report keeps candidate,
timeline, activity, source-window, rejected/not-rejected, reason-count,
reviewability, violated-constraint, margin, and activity-context fields together
for operator-facing "why rejected" explanations while staying artifact-only.
Generated reports also expose row-derived candidate ID maps by required operator
action so review queues can route `review_candidate_rejection` work without
scanning every row or granting approval/import authority.
Generated reports publish a four-item `model_limits` list that runtime
validation and schema export pin for handoff queues.
Existing `candidate_rejection_report.v1` artifacts are accepted as idempotent
inputs by the candidate-rejection report facade when queues already hold the
standalone explanation artifact.
Reduced station-capacity rejection metadata includes the same
`capacity_pack_capacity_fraction` evidence used by communications and resource
handoffs, including nested `source_station_calendar_entry` and overlap evidence
on generated candidates. Nested source-station-calendar `status` or
`availability` values of `reduced_capacity` or `degraded_capacity` derive the
same canonical `station_capacity_reduced` reason.
Typed activities preserve top-level `capacity_fraction`,
`station_capacity_fraction`, and `capacity_pack_capacity_fraction` as bounded
station-capacity evidence, so provider-authored reduced-capacity context can
round trip through `MissionPlan.Activity` and operational timeline activity
contexts without becoming a station reservation or execution authority.
Typed activities also preserve direct station-calendar identity/status context
(`station_calendar_entry_id`, `station_calendar_provider_id`,
`station_calendar_provider_entry_id`, `station_availability`,
`station_calendar_status`, and `station_calendar_trust_boundary_status`) so
provider-calendar review evidence can round trip through typed activity
handoffs without creating a reservation or granting import/execution authority.
They also preserve direct `station_calendar_directions` and nested
`source_station_calendar_entry` provenance so direction-scoped
provider-calendar routing evidence survives typed activity and operational
timeline handoffs without mutating station calendars.
Direct station reservation evidence (`station_reservation_id`,
`station_reservation_expires_at_s`, `station_reserved_by`,
`station_reservation_status`, and `station_reservation_match_status`) is
preserved the same way, so provider reservation state can round trip through
typed activities without creating, extending, approving, or importing a
reservation.
Typed activities also preserve station-calendar overlap review evidence:
`source_station_calendar_overlaps`, `station_calendar_overlap_count`,
`station_calendar_overlap_entry_ids`,
`station_calendar_overlap_availabilities`,
`station_calendar_entry_ambiguous`,
`station_calendar_ambiguous_entry_count`,
`station_calendar_ambiguous_entry_ids`, and `station_contention_status`.
This keeps provider overlap/ambiguity provenance visible to timeline
review/import handoffs without allocating capacity, creating reservations, or
resolving ambiguity automatically.
Aggregate reservation-list evidence
(`station_calendar_reservation_overlap_count`,
`station_calendar_reservation_expires_at_s`,
`station_calendar_reservation_ids`, `station_calendar_reserved_by`, and
`station_calendar_reservation_statuses`) also round trips through typed
activities as provider-calendar review context without creating, extending,
approving, or importing those reservations.
Nested source-station-calendar availability/status evidence also derives
station unavailable and reserved rejection reasons for generated candidates.
Reviewable rejected rows can now be lifted into `operator_review_package.v1`
`candidate_rejection_review` rows and `cadence_import_manifest.v1`
`review_candidate_rejection` rows without approving, selecting, or importing the
candidate.
Approval and lock helpers preserve
terminal or executed lifecycle statuses while updating approval/lock state, so
late approval or preservation actions do not erase completed, partial, executed,
missed, failed, canceled/cancelled, or rejected execution evidence. Typed activity
timeline preservation can also be preflighted for a single activity through
`Timeline.preservation_status/2` and
`OrbitalDynamics.timeline_preservation_status/2`, returning the validated
`timeline_preservation_status.v1` contract with the same
`clear`/`preservation_required`/`review_required` classification used by batch
preservation reports without schedule mutation, operator authority, or command
execution. Typed activity
artifact ingress parses clean numeric-string timing fields, impulsive-burn
`epoch_s` and `delta_v_km_s` entries, and known execution-uncertainty numeric
fields plus trimmed case-insensitive JSON-style `locked` and `allow_overlap?` booleans while leaving
malformed numeric strings or booleans invalid or opaque review metadata instead
of silently coercing them. Maneuver-review reports also gate malformed
schema-typed optional maneuver metadata such as out-of-range
`maneuver_success_factor`: invalid rows keep the review reason and source label,
but withhold the invalid canonical value from downstream `source_recommendation`
handoffs so operator-review and import artifacts stay schema-valid.
Maneuver-review reports pin their artifact-only
model-limit boundary in runtime validation and JSON Schema export, so review
handoffs cannot publish stale maneuver execution assumptions. Resource margin fields and battery state of charge are
bounded to `0.0..1.0` at typed activity construction, map ingress, executable
schema validation, and exported JSON Schema boundaries. Typed activities also
preserve non-negative `battery_energy_generated_wh` evidence through typed
`MissionPlan.Activity` ingress/egress and study-manifest loading, accepting
declared generated-energy aliases such as `energy_generated_wh`,
`estimated_energy_generated_wh`, `estimated_battery_energy_generated_wh`, and
`planned_energy_generated_wh` before review/import handoff. Typed activities also preserve explicit
`dependency_activity_ids`, `dependency_timeline_ids`,
`exclusive_with_activity_ids`, and `exclusive_with_timeline_ids` stable-ID
arrays at ingress and egress, accepting scalar or comma-delimited provider ID
strings at typed activity and raw timeline-map ingress before emitting canonical
arrays, keeping the typed activity boundary aligned with the operational
timeline integrity model. They also preserve explicit
`timeline_id`, with `persistent_id` accepted as a JSON ingress alias, so
callers no longer need to hide durable timeline identity under metadata.
Operational timeline rows and activity contexts expose the same overlap policy
as canonical `allow_overlap` booleans, and timeline diffs compare that field so
repair/review handoffs cannot silently relax or tighten schedule-overlap
constraints. Selected transition-application handoffs preserve
`selected_exclusivity_violation_group` alongside selected violation activity and
timeline IDs, so operator review and Cadence import rows keep group-level
overlap conflicts self-contained.
Typed activities preserve explicit `source_window_type` and nested
`source_window` provenance next to `source_window_id`, deriving the canonical
ID/type from provider-shaped nested windows (`id`, `window_id`, `type`, `kind`,
or `window_type`) when those top-level fields are omitted. Operational timeline
raw-map ingress applies the same source-window aliases and lifts
`metadata.source_window` into row/activity context, so typed activity round
trips do not discard provider or candidate-window evidence that operational
timeline review/import rows already understand. They also preserve explicit
`command_window_id`, `command_window_type`, and nested `command_window`
provenance, including `window_type`/nested ID aliases, so command-window review
handoffs do not have to recover this context from metadata. Typed activity and
raw timeline-map Cadence import metadata canonicalizes provider-shaped aliases
such as `id`, `import_type`, and `contract` into `external_id`,
`activity_type`, and `schema_contract` before review/import rows are emitted,
while preserving the artifact-only no-schedule-mutation boundary. They preserve canonical
resource and product identity fields (`resource_id`, `collection_id`,
`product_id`, `product_ids`, `payload_id`, and `instrument_id`), accepting the
same common JSON aliases used by operational timeline normalization. Typed
activities preserve observation priority evidence (`target_priority`,
`target_priority_source`, and objective IDs/type) plus observation-objective
context (`observation_objective_count`, `observation_objective_ids`,
`observation_objective_source`, and `observation_objective_types`) so
manifest-authored target weighting and objective routing reaches timeline review
and branch-refresh scoring. Typed activities
preserve contact, command, observation, and maneuver feedback evidence,
including result labels, success booleans, success factors, factor source
labels, feedback weights, and provider-declared observation/product quality
evidence (`image_quality_score`, `image_quality_status`,
`image_quality_source`, `cloud_cover_fraction`, and `blur_score`), so
adapter-supplied quality signals can enter timeline review without being
hidden in metadata. Typed activities preserve fixed-rate link evidence as
separate Mbps and MB/s fields (`data_rate_mbps`, `downlink_rate_mbps`,
`data_rate_mb_s`, and `downlink_rate_mb_s`) and realized telemetry aliases
(`actual_data_rate_mbps`, `actual_downlink_rate_mbps`,
`actual_data_rate_mb_s`, `actual_downlink_rate_mb_s`, delivered/received rate
aliases, and actual/contact duration aliases), so schema-valid provider rows
round trip through typed activity and timeline-context handoffs without unit
collapsing. `TimelineFeedback.normalize_realized_activity/2`,
`TimelineFeedback.normalize_realized_activities/2`, and the matching
top-level facades expose that same report-compatible realized feedback
normalization without requiring a full timeline-feedback reconciliation report.
Timeline-feedback rows also preserve planned, realized, and match-status fields
for spacecraft/payload/antenna availability, degraded-state, and mode. Completed
realized feedback with contradictory resource context is excluded from effective
operational feedback as `review_only_resource_variance` while remaining visible
in operator-review and Cadence-import variance rows.
Typed activities also preserve lighting/eclipsing evidence,
including eclipse overlap fraction/duration, lighting condition/detail/model
labels, and numeric or qualitative lighting confidence, so manifest-authored
observation constraints reach operational timeline review without being hidden
in metadata. Typed
activities also preserve artifact-only `cadence_import` metadata for downstream
adapter preflight without approving schedules or executing commands. Typed
activities preserve explicit `scenario_id` and `spacecraft_id` scope, including
provider-shaped nested `spacecraft` / `satellite` identity objects normalized
to canonical `spacecraft_id`, so typed activity round trips do not drop the
fields used by timeline identity, policy, review, and branch artifacts.
Study-manifest mission-plan activities accept and export the same explicit
scope, durable timeline identity, resource/product identity, target-priority
evidence, observation-objective context, collection-latency objective context,
feedback success evidence, observation/product quality evidence,
lighting/eclipsing context, source-window and command-window context, Cadence
import metadata, and dependency/exclusivity arrays in
`study_manifest.v1.schema.json`;
manifest-backed activities inherit the parent
mission-plan ID and spacecraft ID when those scope fields are omitted, and
conflicting child scope is rejected.
The exported manifest schema and manifest field reference expose the same
observation-quality fields plus fixed-rate and realized telemetry fields for
mission-plan activities and `candidate_refresh.operational_feedback.realized_activities`,
so manifest lint catches malformed quality and rate/duration evidence before
planner handoff.
Programmatic `MissionPlan` compilation applies the same inherited scope to
scenario metadata and rejects activities that declare a different scenario or
spacecraft scope than the parent plan.
`MissionPlan.Activity.capabilities/0` is also exposed under
`OrbitalDynamics.capability_catalog().planning.mission_plan_activity` so adapters can
discover supported activity types, status values, approval statuses, contact
directions, lifecycle helper names, top-level facade names, unit-interval
resource fields, provider-style `storage_capacity_margin`,
`downlink_capacity_margin`, and `battery_soc` unit-interval aliases, and the
artifact-only boundary. The study
manifest activity schema derives its activity type, contact direction, status,
and approval-status enums from the same capability surface. Lifecycle
status values accepted by mission-plan activities and study manifests now cover
the operational timeline vocabulary, including completed/partial execution,
missed/failed/cancelled exceptions, and approval-gated values such as
operator review, not evaluated, and blocked by policy. Lifecycle
helpers such as `approve!/1`, `reject!/1`, `lock!/1`,
`apply_lifecycle_event!/2`, `start_execution!/1`, `record_execution!/1`,
`record_completion!/1`, `record_partial!/1`, `record_failure!/1`,
`record_miss!/1`, `delay!/1`, and `cancel!/1` return validated activity copies for
artifact state transitions; they do not mutate schedules, approve external
workflow, or execute commands.
Transition-application report count maps use the same capability-published
decision, application-status, operator-action, transition-type, and
transition-category vocabularies in exported JSON Schema and executable
validation, with non-negative integer counts required before row-derived
summary checks. `Timeline.diff_summary/1`/`3` and
`OrbitalDynamics.timeline_diff_summary/1`/`3` expose compact timeline-diff
triage over `timeline_diff_report.v1`, preserving review rows, changed-field
counts, transition decision counts, review timeline ID maps by required action,
transition category, and changed field, plus no-authority assumptions without
schedule mutation. The summary is emitted as the executable
`timeline_diff_summary.v1` contract with artifact-contract validation over
review-row-derived counts and timeline ID maps. Runtime validation and JSON
Schema export pin the timeline model-limit boundary, so schema-only diff-summary
handoffs cannot accept stale model-limit lists. Existing `timeline_diff_report.v1`
artifacts are accepted as idempotent inputs by the diff-report facade when queues
already hold the standalone diff artifact. Schema-backed diff summaries can also
be promoted through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as `timeline_diff_summary.v1` handoffs,
preserving review rows and summary-level timeline ID maps.
CandidateRefresh accepts direct, accepted-state, mission-state, and
result-artifact-wrapped `timeline_diff_summary.v1` handoffs as compact
timeline-diff source provenance, preserving the summary contract, paths, and
trust boundaries without expanding the handoff into schedule mutation.
`Timeline.transition_application_summary/1`/`3` and
`OrbitalDynamics.timeline_transition_application_summary/1`/`3` expose a
compact selected/review-gated `timeline_transition_application_summary.v1`
artifact over the same report,
including selected activity IDs, selected/review/preserved/recorded/withheld
timeline ID sets, row-derived review activity IDs, review timeline ID maps by
required action and transition category, review applications, and
no-schedule-mutation assumptions.
Executable validation checks review-application-derived review counts and
timeline ID maps while preserving full-report counters as source evidence.
Those schema-backed summaries can also be promoted through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as
`timeline_transition_application_summary.v1` handoffs, preserving review
applications and summary-level selected/review activity and timeline routing.
CandidateRefresh accepts those compact transition-application summaries as
direct or result-artifact-wrapped source-report provenance, preserving the
summary contract, selected/review/preserved/withheld counts, routing maps,
source paths, and trust-boundary evidence without applying transitions or
mutating timelines.
Existing `timeline_transition_application_report.v1` artifacts are accepted as
idempotent inputs by the transition-application report facade when queues
already hold the standalone transition artifact. Both transition-application
reports and summaries pin the timeline model-limit boundary in runtime
validation and JSON Schema export, so schema-only transition handoffs cannot
accept stale model-limit lists. Transition-application reports also preserve
`transition_application_provenance` from safe status/approval helper outputs on
the selected activity context, selected activity row, application row, and
operator-review/Cadence-import handoff rows so review/import consumers can
distinguish helper-applied lifecycle state from hand-authored replacement rows
without applying transitions. Direct status, approval, and lifecycle-event
helpers can also opt into the same selected-activity dependency/exclusivity
review gate before returning helper-applied activity rows.
That selected-integrity gate lifts the same missing, self, duplicate, cycle,
order-violation, and exclusivity-overlap ID families onto transition
decision/application evidence and review/import handoff rows.
`Timeline.integrity_report/2` exposes the same
dependency/exclusivity validation as a compact validated
`timeline_integrity_report.v1` artifact-only summary with review rows,
issue-type counts, activity/timeline missing-dependency validation enabled by
default, and separate flattened self-dependency ID sets so self references are
not routed as missing dependency evidence. Duplicate dependency and exclusivity
references are routed as deterministic review evidence with deduplicated ID sets
while normalized dependency/exclusivity arrays remain canonical. The dependency
and exclusivity issue counters count individual timeline-integrity issue
records, while review-row counters remain row scoped.
Integrity summaries also expose row-derived review activity/timeline ID maps by
issue type, required operator action, and operator-action reason for adapter
queues that do not need to scan full review rows. Programmatic
`MissionPlan` validation now reuses that path before scenario compilation, so
missing `dependency_timeline_ids` fail with the same timeline-integrity issue
model as missing `dependency_activity_ids`.
The validated integrity report also routes through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as `timeline_integrity_review`
adapter rows, preserving each source integrity row plus dependency and
exclusivity issue IDs under the same schema-backed no-mutation boundary.
Explicit activity-ID exclusivity overlaps carry the conflicting timeline ID when
that row is present, and explicit timeline-ID overlaps carry the conflicting
activity ID when present, so review/import queues can route both identity forms
without mutating schedules.
Baseline activity templates are emitted as `activity_template.v1` artifacts and
instantiate through `OrbitalDynamics.activity_from_template/2` into normalized
timeline activities. Template-produced rows carry guarded `activity_template.v1`
provenance at the row level and inside reusable `activity_context`; scalar or
otherwise invalid template markers are dropped. Timeline integrity review rows
and contact-intent activity contexts preserve that provenance so adapters can
route template-sourced work without embedding the full template definition.
Baseline templates also publish typed `operational_hints` for setup duration,
cooldown duration, and telemetry-confirmation expectations. Template
instantiation copies those advisory hints into normalized timeline rows and
activity contexts without changing schedule bounds, granting authority, or
executing commands. Direct raw timeline-map activities that carry valid
`activity_template.v1` provenance derive the same row and `activity_context`
hint fields from nested `operational_hints` when explicit top-level activity
hint values are absent; explicit top-level values remain authoritative, and
malformed hint values remain out of schema-visible row/context fields.
They also publish typed `subsystem_state_hints` with required and produced
subsystem-state declarations. Template instantiation preserves those
declarations in `activity_template.v1` provenance at the row level and inside
`activity_context`; required states also feed review-required precondition rows
for mission-plan and timeline activity summaries, while produced states remain
provenance only. This keeps the handoff auditable without simulating subsystem
state machines or mutating schedules.
`Timeline.capabilities/0` publishes the normalization, identity/context,
precondition-summary, integrity, transition, single-activity protection, and
list-level lifecycle state/preservation helper names plus the candidate-rejection
report helper and matching `OrbitalDynamics` facade names for adapters that need
to discover typed activity normalization, preconditions, status, approval,
planned/realized lifecycle summaries, preservation, integrity, rejection,
decision, diff-summary, application-report, transition-summary, and
selected-activity helpers without hard-coding module internals. Its row
semantics also name the single-activity lifecycle-state transition decision and
required-action fields plus lifecycle-state summary count maps,
transition/category maps, review/record/preserve timeline ID sets, duplicate
identity routing, activity-template provenance, and invalid-input routing that
adapters can consume without scanning source rows.
`Timeline.lifecycle_state_summary/3` and
`OrbitalDynamics.timeline_lifecycle_state_summary/3` pair planned and realized
activity sets by durable timeline identity, derive row-based record/review/
preserve counts and action maps, and preserve duplicate or invalid timeline
inputs as review rows without mutating schedules, importing to Cadence, granting
operator authority, or executing commands. Those summaries publish the validated
`timeline_lifecycle_state_summary.v1` schema contract so row-derived counts,
review rows, invalid activity input IDs, identity maps, and action/category maps
remain adapter-safe while pinning the Timeline `model_limits` boundary.
Operator-review packages and Cadence-import manifests can now consume those
lifecycle-state summaries directly, preserving review timeline/activity IDs,
transition decisions, status/approval transitions, protection context, source
rows, and the no-schedule-mutation/no-import/no-operator-authority boundary as
adapter handoff evidence.
`TimelineFeedback.activity_state/3` and
`OrbitalDynamics.timeline_activity_state/3` expose a compact artifact-only
planned/realized activity-state facade over timeline feedback reconciliation,
including normalized source and realized contexts, status transition,
status category, approval status/category, approval-transition, lock/executed booleans,
protection decision, realized protection decision, match strategy, review flags,
row-derived status/match/feedback/protection count maps, realized provider and
source-quality counts, realized trust-boundary status/boundaries, model limits, and
row-level evidence without mutating schedules or executing commands. The facade
publishes the validated
`timeline_activity_state.v1` schema contract so stale row counts, stale
count maps, realized provenance summaries, review IDs, and schema-pinned
no-mutation/no-command assumptions remain
adapter-safe. Runtime validation and schema export also pin its timeline
model-limit boundary, so schema-only handoffs cannot accept stale model-limit
lists. Operator-review packages and Cadence-import manifests accept the
same compact activity-state artifact directly, preserving source activity-state
rows under `source_timeline_activity_state`, source artifact identity, and the
no-schedule-mutation/no-command-execution boundary as adapter handoff evidence.
Unmatched planned/realized pairs remain
visible as review-required state rows instead of being collapsed into a single
arbitrary activity.
For callers that only need status normalization without full feedback
reconciliation, `Timeline.activity_status_state/2` and
`OrbitalDynamics.timeline_activity_status_state/2` normalize common planned and
realized status aliases into the validated
`timeline_activity_status_state.v1` contract, preserve activity/timeline
identity and context, and emit deterministic transition decision, review,
operator-action, and import action fields without changing planner selection
behavior.
`Timeline.activity_approval_state/2` and
`OrbitalDynamics.timeline_activity_approval_state/2` provide the same compact
handoff for planned/realized approval states through
`timeline_activity_approval_state.v1`, preserving review, protected, blocked,
and rejected approval routing while keeping the artifact-only
no-schedule-mutation and no-operator-authority boundary.
`Timeline.activity_lifecycle_state/2` and
`OrbitalDynamics.timeline_activity_lifecycle_state/2` combine those status and
approval handoffs with lock, executed, and protection evidence into one compact
validated `timeline_activity_lifecycle_state.v1` artifact-only lifecycle state
for adapters that need a single review/import preflight without mutating
schedules, granting operator authority, importing to Cadence, or executing
commands.
The exported schemas for the single-activity status, approval, and lifecycle
state handoffs pin the same no-authority assumption flags that runtime
validation enforces, including the lifecycle state's no-Cadence-import boundary.
The single-activity status, approval, and lifecycle-state artifacts also route
through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1`, preserving their activity/timeline
identity, transition decisions, source state, and review-required versus
ready-for-import boundary as adapter evidence only.
CandidateRefresh also preserves single-activity lifecycle states through
`CandidateRefresh.timeline_activity_lifecycle_state_replay_summary/1` and the
matching `OrbitalDynamics` facade as artifact-only replay provenance without
applying lifecycle transitions or granting import authority. That replay path
also carries lifecycle helper provenance counts from source
`transition_application_provenance` evidence when branch-local activity
lifecycle states were derived from helper-applied transitions.
List-level `CandidateRefresh.timeline_lifecycle_state_replay_summary/1` carries
the same helper provenance counters from lifecycle summary rows while preserving
row-derived review, recordable, and preservation routing.
For V3 strategy branch refreshes, that replay helper prefers a non-empty
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_activity_lifecycle_state`
family over provenance, labels its output source and replay scope as
candidate-source summary metadata, and treats partial non-empty branch families
as authoritative while keeping provenance fallback for absent or empty branch
families.
The separate status-only and approval-only state handoffs have matching
CandidateRefresh replay summaries through
`CandidateRefresh.timeline_activity_status_state_replay_summary/1`,
`CandidateRefresh.timeline_activity_approval_state_replay_summary/1`, and their
top-level `OrbitalDynamics` facades. These summaries keep paths,
model/schema counts, transition decisions, operator/import actions,
activity/timeline routing, and trust-boundary evidence scoped to the individual
`timeline_activity_status_state.v1` or `timeline_activity_approval_state.v1`
contract without applying status or approval changes.
`CandidateRefresh.timeline_activity_state_replay_summary/1` and its matching
top-level `OrbitalDynamics` facade prefer a non-empty V3
`candidate_source.candidate_refresh_request_source_report_summary.source_reports.timeline_activity_state`
family over provenance, label their output source and replay scope as
candidate-source summary metadata, and treat partial non-empty branch families
as authoritative while keeping provenance fallback for absent or empty branch
families.
`Timeline.preservation_report/2` and
`OrbitalDynamics.timeline_preservation_report/2` expose a compact artifact-only
`timeline_preservation_report.v1` summary over selected activities that reuses
`protection_decision/2` rows for locked, approved, executed, or invalid
activities, returning preservation and review counts plus activity/timeline ID
maps by protection decision, category, and reason without mutating schedules,
approving work, or executing commands.
Both batch preservation reports and single-activity
`timeline_preservation_status.v1` artifacts can be routed through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as `timeline_preservation_review`
adapter rows, keeping preservation-required evidence ready to record while
leaving invalid or review-change evidence review-required before import.
Their exported schemas pin the same execution-boundary and scope assumptions
that runtime validation enforces for report and status handoffs.
CandidateRefresh also exposes those preservation handoffs through
`CandidateRefresh.timeline_preservation_replay_summary/1` and the matching
`OrbitalDynamics` facade. The replay summary preserves source paths,
report/status contract counts, preservation and review status/action maps,
protection decision/category routing, activity/timeline ID routing, and the
no-schedule-mutation/no-authority boundary without applying preservation
decisions.
Single-activity transition
decisions now reuse the selected-activity dependency integrity gate, so an
unchanged row with missing dependencies returns `review_timeline_integrity`
unless selected dependency validation is explicitly disabled. Selected activity
and selected application timeline-integrity issue counters also reject negative
values before transition-application reports are accepted.
`Timeline.dependency_impact_summary/3` and
`OrbitalDynamics.timeline_dependency_impact_summary/3` expose a compact
schema-backed `timeline_dependency_impact_summary.v1` dependency-impact view over
source/replacement timelines, listing source and replacement activities whose
dependencies or explicit exclusivity links still point at changed or removed
source timeline identities, with row-derived dependent activity/timeline ID sets
by source/replacement scope and impacted dependency/exclusivity ID sets
advertised by `Timeline.capabilities/0`. Executable validation rejects stale
row-derived dependent counts or dependency/exclusivity ID sets without mutating
schedules or granting operator authority. Runtime validation and JSON Schema
export also pin its timeline model-limit boundary, so schema-only dependency
impact handoffs cannot accept stale model-limit lists. The summary can also be
routed into `operator_review_package.v1` and `cadence_import_manifest.v1`
handoff rows that preserve source/replacement scope, scoped dependent IDs, and
impacted dependency/exclusivity IDs while leaving any schedule mutation to
downstream review. The generic `OrbitalDynamics.operator_review_package/1` facade
accepts the same dependency-impact summary artifacts, including schema-contract
and model-only inputs.
`Timeline.publication_summary/2` and
`OrbitalDynamics.timeline_publication_summary/2` expose
`timeline_publication_summary.v1` as an artifact-only publication metadata
handoff. It preserves deterministic publication ID/sequence, source artifact
identity/type, superseded artifact IDs, downstream product IDs, invalidated
downstream product IDs, an explicit downstream invalidation status, reason
counts plus reason-keyed downstream product ID routing, optional
dependency-impact status, nested dependency-impact source evidence,
changed-source/dependent activity and timeline ID sets, and impacted
dependency/exclusivity ID sets,
optional nested `timeline_diff_summary.v1` changed-field audit evidence,
row/changed/review diff counts, changed-field counts, changed/review timeline
IDs, changed-field timeline routing, publication authority, host-owned
notification delivery assumptions, and the same timeline model-limit boundary in
runtime validation and JSON Schema export. Executable validation rejects stale
copied audit projections that no longer match the nested dependency-impact or
diff summaries. The summary does not mutate schedules, deliver notifications,
approve imports, or grant operator authority.
Publication summaries can now route through
`OperatorReview.from_timeline_publication_summary/1`,
`CadenceImport.from_timeline_publication_summary/2`, and the matching public
facades as `timeline_publication_review` / `review_timeline_publication`
handoff rows. Those rows preserve publication identity, sequence, status,
explicit downstream invalidation status, authority, supersession, downstream
invalidation reasons, dependency-impact changed-source/dependent ID sets and rollups,
changed-field audit counts and routing, and the nested source publication
summary while leaving publication execution, notification delivery, and import
authorization to downstream operators or host systems.
Operational-readiness and quality-gate summaries preserve that same publication
context when classifying direct publication summaries, their review packages, or
Cadence-import manifests. The context explains review-only routing with
publication status, downstream invalidations, dependency-impact IDs/counts, and
changed-field review counts, but remains artifact-only and does not publish,
notify, import, mutate schedules, or grant operator authority.
CandidateRefresh publication replay now preserves the same publication summary
evidence through `CandidateRefresh.timeline_publication_replay_summary/1` and
`OrbitalDynamics.candidate_refresh_timeline_publication_replay_summary/1`.
Replay accepts direct publication summaries, result-artifact wrapped summaries,
and review/import handoff rows, including row-only handoffs where embedded
publication summaries have been stripped, then emits artifact-only branch-local
publication, dependency source/dependent ID sets, changed-field, invalidation,
invalidation reason, and review pressure without publishing, notifying, importing, mutating
schedules, or granting authority.
Operational-timeline report activity/row/contact/command/protection/execution
totals and optional dependency, exclusivity, uncertainty, integrity, duplicate,
valid, invalid, and terminal-exception counters are non-negative integers in
both exported JSON Schema and executable validation before row-derived summaries
are accepted. Timeline-integrity reports also pin the same timeline model-limit
boundary in runtime validation and JSON Schema export, so schema-only integrity
handoffs cannot accept stale model-limit lists.
Operational-timeline row-level `timeline_integrity_issue_count` values use the
same non-negative integer executable contract as the exported row schema.
Timeline-diff report source/replacement/row/status/review counters are likewise
non-negative integers in exported JSON Schema and executable validation, so
artifact producers cannot publish float-shaped or negative diff totals.
Timeline-diff and transition-application duplicate timeline-identity activity
counters are also non-negative integers at the row boundary, keeping duplicate
collision evidence consistent before review/import handoff.
Timeline-diff and transition-application rows preserve self-dependency activity
and timeline IDs separately from missing-dependency IDs when integrity review
blocks a source/replacement row.
Operator-review and Cadence-import handoff rows retain those source,
replacement, and selected self-dependency evidence fields from timeline diff and
transition-application artifacts, so adapter routing does not collapse self
references into missing-dependency evidence.
Timeline-feedback report planned/realized/row counters and optional
reconciliation counters for uncertainty, operational-feedback exclusion,
ambiguous timeline matching, and duplicate realized matches are non-negative
integers in both exported JSON Schema and executable validation. Timeline
feedback reports also pin their feedback-specific model-limit boundary in
runtime validation and JSON Schema export, so schema-only feedback handoffs
cannot accept stale model-limit lists.
Timeline-feedback thermal zone, temperature, operating-bound, margin,
status/model/source, and confidence evidence is preserved on operator-review
and Cadence-import realized-feedback handoff rows, so adapter queues can route
thermal variance without reopening nested activity contexts.
Timeline-feedback command authority and command-safety evidence is likewise
preserved as artifact-only handoff context, including planned and realized
authority/safety statuses, required authority, authorization and safety-check
booleans, and row-level match statuses without granting authority, signing,
uplinking, or executing commands.
Operational-timeline review/import handoff rows also preserve artifact-only
command authority and command-safety context from the planned timeline row,
including authority/safety status, required authority, authorization, and
safety-check fields, without granting authority, signing, uplinking, importing,
mutating schedules, or executing commands.
Operational-timeline review/import handoff rows preserve the same top-level
thermal evidence from operational timeline rows and activity contexts.
Operational-timeline review/import handoff rows also preserve top-level
pointing and attitude evidence from timeline rows and activity contexts,
including modes, targets, angles, errors, status/model/source, and confidence.
Operational-timeline review/import handoff rows also preserve link-profile and
link-quality evidence, including protocol, band, modulation/coding,
polarization, planned and actual rates/durations, margin/SNR metrics, lock
states, and quality status.
Operational-timeline review/import handoff rows also preserve observation
quality scores/status/source, cloud/blur evidence, feedback weights, and
maneuver success/result evidence at top level.
The supported activity type surface includes first-class `attitude` rows, so
declared pointing holds can be represented directly instead of being inferred
only from `slew` or observation context.
