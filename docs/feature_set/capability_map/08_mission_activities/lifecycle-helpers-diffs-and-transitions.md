# Lifecycle Helpers, Timeline Diffs, and Transitions

## Lifecycle helpers and facades

`MissionPlan.Activity` exposes pure lifecycle helpers for the executing,
completed, partial, failed, missed, delayed, executed, canceled, approved,
rejected, and locked artifact states.

- Matching top-level `OrbitalDynamics` facades and normalized lifecycle-event
  application helpers let callers model operational timeline transitions
  without ad hoc status writes or external workflow mutation.

## Unit-interval fields and aliases

Typed activity constructors, map ingress, executable validation, and the
exported JSON Schema now agree that resource margins and battery state of charge
are unit-interval fields. This prevents Cadence import contexts from preserving
schema-invalid margin values.

- **Standalone operational timeline normalization** applies the same
  invalid-input review gate to out-of-range unit-interval activity context
  values such as resource margins, battery state of charge, quality fractions,
  and command/contact/observation/maneuver success factors, instead of emitting
  schema-invalid timeline rows.
- **Margin aliases** — `storage_capacity_margin` is accepted as an alias for
  `storage_margin`, where map inputs already accept `downlink_capacity_margin`
  and `battery_soc`.
- `Timeline.capabilities/0` exposes the validated unit-interval field aliases as
  row semantics.

## Execution uncertainty metadata

Declared `execution_uncertainty` maps are preserved with derived timing and
delta-v 3-sigma fields, while maneuver rows missing that metadata are counted
explicitly. The same artifact-only metadata flows into operator-review and
Cadence-import rows.

## Activity-context, timeline-link, and transition helpers

The module also exposes public activity-context, timeline-link, and typed
status/approval transition helpers.

- **Reusable context** includes normalized dependency and exclusivity stable-ID
  arrays, plus timing, target, station availability, and schedule-conflict
  context, plus top-level or metadata-supplied command/contact feedback evidence.
- The capability catalog advertises the top-level `timeline_link` facade next
  to identity/context helpers, so adapter consumers can discover the
  source-to-replacement join-key handoff without inferring it from diff rows.
- **Raw timeline lifecycle events** use the same provider lifecycle-event
  aliases as typed mission-plan activities, then validate the resulting status
  and approval transitions before returning normalized timeline rows with
  transition provenance; transition-application review/import rows keep that
  provenance first-class even when selected timeline integrity requires review,
  and CandidateRefresh lifecycle-state replay summarizes helper provenance
  counts for branch-local refresh decisions.
- **Timeline precondition summaries** expose the same clear, review-required,
  and blocked activity-condition classification used by operational timeline
  rows, without building a report, reserving resources, mutating schedules, or
  granting operator authority. Command authority and safety evidence is part of
  that preflight: missing authority or unchecked safety requires review, and
  explicitly unsafe/failed safety blocks handoff.
- **Status/approval-transition review semantics** route unsupported provider
  lifecycle values to operator review instead of treating them as routine
  planned-status changes or approval grants/removals.
- **Protection-decision helpers** for lock/approved/executed also review-gate
  unsupported realized status values. They are used by repair/approval artifacts
  instead of planner-local timeline identity and preservation shaping.
- **Lifecycle-state review/import handoffs** preserve review-required summary
  rows with status and approval transition evidence, protection context, source
  lifecycle rows, and timeline identity without importing to Cadence or mutating
  schedules.

## Row-derived summary surface

A row-derived summary surface covers operational activity status, approval
status, required operator action, Cadence import status, and operational kind
counts.

- It is validated against the report rows and exported as canonical enum-keyed
  non-negative count maps.
- Required top-level operational timeline counters and optional summary counters
  are exported and executable-validated as non-negative integers.
- `Timeline.capabilities/0` advertises those operational summary/count semantics
  for catalog consumers.
- Row-level `timeline_integrity_issue_count` values follow the same non-negative
  integer executable contract as the exported row schema.
- Report-level `model_limits` runtime validation and JSON Schema exports pin
  the exact list from `OrbitalDynamics.Timeline.model_limits/0`.

## Timeline diff report

A schema-validated `timeline_diff_report.v1` builder and the
`OrbitalDynamics.timeline_diff_report/3` facade compare source and replacement
activities by timeline identity.
Existing `timeline_diff_report.v1` artifacts are accepted as idempotent inputs
by the diff-report facade, so repair or import queues that already hold the
standalone diff artifact can reuse it without reopening source and replacement
timelines.

- Comparison includes typed status and approval-transition objects plus
  dependency/exclusivity stable-ID arrays.
- `Timeline.capabilities/0` advertises the top-level
  `timeline_diff_report` facade alongside the diff helper metadata.
- `Timeline.capabilities/0` advertises the core and activity-context compare
  fields that drive `changed_fields` and `changed_field_counts`.
- Non-negative bounds apply to transition/diff scalar counters and duplicate
  timeline-identity counters.
- Report-level `model_limits` runtime validation and JSON Schema exports pin
  the exact list from `OrbitalDynamics.Timeline.model_limits/0`.

### Diff summary triage surface

`Timeline.diff_summary/1`/`3` and `OrbitalDynamics.timeline_diff_summary/1`/`3`
emit `timeline_diff_summary.v1`, a compact artifact-only triage surface over
`timeline_diff_report.v1`.

- They preserve review-required diff rows, changed-field counts, transition
  decision counts, and review timeline ID maps by required action, transition
  category, and changed field.
- Lifecycle-state summaries also preserve row-derived operator-action reason
  counts and review timeline ID maps by operator-action reason, so compact
  handoffs can route approval grants, recorded executions, duplicate timeline
  identities, and invalid inputs without reopening every lifecycle row. The
  same summary-level reason maps are flattened into lifecycle-state
  operator-review and Cadence-import rows for adapter routing.
- Executable validation checks review-row-derived review counts and timeline ID
  maps while preserving the full-report count fields as source evidence.
- Runtime validation and JSON Schema export pin the same timeline model-limit
  list as the full diff report, so schema-only summaries cannot accept stale
  model-limit lists.
- Existing `timeline_diff_summary.v1` artifacts are accepted as idempotent
  inputs by the diff-summary facade when downstream queues already hold the
  compact summary artifact.
- CandidateRefresh replays direct, accepted-state, mission-state, and
  result-artifact-wrapped summaries through timeline-diff source provenance,
  preserving the compact contract, source paths, aggregate maps, and trust
  boundaries.
- This happens without schedule mutation or operator authority, and the
  schema-backed summary routes through operator-review and Cadence import
  handoffs.

## Single-activity and batch transition application

The reusable single-activity transition application helper now runs the same
selected-activity dependency/exclusivity integrity gate as the batch
transition-application report, including the existing explicit opt-out for
selected dependency validation.
Existing `timeline_transition_application_report.v1` artifacts are accepted as
idempotent inputs by the transition-application report facade, so repair or
import queues that already hold the standalone transition artifact can reuse it
without reopening source and replacement timelines.

- Preserved or unchanged rows exposed through the small API cannot bypass review
  when their selected timeline subset is missing required dependency evidence.
- The matching transition-decision helper also returns
  `review_timeline_integrity` for those single-activity unchanged rows, unless
  selected dependency validation is explicitly disabled.
- Runtime validation and JSON Schema export pin the timeline model-limit list on
  transition-application reports, so schema-only handoffs cannot accept stale
  model-limit lists.

### Immutable revision identity and pure replay

`Timeline.transition_application_report/3` and its top-level facade preserve
their existing output unless `timeline_revision?: true` is explicitly supplied.
With that option, the report and each application row carry the same optional
`timeline_revision.v1` evidence:

- `prior_revision_id` is derived from canonically ordered normalized source
  activities;
- `transition_batch_id` is derived from the canonical transition-application
  rows; and
- `replacement_revision_id` is derived from the canonically ordered selected
  replacement activities.

All three identities use canonical JSON plus SHA-256 and are independent of
wall-clock time and source list order for equivalently identified activities.
Transition-application summaries preserve the same evidence when present.
Executable validation and JSON Schema source export type the identity scheme,
canonicalization version, content-ID formats, and report/row copy consistency.

`Timeline.replay_transition_application_report/4` and
`OrbitalDynamics.timeline_replay_transition_application_report/4` are pure
replay boundaries. Given the prior report plus source and replacement activity
lists, they rebuild the transition report with revision evidence and return:

- `{:ok, report}` when the named prior revision, transition batch, and
  replacement revision reproduce;
- `revision_conflict` evidence with `prior_revision` scope before applying a
  batch to different prior content;
- `batch_conflict` evidence when replacement/transition content no longer
  matches the named batch; or
- `invalid_replay_evidence` for missing or malformed identity evidence.

This is artifact-local idempotence only. It does not persist revisions, acquire
locks, coordinate concurrent writers, invoke planner defaults, mutate a
schedule, start an approval/import workflow, or claim distributed concurrency
safety.

### Duplicate timeline-identity preservation

Timeline-transition application rows now also preserve duplicate
timeline-identity collision scope, counts, activity IDs, and normalized source
rows at top level before operator-review and Cadence-import handoff. Transition
application consumers do not have to reopen nested diff evidence to route
duplicate timeline IDs.

### Compact transition-application summaries

Compact transition-application summaries emit
`timeline_transition_application_summary.v1` artifacts exposing:

- selected activity IDs,
- review-gated applications,
- transition decision counts,
- review timeline ID maps by required action and transition category, and
- selected-subset integrity counts,

without schedule mutation or operator authority. Executable validation checks
review-application-derived review counts and timeline ID maps, and the
schema-backed summary routes through operator-review and Cadence import
handoffs. Runtime validation and JSON Schema export pin the same timeline
model-limit list for compact summaries. CandidateRefresh also accepts direct and
result-artifact-wrapped transition-application summaries as source-report
provenance, preserving the compact summary contract,
selected/review/preserved/withheld counts, selected-subset integrity review and
issue counts, selected-integrity issue-type counts, routing maps, source paths,
and trust-boundary evidence without applying transitions or mutating timelines.
Existing `timeline_transition_application_summary.v1` artifacts are accepted as
idempotent inputs by the transition-application-summary facade when downstream
queues already hold the compact summary artifact.

### Self-dependency evidence

Diff and transition-application rows also preserve self-dependency evidence
separately from missing dependency evidence when integrity review blocks a
source/replacement row.

## Malformed input handling

Single-activity and batch timeline normalization now share the same invalid
activity preservation path, so malformed activity handoffs missing identity or
type become reviewable typed payloads instead of crashing in the single-row API.

- Single-activity identity, context, and protection helpers also preserve
  malformed handoffs as synthetic invalid timeline identity, invalid-input
  context, and `review_change` protection decisions.
- Timeline-link helpers carry side-specific invalid-input metadata for malformed
  source or replacement activities instead of failing before review/import
  handoff.

## Diff rows: collisions, review actions, and context

- **Duplicate identities** — duplicate source or replacement timeline identities
  are retained as review-required collision rows with duplicate activity IDs and
  normalized source/replacement activity evidence, instead of being overwritten
  during the identity match.
- **Specific review actions** — changed or removed executed, locked, or approved
  source activities now carry specific timeline-diff review actions instead of
  generic timeline-change or removed-activity labels.
- **Preserved context** — added, removed, and changed diff rows now carry
  source/replacement activity context where present, so operator-review and
  Cadence-import rows retain timeline identity, source/replacement spacecraft,
  ground-station, target, and source-window identity, dependency, exclusivity,
  timing, target, and station evidence without rebuilding it from the full
  activity payload.
- **Malformed inputs** — timeline-diff reports also preserve malformed source or
  replacement inputs missing stable activity identity, carrying malformed
  activity IDs, or missing activity type, as side-specific
  `review_invalid_activity_input` rows with invalid-input counts, schema-stable
  synthetic review IDs, and original input evidence, instead of crashing or
  letting malformed rows participate as ordinary activity matches.

## Diff reasons, transition decisions, and count maps

- Review/import rows expose the concrete diff reason as `operator_action_reason`,
  matching the rest of the Cadence-facing review surfaces.
- Timeline-diff reports expose row-derived diff-status, required-action,
  changed-field, status-transition, and approval-transition count maps that are
  validated against the rows and exported as non-negative JSON Schema count maps,
  with canonical enum keys for diff status, operator action, transition decision,
  transition type, and transition category.
- Required top-level source/replacement/row/status/review counters are also
  exported and executable-validated as non-negative integers.
- Diff rows expose deterministic `transition_decision` and
  `transition_decision_reason` values with row-derived `transition_decision_counts`.
- Operator-review/Cadence validation fixtures now check row-derived transition
  application status, decision, action, status-transition, approval-transition,
  and application ID routing maps before downstream review/import handoff
  consumes the report. Import rows preserve those fields so the artifact doubles
  as an explicit transition plan.

## Reviewable diff fields (advisory, not schedule-enforced)

- **Dependency / exclusivity** — dependency or exclusivity changes are reviewable
  timeline-diff fields but are not schedule-enforced by OrbitalDynamics.
- **Dependency cycles** — timeline-diff source and replacement inputs now also
  reuse the typed activity integrity checks, so unchanged rows with dependency
  cycles are promoted to `review_timeline_integrity` diff rows, and flattened
  source/replacement cycle IDs are preserved through operator-review/Cadence-import
  handoffs.
- **Command/contact execution evidence** — changes, including `command_success`,
  `command_result`, and feedback confidence factors, are also reviewable
  timeline-diff fields and preserve source/replacement context through
  review/import rows.
- **Throughput and data-volume evidence** — planned-versus-actual throughput and
  data-volume evidence changes are also reviewable timeline-diff fields,
  including provider data-volume requirement, selected/planned volume,
  delivered/received volume, and shortfall aliases, so delivery shortfalls are
  preserved as reviewable changes instead of unchanged rows.
- **Station-calendar trust/source evidence** — changes, including trust-boundary
  status, trust boundary, provenance, applied provider-calendar row, and overlap
  provider rows, are also reviewable timeline-diff fields instead of being buried
  in activity context.
- **Resource-assignment changes** — also reviewable timeline-diff fields; they
  preserve source/replacement `resource_id` context for review/import handoffs.
- **`execution_uncertainty` map changes** — also reviewable timeline-diff fields,
  preserving source/replacement uncertainty context without implying finite-burn
  execution.
- **Maneuver success confidence fields** — preserved in operational activity
  context and reviewable timeline-diff fields when they change.

## Operator-review package normalization

Timeline diff reports can be normalized into `operator_review_package.v1`
`timeline_diff_review` rows for added, removed, or changed timeline identities
that require operator review.

- These rows preserve those transition objects and typed source/replacement
  protection-decision payloads.
- Exported nested JSON Schema and executable validation cover transition
  type/category/review flags plus protection identity, lock, approval, category,
  and reason fields.

### Plan-delta replay

Prior `plan_delta_review` rows and Cadence `review_plan_delta` import rows for
canceled or suppressed source work replay into the same V3 branch-local
removed-timeline pressure path as timeline-diff rows.

- They preserve source activity context, timeline identity, required action,
  source path, and review/import trust boundary, without treating preserved
  items as pressure.

## Source-evidence objects

Review/import `source_*` snapshots are now treated as source-evidence objects
rather than complete nested artifacts. Partial fixture rows and adapter evidence
remain preservable.

- Stable-ID-bearing fields such as `activity_id`, `timeline_id`,
  `ground_station_id`, `maneuver_id`, `station_calendar_entry_id`, provider IDs,
  and `diff_status` are still schema-visible and executable-validated.
- Preserved `source_policy_decision` uses a policy-evidence schema that allows
  partial source decisions while checking `policy_bundle_id`, optional
  classification, escalations, and model limits.
- `source_policy_escalation` continues to validate routing evidence.
- Cadence import rows plus embedded `source_review_row` copies apply the same
  lightweight source-evidence validators, so adapter handoffs preserve source
  context without falsely requiring every embedded snapshot to satisfy its
  standalone artifact contract.

## Permissive nested activity-context shape

Exported schemas now use the same permissive nested activity-context shape for
approval requirements, plan deltas, operator-review rows, and Cadence import
rows, so dependency/exclusivity stable-ID arrays and nested `timeline_identity`
objects are machine-visible.

- Exported schema and executable validation cover nested timeline identity,
  timeline-link, and timeline-protection stable-ID/count fields without blocking
  adapter-specific context keys.
- Generic Cadence import rows preserve activity context plus source/replacement
  timeline identities from operator-review rows, so review-only adapter handoffs
  retain dependency, self-dependency, and exclusivity evidence.

## Top-level transition helpers and classification

Top-level public helpers expose durable timeline identity, activity context,
source/replacement links, combined status/approval transitions, and the
individual typed status or approval transition objects used by timeline diff
rows.

- Those transition objects now classify lifecycle categories, deterministic
  transition categories, and operator-review recommendation reasons for
  executed-status changes, terminal exceptions, protected approval regressions,
  and status or approval transitions into `blocked_by_policy`.
- They include row-derived transition-category count maps, the same nested shape
  exported in JSON Schema, and executable validation of transition fields,
  transition types, review flags, and status-vs-approval field alignment across
  timeline-diff, operator-review, Cadence-import, and realized-feedback rows.

## Duplicate row ID and counter validation

- Executable validation now rejects duplicate row IDs in standalone
  operational-timeline, timeline-diff, command-window, branch-comparison,
  contact-allocation, maneuver-review, objective-satisfaction, Pareto-frontier,
  and score-term reports, matching the row-identity guarantees already used by
  operator-review and Cadence-import artifacts.
- Duplicate timeline-identity activity counters on timeline-diff and
  transition-application rows are exported and executable-validated as
  non-negative integers before those rows reach review/import handoff.

## V1 campaign artifact emission

V1 campaign artifacts emit those report rows to expose:

- selected activity status, approval state, lock state, contact/command
  classification, required operator action, operator-action reason, and
  execution boundary;
- Cadence import status plus adapter external ID/contract when declared;
- station availability, and station-calendar entry/overlap/reservation context,
  including reservation identity, owner/status, and
  `station_reservation_match_status`;
- schedule-conflict status, dependency/exclusivity metadata, source-window
  lineage, and derived timeline identity.

Timeline diffs now treat changed station-calendar reservation identity,
reservation-match context, and provider-calendar identity as review-significant.
Typed timeline protection treats `auto_approvable` activities as protected
approved work, matching timeline-diff review semantics.

## Standalone operational timeline normalization (inputs and inference)

Standalone operational timeline normalization accepts top-level `activity_type`
as an input alias for `type`, preserving exported or provider-shaped timeline
rows as typed activities without requiring an adapter rewrite.

- It flattens singular provider-shaped `target`, `station`, and `ground_station`
  objects into canonical `target_id` / `ground_station_id` before timeline
  identity, activity context, and contact inference.
- The first-class typed activity model also preserves provider data-volume
  requirement, selected/planned volume, delivered/received volume, shortfall, and
  downlink-completion source aliases before timeline/report handoff.

### Contact and activity-type inference

- Provider-shaped `contact` activities now participate in operational timeline
  identity/contact classification when they carry station context.
- Provider-shaped station/time rows without explicit type or direction infer
  canonical downlink timeline rows.
- Direction-only command/uplink/tracking station windows normalize as planned
  contacts.
- Direction-only health-check station windows normalize as health-check
  activities.
- Command-result shaped rows without command type/direction remain invalid review
  inputs.
- `CommandWindow.capabilities/0` advertises the command-window activity-type
  classifier used by report rows.
- Contact-shaped command, uplink, and tracking activities can be lifted into
  artifact-only `contact_intent.v1` rows with direction, Cadence import metadata,
  and timeline identity lineage.
