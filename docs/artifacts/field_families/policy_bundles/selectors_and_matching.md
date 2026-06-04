# Selectors and Rule Matching

## Cross-Cutting Rule-Match Selectors

Timeline-protection rules can also match scalar or list-valued
`transition_decision` / `transition_decisions` and `application_status` /
`application_statuses` from approval requirement activity context. They can also
match planned timeline-feedback/import protection context via
`planned_protection_decision` and `planned_protection_category` selectors plus
plural-list variants. Cadence-facing review action and reason codes can be
matched via `required_operator_action`, `operator_action_reason`, and
plural-list variants.
Contact-allocation status and reason evidence can be matched via scalar or list-valued
`allocation_status`, `effective_allocation_status`, `allocation_reason`, and
plural-list variants.
Resource suppression routing evidence can be matched via scalar or list-valued
`suppressed_reason`, `resource_blocking_dimension`, and plural-list variants.
Station reservation routing evidence can be matched via `station_reservation_id`,
`station_reserved_by`, `station_reservation_match_status`, and plural-list
variants.
Provider station-calendar ambiguity and reservation owner/status evidence can
be matched via `station_calendar_entry_ambiguous`,
`station_calendar_ambiguous_entry_id`,
`station_calendar_ambiguous_entry_count_min`,
`station_calendar_ambiguous_entry_count_max`, `station_calendar_reserved_by`,
`station_calendar_reservation_status`, `station_calendar_reservation_id`, and
plural-list variants; rule-match rows preserve both scalar and plural
reservation owner/status/ID evidence when available.
Timeline-integrity review evidence can be matched via scalar or list-valued
`timeline_integrity_status`, `timeline_integrity_issue_type`,
source/replacement-prefixed timeline-integrity selectors, and plural-list
variants. Nested source/replacement protection decisions and categories can be
matched via scalar, nested-map, or list-valued
`source_protection_decision`, `source_protection_category`,
`replacement_protection_decision`, and `replacement_protection_category`
selectors plus plural-list variants. `timeline_protection_v1` uses these
selectors to route source-preserved transition applications,
executed/locked planned-protection evidence, dependency/exclusivity integrity
issues, and locked/approved source-protection decisions to mission-planning
review. `policy_decision.v1` rule matches retain the matched scalar and
list-valued transition/protection/integrity values for adapter queues.

## Policy Bundle Schema and Rule Matching

The `policy_bundle.v1` JSON Schema exports the nested approval-policy and
action-rule field types used by these bundles, including contact `direction`,
direction-list evidence, station-calendar direction evidence,
`ground_station_id`, station availability, reservation, capacity-fraction, and
payload/antenna availability match fields, plus missing custom-priority-field
evidence selectors for contact contention/allocation policy routing.
It also types actual-completion, confidence-threshold, and raw provider-result
match fields for contact, command, observation, and maneuver evidence so policy
rows can classify low completion/confidence or failed provider-result feedback
without reopening free-form activity payloads.
Policy matching treats
provider-shaped rule or requirement-context `station_id` as canonical
`ground_station_id` for contact authority and ground-network allocation rules,
canonicalizes provider-shaped station-calendar status selectors before matching,
and requirement rules can also scope to requirement-context `spacecraft_id`
(or planner-native `scenario_id`) and `target_id`. These scoped identity
selectors also consume aggregated `ground_station_ids` / `station_ids`,
`spacecraft_ids` / `scenario_ids`, and `target_ids` requirement context, and
preserve the matched lists in rule-match evidence. Direction-scoped rules match
either scalar `direction` or list-valued `directions` requirement context, and
rule-match evidence preserves both fields. Station-calendar direction rules
match scalar `station_calendar_direction` or list-valued
`station_calendar_directions` context and preserve both fields in rule-match
evidence. Station-calendar entry, provider, provider-entry, status,
trust-boundary, and reservation-ID rules match scalar or list-valued
station-calendar context from risk indicators, branch events, and requirement
context and preserve those matched lists in rule-match evidence; branch
risk/event matching treats direct `station_reservation_id` / `reservation_id`
as station-calendar reservation ID context and direct `station_reserved_by` /
`reserved_by` plus `station_reservation_status` / `reservation_status` as
provider-calendar owner/status context for provider-calendar rules.
Station-reservation owner rules match scalar
`station_reserved_by` or
list-valued `station_reserved_bys` requirement context; direct reservation
status and match-status rules likewise match scalar or list-valued
`station_reservation_statuses` and `station_reservation_match_statuses`
context. Rule-match evidence preserves those owner/status lists for downstream
review/import routing. Station-scoped risk or branch-event rules use the same station
alias when matching provider risk indicators and ground-station events.
Branch-event rules also honor `spacecraft_id` and `target_id` scopes for
spacecraft and target events.
When a rule comes from an organization or inline policy bundle with adapter
provenance, each policy rule match also lifts the bundle source, adapter,
organization ID, policy source, and trust boundary so downstream review queues
can route the matched authority rule without unpacking top-level policy
provenance.
Spacecraft-scoped risk rules can match resource and availability risk
indicators by `spacecraft_id`, and target-scoped risk rules can match target
feedback or urgent-target risk indicators by `target_id`.
Resource-filter suppression risks preserve spacecraft, scenario, station,
target, and direction evidence from the suppressed row so scoped risk rules can
classify resource suppressions without crossing assets.
Feasibility-status rules use the same station, spacecraft, and target scope
fields when matching strategic additions.
`policy_decision.v1` can carry
an optional `policy_bundle_provenance` map for organization-adapter policy
source evidence and optional `escalations`
summary derived from matched rules. New policy decisions also carry
schema-validated `model_limits` copied from `Policy.capabilities/0`, keeping the
classification-only and no-execution boundary visible on the decision artifact
itself. The exported
`policy_decision.v1` JSON Schema also types the nested `rule_matches` and
`escalations` rows plus the provenance map so downstream import gates can
inspect authority context, SLA metadata, and adapter source evidence without
relying on free-form arrays. Rule matches are ordered by rule, activity,
risk/event/feasibility type, scope IDs, and reason fields so repeated scoped
matches have deterministic evidence order. Confidence-factor rule matches
preserve the matched observation and maneuver success factors plus source labels
alongside the existing contact and command feedback evidence. Policy action
rules can also match `feedback_source`, `feedback_scope`, `trust_boundary`, and
`source_event_type` across branch events, approval-requirement activity context,
and strategic-addition feasibility evidence, allowing review bundles to route
report-derived candidates by their provenance boundary instead of only by
activity type. Approval-requirement rule matching can scope to
`policy_classification` / `policy_classifications` without matching unrelated
requirement rows, and preserves the matched classification in rule-match
evidence. Requirement-context selectors for status, approval status, policy
classification, review queue, review queue key, and Cadence import status also
read list-valued fields such as `statuses`, `approval_statuses`,
`review_queues`, `review_queue_keys`, and `cadence_import_statuses`, preserving
  those lists in rule-match evidence when present. Resource/provenance selectors
  likewise consume aggregated requirement context such as
  `resource_pressure_statuses`, `resource_source_qualities`,
  `resource_trust_boundaries`, `resource_trust_boundary_statuses`,
  `first_resource_pressure_kinds`, `feedback_sources`, `feedback_scopes`,
  `trust_boundaries`, and `source_event_types`, preserving those lists in
  rule-match evidence. Station availability and contention selectors likewise
  consume `station_availabilities` and `station_contention_statuses` from
  aggregated requirement context. Branch-event rule matching also preserves matched
`approval_status`, `policy_classification`, `allocation_status`,
`effective_allocation_status`, and `allocation_reason` evidence, so
policy-blocked allocation-derived refresh branches can be blocked before
recommendation ranking instead of merely annotated. The
`policy_classification` and `policy_classifications` rule selectors are
schema-constrained to the policy classification enum
(`auto_approvable`, `operator_review_required`, `blocked_by_policy`) rather
than arbitrary status strings.
