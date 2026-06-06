# Link Capacity Report

`link_capacity_report.v1` is available through
`OrbitalDynamics.Communications.LinkCapacity` and the public
`OrbitalDynamics.link_capacity_report/3` facade for standalone atom- or
string-keyed contact inputs. It groups native `downlink` rows and
`planned_contact` rows whose direction is `downlink` by station, preserves
selected-contact IDs, and totals raw and station-capacity-adjusted throughput
under the existing fixed-rate planning model, deriving MB from declared data
rate and contact duration when explicit throughput MB is absent. Throughput-bearing provider or
contact rows without explicit `type` or `direction` are treated as downlink-like
capacity inputs, including rows that carry nested `station` or
`ground_station` identity objects instead of flat station IDs, so valid rows
contribute to station summaries and invalid rows remain review-gated. Direct
station-calendar availability/status evidence on contributing contacts is
canonicalized before capacity adjustment; unavailable or maintenance evidence,
including nested source-calendar outage evidence, contributes zero
station-capacity throughput while preserving station-calendar entry/provider
identity and policy classification context. Downlink-like candidate or selected rows missing stable
contact identity or station identity are preserved as `invalid_contact_inputs`
or `invalid_selected_contact_inputs`, routed into operator-review and Cadence
import rows, and excluded from throughput totals instead of raising or being
silently dropped. Link-capacity input validation also rejects malformed
stable-ID contact, station, scenario, and spacecraft identity values before
station grouping; schema-facing invalid rows sanitize or omit those fields while
preserving the original source handoff. Out-of-range contact/command feedback
confidence and selected-contact completion fractions are also preserved on the
invalid input review path instead of being clamped into aggregate capacity,
policy, review, or import evidence. Malformed non-map candidate or selected
handoffs are retained as `invalid_contact_shape` rows with raw input evidence on
the same review path. When an approval policy is supplied, invalid
link-capacity contact inputs also carry `approval_requirements`,
`approval_rule_matches`, and `policy_decision.v1` evidence through
operator-review and Cadence-import rows. Optional `policy.required_downlink_mb` and
`policy.required_downlink_mb_by_ground_station` inputs compare selected
capacity-adjusted throughput against declared downlink demand. Station-scoped
policy requirements emit station rows even when no candidate contacts exist for
that station, so missing station capacity remains visible in operator-review and
Cadence-import rows instead of only appearing in top-level totals. Malformed
station keys in station-scoped policy requirements are preserved as
`invalid_policy_required_downlink_station_ids` metadata, but they are excluded
from station rows and required-throughput totals until corrected; operator-review
and Cadence-import rows surface the same malformed policy keys as a
`review_invalid_link_capacity_policy` action. When those policy requirements are
absent, per-contact `required_downlink_mb` values are summed as declared demand
and traced through `required_downlink_contact_count` plus
`required_downlink_contact_ids`. Link-capacity rows also preserve the aggregate
`downlink_completion_source` and exact `downlink_completion_sources` lineage
from policy fields or the contributing required-downlink contacts, including
nested throughput/activity-context source evidence. The same lineage flows into
approval context, operator-review rows, and Cadence-import rows so the capacity
summary does not sever candidate-refresh or operational-feedback demand
provenance. Reports emit `selected_downlink_shortfall_mb` and
`downlink_requirement_status` for review/import rows. Planned data-volume
aliases such as `planned_data_volume_mb`, `estimated_data_volume_mb`, and
`data_volume_mb` count as candidate capacity evidence. When selected realized
downlink rows carry `actual_throughput_mb`, `actual_data_volume_mb`, or provider-style
`actual_downlink_mb`/`delivered_data_mb`/`received_data_mb` aliases, the report
also sums actual delivered throughput for selected IDs that match exactly one candidate row and
emits `actual_throughput_mb`, `actual_throughput_contact_ids`,
`actual_downlink_shortfall_mb`, `actual_downlink_completion_ratio`, and
`actual_downlink_requirement_status` so review/import rows can distinguish
planned capacity from realized delivery against the same declared downlink
requirement without claiming a full provider reconciliation model. Selected realized
downlink rows that carry `completed_fraction` or completion aliases also emit
an average `actual_completion_fraction` plus matched contact IDs using the same
exact candidate-identity rule after unit-interval validation. Selected realized throughput or
completion-fraction rows that are unmatched or map to duplicate candidate IDs
are now kept in unresolved actual-throughput/completion ID fields and routed to
operator-review plus Cadence-import rows instead of being silently reconciled;
station rows carry the same unresolved actual ID evidence scoped to the affected
ground station when such feedback exists. The exported link-capacity schema now
puts the same stable-ID pattern on top-level invalid/unmatched/ambiguous contact
ID arrays and station-row contact, selected-contact, duplicate-contact, and
ambiguous-selected-contact ID arrays that executable validation applies.
In V1 campaign
artifacts, a downlink-completion objective with `required_downlink_mb` becomes
the embedded link-capacity requirement unless the scoring/link-capacity policy
declares an explicit override; V2 repair artifacts apply the same fallback from
their mission-state downlink objective when supplied. V2 repair and V3
downlink-completion staging accept top-level `activity_type` as the planned or
candidate activity-kind alias before provider inference. Explicit
`activity_type: downlink` rows normalize into canonical downlink activity fields
while command, uplink, and tracking contacts do not contribute to downlink
capacity. Provider-shaped station/time candidates that omit explicit type or
direction still normalize `station_id`, nested `station` / `ground_station`
identity objects, nested `spacecraft` / `satellite` identity objects, `start_s`,
and `end_s` before proposal and feasibility evaluation. It is
still an artifact-only
summary: no link budget, modulation model, provider reservation, or schedule
mutation is implied. Selected capacity is counted only for selected IDs that
match exactly one candidate row; duplicate candidate IDs and unmatched selected
IDs remain visible in the report and are excluded from selected-throughput
totals to avoid ambiguous capacity claims. Unmatched selected IDs now also
become review-gated operator-review and Cadence import rows so adapter queues
can resolve selected contact identity mismatches without reading report
metadata by hand. Terminal or approval-rejected downlinks remain audited
through ignored-contact fields but contribute zero available or selected
capacity. Declared station capacity fractions are validated against the same
unit-interval range used by contact filtering before capacity-adjusted
throughput rows are emitted. Link-capacity contact ingress now parses clean
numeric-string timing aliases, throughput/data-volume aliases, capacity
fractions, provider percentage aliases such as `capacity_percent`,
`station_capacity_percent`, and nested throughput/capacity/activity context
variants, and completion fractions before summary and reconciliation logic;
malformed numeric strings remain missing numeric evidence. Approval rejection
takes precedence in ignored
reason-count surfaces when a contact is both terminal and rejected. Station-row
ignored selected-contact reasons are derived from the selected handoff rows, so
realized or provider selected feedback cannot inherit candidate-row status by accident.
Those reason-count maps are lifted onto link-capacity operator-review rows and
Cadence import rows so adapter queues can route ignored terminal/rejected
capacity without unpacking `source_link_capacity`. `LinkCapacity.capabilities/0`
also advertises both ignored-contact and ignored-selected-contact reason-count
maps as first-class row semantics. When an approval policy is supplied,
link-capacity approval requirements preserve contact IDs, selected IDs,
duplicate IDs, ambiguous selected-contact IDs, and any declared downlink
requirement evidence in `activity_context`. Link-capacity rows also aggregate
schema-safe provider result labels, source contact/command success flags, feedback
confidence factors, source labels, command result, including top-level or
metadata-supplied JSON-style booleans and numeric-string factors, and applied
`station_calendar_directions` into the row, policy context, operator-review
row, and Cadence-import row. Provider reservation IDs, owners, statuses, and
match statuses are likewise aggregated into those link-capacity handoffs and
row-derived top-level routing summaries as identity evidence. Compact
`link_capacity_summary.v1` handoffs also preserve station-calendar provider and
provider-entry ID maps by ground station, and schema validation cross-checks the
top-level provider ID lists against those maps before downstream replay trusts
the compact handoff. None of this treats feedback, station-calendar capacity
context, or reservation context as a
link-budget model, provider reservation write, or schedule mutation.
Executable validation checks report-level `model_limits` against
`OrbitalDynamics.Communications.LinkCapacity.capabilities/0`, keeping saved
artifacts aligned with the producer's declared fixed-rate summary boundary.
Executable validation treats link-capacity contact/selection/actual-throughput
cardinality fields as integer counts, cross-checks count fields against their
corresponding contact-ID lists on report and station rows, and leaves
throughput and utilization fields numeric, matching the exported JSON Schema.
Planned and realized data-volume aliases such as `planned_data_volume_mb`,
`estimated_data_volume_mb`, and `actual_data_volume_mb` are accepted as
capacity evidence at this artifact boundary so timeline-feedback handoffs do
not need to be rewritten into link-budget-specific field names before review.
