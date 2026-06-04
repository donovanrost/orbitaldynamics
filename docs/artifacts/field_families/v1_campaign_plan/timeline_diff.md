# Timeline Diff Report

`OrbitalDynamics.timeline_diff_report/3` builds `timeline_diff_report.v1` rows
by comparing source and replacement activities by timeline identity. Rows carry
stable diff IDs, added/removed/changed/unchanged status, source and replacement
activity IDs, source/replacement spacecraft IDs, ground-station IDs, target IDs,
source-window IDs, timing deltas, changed fields, review requirements, and
source or replacement timeline identities. Status and approval changes are also exposed
as typed transition objects so review/import consumers do not need to infer
them from parallel source and replacement fields; exported JSON Schemas now
formalize the transition object fields including lifecycle category,
transition category, and operator-review recommendation, and executable
validation checks the same typed transition fields rather than treating
transition objects as opaque maps, including after timeline-diff rows are lifted
into operator-review and Cadence-import handoff rows. It also checks
`timeline_diff_report.v1` report-level `model_limits` against
`OrbitalDynamics.Timeline.model_limits/0`. Dependency or exclusivity
metadata changes are treated as reviewable changed fields and preserve source
and replacement stable-ID arrays. Source and replacement dependency/exclusivity
integrity evidence from the same typed activity normalizer is also preserved:
unchanged rows with dependency cycles or other timeline-integrity issues become
`review_timeline_integrity` diff rows, and flattened
`source_dependency_cycle_*` / `replacement_dependency_cycle_*` fields flow into
operator-review and Cadence-import handoff rows. Command/contact execution
evidence changes such as `contact_result`, `command_result`,
`contact_success`, `command_success`, and feedback confidence factors are also
reviewable timeline-diff fields, with source/replacement activity context
preserved for review and import handoffs. Planned-versus-actual throughput,
downlink-completion requirement/shortfall/source evidence, data-volume,
collection/delivery latency, thermal evidence, and resource margin/availability evidence changes are also
reviewable timeline-diff fields, so delivery shortfalls do not pass through as
unchanged timeline rows.
Station-calendar trust/source evidence changes, including
`station_calendar_trust_boundary_status`, `trust_boundary`, `provenance`,
`source_station_calendar_entry`, and `source_station_calendar_overlaps`, are
also reviewable timeline-diff fields when supplied in activity context.
Resource-assignment and resource-evidence changes are also reviewable
timeline-diff fields and carry source/replacement `resource_id`, trust,
provenance, margin, battery, and availability context through review/import
handoffs.
Thermal-evidence changes carry source/replacement temperature, operating-bound,
derived-margin, status, source, model, and confidence context through the same
review/import handoffs.
Execution-uncertainty map changes are
also reviewable timeline-diff fields, carrying declared/missing status and
derived uncertainty summary through source/replacement context without implying
finite-burn execution. Maneuver success confidence fields are preserved in
operational activity context and are reviewable diff fields when they change.
Duplicate source or replacement
timeline identities are preserved as review-required collision rows with the
colliding activity IDs and normalized activity rows, so a bad identity assignment
cannot silently drop timeline evidence. Removed or changed source activities that were
executed, locked, or approved carry specific review actions so
preservation-sensitive replacements do not look like ordinary timeline edits.
Those timeline-diff review actions are now a schema-visible executable
vocabulary, so added, removed, protected, duplicate-identity, invalid-input,
integrity, review-only, record-only, and no-op rows cannot persist arbitrary
provider action strings.
Added, removed, and changed rows also carry source/replacement activity context
when that side exists, allowing review and import consumers to keep timeline
identity, dependency, exclusivity, timing, target, and station evidence without
reconstructing it from the full activity payload. The report also exposes
row-derived `diff_status_counts`, `required_operator_action_counts`,
`changed_field_counts`, `status_transition_counts`,
`approval_transition_counts`, `status_transition_category_counts`, and
`approval_transition_category_counts` maps with executable validation against
the rows and integer count-map values. Diff rows also carry deterministic
`transition_decision` and `transition_decision_reason` fields, summarized by
`transition_decision_counts`, so protected source activities, review-gated
changes, record-only changes, and unchanged rows are explicit before
operator-review or Cadence-import handoff. Executable validation also rejects
duplicate timeline-diff row IDs,
matching the stronger row-identity guarantees already used by operator-review
and Cadence-import artifacts.
Malformed source or replacement inputs missing a stable activity identity,
carrying malformed activity IDs, or missing activity type are preserved as
side-specific `review_invalid_activity_input` rows with original input evidence,
schema-stable synthetic review IDs, `invalid_source_activity_input_*` and
`invalid_replacement_activity_input_*` summary fields, and the same
review/import propagation as other timeline-diff rows.
Timeline-diff review/import
rows expose the concrete diff reason as `operator_action_reason`, matching the
other Cadence-facing review surfaces that carry actionable review causes, and
preserve transition-decision fields from the source diff row for adapter queues.
The executable contract and exported JSON Schema apply the same stable-ID shape
to nested source and replacement timeline
identities as operational timeline rows. The report is artifact-only and does
not mutate either schedule.
