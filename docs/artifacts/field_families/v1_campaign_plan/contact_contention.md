# Contact Contention and Resolution

`contact_contention_report.v1` and
`contact_contention_resolution_report.v1` are standalone executable/exported
contracts. Their schemas expose nested conflict-group and recommendation rows
for station- and spacecraft-scoped contention import/review flows without
granting reservation or schedule-mutation authority. Conflict groups carry
stable group IDs, resource scope, station and spacecraft IDs, timing bounds,
direction and direction-list evidence, source-window IDs, required operator
action, approval status, optional approval-policy evidence, and provenance so
review queues do not need to reconstruct planner context. Conflict groups and
resolution recommendations also carry deterministic overlap-pressure metrics:
contention window seconds, summed contact duration, seconds with at least two
active contacts, maximum concurrent contacts, and pairwise overlap count. These
metrics are computed from the report intervals and flow through operator-review
and Cadence-import rows as severity evidence without reserving station time.
They also preserve conservative station capacity context (`capacity_fraction`,
`capacity_fraction_min`, and `capacity_fraction_max`) from capacity-fraction
fields and provider percent aliases such as `capacity_percent`,
`station_capacity_percent`, and nested throughput/capacity/activity context
variants, so reduced-capacity station evidence remains routable through
contention review and import rows without implying a link-budget model.
Exported nested
schemas now put the stable-ID pattern on contact, source-window, scenario,
station, spacecraft, invalid-input, and deferred-contact ID arrays so Cadence
preflight validation sees the same identity contract as executable lint.
Same-spacecraft
groups are only emitted for overlaps spanning multiple ground stations, leaving
single-station overlaps on the existing station-contention path. When a contact
does not declare `spacecraft_id`, the planner-native `scenario_id` is used as
the spacecraft scope for this artifact-only contention check. The same behavior
is available through
`OrbitalDynamics.Communications.ContactContention` and the public
`OrbitalDynamics.contact_contention_report/2`,
`OrbitalDynamics.annotate_contact_contention/2`, and
`OrbitalDynamics.contact_contention_resolution_report/3` facades for
standalone atom- or string-keyed contact inputs, with `start_s`/`end_s`
normalization, direction-only station-window support for command/uplink/
tracking/health-check/downlink rows, typed health-check contact grouping,
provider-shaped downlink inference for station/time rows
without explicit type or direction, nested `station` / `ground_station`
identity normalization before contention grouping, and deterministic advisory
recommendations that do not mutate the candidate set. Resolution policy can opt into
priority-aware ordering (`highest_priority_highest_score` or
`highest_priority_earliest_start`) using declared priority fields such as
`contention_priority`; it can also use computed `command_contact_priority` to
prefer command/uplink contacts over routine downlinks without requiring callers
to precompute a numeric priority. The default priority field chain also includes
computed `station_reservation_priority`, which lets contacts carrying direct
matched/owned station-reservation evidence, including the `owner_matched`
handoff emitted for caller-owned reserved windows, or a direct reservation ID
with an active reservation status win over higher-score unreserved contacts in
advisory resolution reports. The computed priority accepts both station-prefixed fields
and direct reservation aliases such as `reservation_id`, `reservation_status`,
and `reservation_match_status`. Aggregate provider-calendar reservation lists remain review
evidence and do not create phantom reservation priority. Direct reservation
identity, reserver, reservation status, and match-status evidence are also
flattened onto conflict groups and resolution recommendations as plural lists so
operator review and import routing can inspect ownership context without
unpacking `source_contact_candidates`; approval-policy rules match the same
plural owner/status/match-status lists through `station_reserved_bys`,
`station_reservation_statuses`, and `station_reservation_match_statuses` when
aggregated contention or allocation context has no single reservation field.
Resolution
`tie_breakers` are executable and deterministic for `starts_at_s`, `ends_at_s`,
`score`, `priority`, `command_contact_priority`,
`station_reservation_priority`, `id`, and `contact_id`, so operators can make
equal-score/equal-priority conflicts prefer earlier-ending contacts,
reservation-matched contacts, or other declared tie policy without mutating
provider reservations. Numeric-string score and priority evidence is parsed at
the same ranking boundary, while malformed numeric strings fall back to missing
numeric evidence.
When callers declare custom priority fields, resolution recommendations now
publish `requested_priority_fields`, per-field numeric evidence counts, and
`priority_fields_without_numeric_evidence_count` /
`priority_fields_without_numeric_evidence` so review queues can distinguish an
intentional custom field from one that had no usable numeric evidence in that
contention group. Unsupported caller
selection rules are normalized back to the default executable policy, while the
requested value, ignored tie breakers, malformed policy input, and policy
warnings remain visible in the artifact. Keyword-list policies are accepted as
operator input. The exported JSON Schema now describes the nested resolution
policy shape, including `selection_rule`, `priority_fields`, `tie_breakers`,
`requested_priority_fields`, `requested_selection_rule`,
`ignored_tie_breakers`, `ignored_policy_input`, `policy_warnings`, `action`,
and normalized mission-specific priority override maps/counts/IDs, instead of
leaving that policy metadata as an opaque object.
Executable validation checks override map values, stable contact IDs, and
count/list consistency. Each resolution recommendation also carries the
effective selection rule, priority fields, tie breakers, unsupported requested
rule, ignored tie breakers/input, policy warnings, custom priority evidence
coverage, and override count/ID handoff through operator-review and
Cadence-import rows, so reviewers do not have to reopen the report-level policy
object to understand why a contact was selected. Selected/deferred priority evidence is preserved through
recommendation, operator-review, and Cadence-import rows. Contact-like inputs
missing contention identity,
station, or timing fields are preserved in `invalid_contact_inputs` with
`invalid_contact_input_reason`, required review action, and the original
`source_contact_candidate`, and those rows flow through operator-review and
Cadence-import handoff instead of being dropped before contention detection.
When an approval policy is supplied, invalid contact-contention inputs also
receive row-level `approval_requirements`, approval-rule matches, and
`policy_decision.v1` evidence, keeping malformed handoff review under the same
ground-network authority routing as normal contention groups.
Contact-contention invalid-input rows and contention-resolution recommendations
constrain `review_status` to `operator_review_required` in executable
validation and exported JSON Schema so review/import queues cannot invent
readiness labels.
Standalone contention also validates stable-ID-shaped contact, station,
source-window, scenario, and spacecraft identity fields before grouping:
malformed identity values are blocked as invalid-input review rows, omitted
from schema-facing summary fields, and preserved in the original
`source_contact_candidate`. Malformed non-map contact handoffs are retained as
`invalid_contact_shape` rows with raw input evidence instead of crashing direct
contention report generation.
Duplicate contact IDs inside a conflict group are surfaced as
ambiguous contact identity, and the resolution report requires operator review
instead of selecting an arbitrary duplicate ID. Generated conflict-group and
recommendation identity is source-order invariant: duplicate candidates are
canonicalized by contact/source-window/provider identity before public group
IDs, source candidate arrays, and duplicate-candidate review evidence are
emitted. Approval requirements for
contention groups and resolution recommendations preserve command/uplink
contention as `command_review`, while duplicate-identity rows preserve duplicate
contact IDs, duplicate-candidate counts, resolution status, and resolution issue
in `activity_context`, so policy decisions do not hide identity ambiguity.
Contention groups and resolution recommendations also aggregate source contact
and command feedback evidence from top-level candidate fields or metadata,
preserving trimmed case-insensitive JSON-style false success flags, minimum
confidence factors, and actual-throughput evidence through review/import rows.
They also derive group-level station availability and station-calendar status
from direct `availability` / `station_calendar_status` fields plus nested
`source_station_calendar_entry` and `source_station_calendar_overlaps` evidence
before approval-policy classification, so unavailable station-time contention
cannot be downgraded to ordinary same-station review at the artifact boundary.
feedback confidence factors, source labels, and actual throughput derived from
actual-data-volume or actual data-rate plus duration evidence into policy `activity_context`,
operator-review rows, and Cadence-import rows. This keeps failed or
low-confidence contact evidence visible during contention review without
executing commands, mutating schedules, or reserving provider time.
They also aggregate applied `station_calendar_directions` across the contended
contacts and carry that direction context through group/recommendation policy
context, operator-review rows, and Cadence-import rows.
Executable validation treats top-level contention summary counts and nested
group/recommendation counts as integers, matching the exported JSON Schema and
keeping review/import queue totals discrete. It also cross-checks
`conflict_group_count`, `conflicted_contact_count`, duplicate-contact summary
counts, invalid-contact IDs, and `recommendation_count` against the emitted
group, invalid-input, and recommendation rows.
Executable validation also checks both report-level `model_limits` arrays
against `OrbitalDynamics.Communications.ContactContention.capabilities/0`, so
saved contention and advisory-resolution artifacts stay aligned with the shared
artifact-only model boundary.
For deterministic resolution recommendations, executable validation also
requires `selected_contact_id` plus `deferred_contact_ids` to be a unique,
exact match for the IDs in `source_contact_candidates`. This preserves the
producer's single-candidate-set decision invariant and rejects substituted or
self-deferred identities before downstream planner use.
When a conflict group carries `source_contact_candidates`, their ID multiset
must likewise match `contact_ids`; ordering may differ and legitimate duplicate
identity evidence remains representable, but substituted or missing candidate
rows are rejected.
Resolution-summary group maps must reference their corresponding recommendation,
review, or ambiguous group lists, and review/ambiguous group IDs must reference
recommendation groups. Candidate-refresh aggregation and replay apply the same
lineage filter when consuming preserved summaries without standalone validation.
Resolution-summary resource-scope, selection-reason, and review-action maps also
require keys backed by positive entries in their corresponding count maps.
Candidate-refresh filters those category keys per source report and again during
preserved replay, while retaining flattened contact IDs and aggregate counts as
review evidence.
Its exported JSON Schema includes the nested row and `timeline_identity` field
shape used by executable validation. Rows also carry artifact-only operational
kind, required operator action, operator-action reason, execution boundary,
Cadence import status, station availability, and schedule-conflict status when
that context is present. Planned activity dependency and exclusivity metadata is
preserved as deterministic stable-ID arrays for review/import consumers; the
report records those relationships but does not enforce a schedule graph.
