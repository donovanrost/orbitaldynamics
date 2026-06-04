# Command Window Report

`OrbitalDynamics.command_window_report/2` builds
`command_window_report.v1` rows for command, tracking, health-check, and uplink
contact windows, including provider-shaped `planned_contact` rows that declare
`direction: health_check`. Rows carry stable IDs, timing, direction, approval status,
required operator action, Cadence import status, source-window lineage, optional
approval-policy classification evidence, derived timeline identity, and
dependency/exclusivity stable-ID arrays from the source activity. Executable
validation checks report-level `model_limits` against
`OrbitalDynamics.Communications.CommandWindow.capabilities/0`, so command-window
artifacts cannot drift from the no-command-execution/no-provider-reservation
boundary while still passing schema lint. Rows also
carry the reusable `activity_context` shape used by operational timeline,
policy, review, and import artifacts, preserving timing, source-window lineage,
timeline identity, contact result, command result/success,
command-success feedback factors,
station contention status, reservation identity, reservation owner/status, and
`station_reservation_match_status` through command-window handoffs.
Command-window ingress parses clean numeric-string timing aliases,
top-level or metadata-supplied command/contact success booleans, result labels,
success factors, source labels, declared capacity-fraction evidence, and
provider capacity percent aliases such as `capacity_percent`,
`station_capacity_percent`, and nested throughput/capacity/activity context
variants before timeline normalization. List-valued provider result labels are flattened to
deterministic comma-joined strings in command-window rows and activity-context
handoffs, so provider and adapter handoffs reach `command_window_report.v1` as
schema-valid review evidence while malformed numeric strings remain missing
numeric evidence. It also canonicalizes
direct station-calendar `availability` and `station_calendar_status` outage or
maintenance aliases, plus nested `source_station_calendar_entry` /
`source_station_calendar_overlaps` status evidence, before operator-action and
approval-policy classification, so direct command/tracking/uplink windows cannot
bypass unavailable-station blocking when no separate station-calendar overlay is
supplied. Provider
reservation aliases (`reservation_id`, `reserved_by`, `reservation_status`, and
`reservation_match_status`) are normalized into the canonical
`station_reservation_*` handoff fields before policy, operator-review, and
Cadence-import routing, so adapter-shaped reservation evidence remains
actionable without a separate overlay rewrite. Nested provider-calendar
reservation evidence under `source_station_calendar_entry` feeds the same
canonical station-reservation fields and derives an `overlap` match status when
the command or tracking row did not already claim the reservation, preserving
the difference between owned station time and provider-reserved overlap.
Nested `source_station_calendar_overlaps` reservation entries also derive the
plural `station_calendar_reservation_*` list/count context used by approval
policy matching, operator-review rows, and Cadence import rows, so a policy can
route a specific reservation inside a multi-reservation provider overlap list
without callers flattening that provider payload first.
Declared station-calendar overlays may be supplied as direct calendar rows,
singular provider artifacts, or lists containing multiple
`station_calendar_provider.v1` artifacts; command-window reports preserve the
matched provider ID, provider entry ID, reservation IDs, and nested
`station_calendar_report.v1` counts through report, operator-review, and
Cadence-import rows. When station-calendar evidence requires command-window
review, it takes precedence over generic missing Cadence-import preparation
while preserving the superseded action and reason in the row.
Provider
contact-result failures on completed/executed uplink or command-window rows are
preserved from the shared timeline classifier as reviewable terminal exceptions
instead of being flattened to normal terminal rows. Rejected or policy-blocked
approval states on terminal command-window rows also stay review-gated through
the same shared classifier. The report consumes the shared typed activity
normalizer, so dependency ordering and exclusivity integrity issues are carried
as review-gated command-window rows, dependency cycles preserve
`dependency_cycle_activity_ids` / `dependency_cycle_timeline_ids`, and missing
dependency checks are available through `validate_missing_dependencies?: true`.
Malformed command, tracking, or
uplink activity inputs that still declare usable window timing are also retained
as `review_invalid_activity_input` command-window rows with invalid-input reason
and source activity evidence; when an approval policy is supplied, those rows
also carry policy-decision and rule-match evidence through the same handoff
fields as valid command-window rows, including matched escalation authority,
rule, queue, role, level, SLA, and source escalation metadata. The embedded
operator-review and Cadence-import command-window rows preserve that context so
adapter gates can see prerequisite, mutually exclusive, and timeline-integrity
context without executing commands. When a command-window report is embedded in
a V2 repair result inside a V3 strategy branch, the exported schema now exposes
the same nested row, timeline identity, command-success, and count shapes
instead of an opaque nested object. Prior `source_command_window_report`,
`command_window_report`, result-artifact-embedded `command_window_report.v1`,
or preserved command-window review/import rows from `operator_review_package.v1`
and `cadence_import_manifest.v1` with command-success factors or provider
command-result evidence are also normalized into strategy
`operational_feedback.command_success_rate`, allowing low-confidence command
windows to derive branch-local command-success review branches without
resubmitting raw provider telemetry; explicit command-success JSON-style
booleans from realized state are normalized on the same V3 feedback path. Their
source provenance exposes weighted row counts, feedback-weight source labels,
and report or wrapper trust-boundary evidence when present.
Prior `source_operational_timeline_report` or `operational_timeline_report`
rows now feed standalone candidate refresh directly from top-level,
mission-state, accepted-planning-state, result-artifact, operator-review, and
Cadence-import handoffs. Contact rows update
`operational_feedback.contact_success_rate`, downlink contact throughput updates
`operational_feedback.station_throughput_factor`, observation rows update
`operational_feedback.observation_success_rate`, and command/maneuver rows feed
the same command-window and maneuver-review success maps at lower priority than
realized timeline feedback and explicit request feedback. Source provenance
records report paths, row counts, feedback-field counts, required-action counts,
and report/row trust boundaries for those operational timeline replay inputs.
Prior `source_maneuver_review_report` or
`maneuver_review_report` rows with maneuver-success factors or provider
maneuver-result evidence are likewise normalized into strategy
`operational_feedback.maneuver_success_rate`, allowing low-confidence maneuver
recommendations to derive branch-local maneuver-success review branches without
resubmitting raw provider telemetry; explicit maneuver-success JSON-style
booleans from realized state are accepted on the same path while preserving the same weighted
source-provenance context. Those maneuver-review report rows now also replay
declared or missing maneuver execution-uncertainty evidence into
`operational_feedback.maneuver_execution_uncertainty`, with provenance counts
for declared/missing uncertainty rows, so review artifacts can regenerate
branch-local uncertainty review without resubmitting the original timeline
feedback report. Timeline-feedback
`operational_feedback.maneuver_execution_uncertainty` entries with missing or
over-threshold timing / delta-v 3-sigma values derive
`maneuver_execution_uncertainty_feedback` branches, preserving the raw
uncertainty map, thresholds, source label, feedback key, and trust boundary for
branch-local review without changing maneuver execution semantics. Prior
`operator_review_package.v1`
command-window or maneuver-review rows that preserve those source rows feed the
same command/maneuver feedback path without requiring the original source
reports to be resubmitted. Operational-timeline review and realized-feedback
rows now copy the same maneuver execution-uncertainty fields into that feedback
handoff, so timeline review/import wrappers can regenerate uncertainty review
branches as well as maneuver-success branches; row-specific operational-timeline
branches preserve the concrete uncertainty feedback event and source path for
adapter review, including top-level `cadence_import_manifest.v1`
`review_operational_timeline` rows. Realized-feedback maneuver rows preserve
the same row-specific uncertainty events alongside maneuver-success feedback,
so completed maneuver telemetry does not lose its execution-uncertainty review
reason, including top-level `cadence_import_manifest.v1` realized-feedback rows
that flatten the source review row. Direct maneuver-review source rows also
preserve row-specific uncertainty events, including uncertainty-only review
rows, so maneuver-review imports retain the concrete covariance review reason
instead of only contributing aggregate operational feedback. They also derive source-specific branch-local
`command_success_feedback` and `maneuver_success_feedback` branches from
preserved `source_command_window` and `source_maneuver_review` rows, and Cadence
import rows with either nested source-review rows or top-level source payloads
replay the same handoff with their import queue trust boundary. Command-window
feedback branches retain station-calendar
provider IDs, reservation identity and status, reservation-match evidence,
station availability, and direction from the preserved source row so
branch-comparison rows can expose the ground-network reason behind low
command-success confidence. Prior `operator_review_package.v1`
operational-timeline review rows that preserve source timeline rows also feed
contact success, station throughput, observation success, command success, and
maneuver success into strategy `operational_feedback`, allowing those review
queues to drive branch-local contact, observation, command, and maneuver review
branches without resubmitting raw timeline feedback reports. Feedback and
confidence weight aliases from the preserved source timeline rows are applied
to those deterministic feedback averages. Matched,
non-invalid `operator_review_package.v1` realized-feedback
rows also feed contact, station-throughput, downlink-demand shortfall,
observation, command, and maneuver confidence into strategy
`operational_feedback`; provider `realized_status` is interpreted as execution
status when the review row's `status` only records match state, so failed
reviewed downlinks can drive replacement demand without requiring an explicit
success-factor field, normalized lifecycle-event tokens can supply the same
terminal execution status when adapter rows omit `realized_status`, and
reviewed observation, command, or maneuver rows can
still drive confidence feedback from execution status alone. Top-level
feedback/confidence weight aliases on those review rows are applied before the
rows are folded into deterministic feedback averages, and source provenance
preserves weighted row counts, declared feedback-weight source labels, and
review-queue key counts. Realized contact feedback can derive actual
throughput from provider actual-data-rate plus duration aliases before
calculating station-throughput and downlink-demand feedback, so branch-local
refreshes do not require providers to precompute `actual_throughput_mb`; the
feedback row also carries `actual_data_rate_throughput_derivation` evidence
when throughput came from rate-duration reconstruction.
Preserved realized-feedback `source_feedback` rows now
also derive branch-local feedback branches directly, retaining the review or
Cadence import source path and trust boundary on contact, throughput,
observation, command, and maneuver feedback events. The same preserved
`source_feedback` evidence is exported and executable-validated as a
`timeline_feedback_report.v1` row on operator-review rows, Cadence import rows,
and embedded `source_review_row` copies, keeping realized feedback identity
checks intact for adapter handoff.
Operator-review contact/resource suppression rows that preserve
`source_contact_suppression` or `source_resource_suppression` can also drive
V3 branch-local refresh pressure directly. This lets a strategy request consume
the review package as the durable handoff and still derive downlink-completion,
station-reservation, antenna, payload, spacecraft, and resource-margin pressure
branches without requiring the original contact/resource filter reports to be
resubmitted.
Operator-review source action counts use `required_operator_action` when
adapter-facing rows omit the shorter `action` field.
Executable validation rejects weighted feedback row counts that exceed the
declared source report row count or realized activity count.
Ambiguous or invalid
feedback rows stay review-only and do not become branch inputs. The
`command_contact_authority_v1` policy
bundle can classify those command-window rows by command/uplink/tracking
direction and health-check activity type before they are lifted into
review/import packages.
Direct mission-state realized downlink rows follow the same status split:
provider-shaped rows with review/match `status` and failed `realized_status`
derive downlink-completion recovery branches rather than being mistaken for
successful matched rows.
Executable validation rejects duplicate command-window row IDs before
review/import handoff and treats command-window scalar counts plus row ranks and
timeline-integrity issue counts as integers matching the exported JSON Schema.
It also cross-checks top-level window-type counts, invalid activity IDs,
review-required totals, and source-window lineage totals against emitted rows
so command-authority review queues do not need to trust duplicated summary
metadata.
The report is a review/import boundary only; it does not reserve station time or
execute commands.
