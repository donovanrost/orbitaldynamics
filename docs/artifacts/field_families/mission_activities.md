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
instead of remaining generic planned contacts. Top-level
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
For callers that need a compact preflight over declared activity conditions,
`precondition_summary/1` reports clear, review-required, or blocked state from
explicit resource availability, degraded mode, resource-blocking dimensions,
depleted unit-interval margins, and current-type suppression/incompatibility
fields. The matching `mission_plan_activity_precondition_summary/1` facade keeps
that summary artifact-only: it does not mutate schedules, reserve resources,
execute commands, or grant operator authority.
Timeline-map adapters can use `Timeline.activity_precondition_summary/1` and
`OrbitalDynamics.timeline_activity_precondition_summary/1` for the same
clear/review-required/blocked `timeline_activity_precondition_summary.v1`
preflight without building a full operational timeline report; malformed
activity input remains review-required input evidence rather than a resource
reservation or schedule mutation. The summary contract validates its
precondition status/count fields, typed precondition rows, optional timeline
identity, dependency/exclusivity context arrays, `allow_overlap`, and
no-authority assumptions.
Those compact precondition summaries now route through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1` as
`timeline_activity_precondition_review` handoffs. Review/import rows preserve
the summary precondition status, counts, typed rows, dependency/exclusivity
arrays, `allow_overlap`, invalid-input evidence, and the source summary whether
the artifact is accepted directly or through CandidateRefresh direct/result
artifact wrappers.
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
of silently coercing them. Maneuver-review reports pin their artifact-only
model-limit boundary in runtime validation and JSON Schema export, so review
handoffs cannot publish stale maneuver execution assumptions. Resource margin fields and battery state of charge are
bounded to `0.0..1.0` at typed activity construction, map ingress, executable
schema validation, and exported JSON Schema boundaries. Typed activities also preserve explicit
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
constraints.
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
`target_priority_source`, and objective IDs/type) so manifest-authored target
weighting reaches timeline review and branch-refresh scoring. Typed activities
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
evidence, feedback success evidence, observation/product quality evidence,
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
accept stale model-limit lists.
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
`Timeline.capabilities/0` publishes the normalization, identity/context,
precondition-summary, integrity, transition, single-activity protection, and
list-level lifecycle state/preservation helper names plus the candidate-rejection
report helper and matching `OrbitalDynamics` facade names for adapters that need
to discover typed activity normalization, preconditions, status, approval,
planned/realized lifecycle summaries, preservation, integrity, rejection,
decision, diff-summary, application-report, transition-summary, and
selected-activity helpers without hard-coding module internals.
`Timeline.lifecycle_state_summary/3` and
`OrbitalDynamics.timeline_lifecycle_state_summary/3` pair planned and realized
activity sets by durable timeline identity, derive row-based record/review/
preserve counts and action maps, and preserve duplicate or invalid timeline
inputs as review rows without mutating schedules, importing to Cadence, granting
operator authority, or executing commands. Those summaries publish the validated
`timeline_lifecycle_state_summary.v1` schema contract so row-derived counts,
review rows, invalid activity input IDs, identity maps, and action/category maps
remain adapter-safe.
Operator-review packages and Cadence-import manifests can now consume those
lifecycle-state summaries directly, preserving review timeline/activity IDs,
transition decisions, status/approval transitions, protection context, source
rows, and the no-schedule-mutation/no-import/no-operator-authority boundary as
adapter handoff evidence.
`TimelineFeedback.activity_state/3` and
`OrbitalDynamics.timeline_activity_state/3` expose a compact artifact-only
planned/realized activity-state facade over timeline feedback reconciliation,
including normalized source and realized contexts, status transition,
protection decision, match strategy, review flags, row-derived status/match/
feedback/protection count maps, model limits, and row-level evidence without
mutating schedules or executing commands. The facade publishes the validated
`timeline_activity_state.v1` schema contract so stale row counts, stale
count maps, review IDs, and explicit no-mutation/no-command assumptions remain
adapter-safe. Runtime validation and schema export also pin its timeline
model-limit boundary, so schema-only handoffs cannot accept stale model-limit
lists. Operator-review packages and Cadence-import manifests accept the
same compact activity-state artifact directly, preserving source activity-state
rows, source artifact identity, and the no-schedule-mutation/no-command-execution
boundary as adapter handoff evidence. Unmatched planned/realized pairs remain
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
The single-activity status, approval, and lifecycle-state artifacts also route
through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/1`, preserving their activity/timeline
identity, transition decisions, source state, and review-required versus
ready-for-import boundary as adapter evidence only.
CandidateRefresh also preserves single-activity lifecycle states through
`CandidateRefresh.timeline_activity_lifecycle_state_replay_summary/1` and the
matching `OrbitalDynamics` facade as artifact-only replay provenance without
applying lifecycle transitions or granting import authority.
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
