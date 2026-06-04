# Policy in Resource Artifacts

## Resource Filter Facade

The resource filter supports wildcard single-summary inputs, spacecraft-specific
summaries, and normalized policy thresholds. It parses clean numeric-string
resource summary values, policy thresholds, and candidate timing aliases before
availability and margin suppression; malformed numeric strings remain invalid
or missing evidence on the existing review paths. An ID-less summary remains a
wildcard fallback even when scoped summaries are present, while a single
spacecraft-specific summary stays scoped to matching spacecraft or scenario IDs.
Duplicate valid resource summaries for the same spacecraft or wildcard scope no
longer choose a hidden winner; matching candidates are review-gated with
`ambiguous_resource_summary`, `resource_summary_count`, source-quality/trust
status summaries, and the source summary rows preserved for operator-review and
Cadence-import handoff.
The filter remains a planning artifact only; it does not simulate subsystem
state or mutate schedules. Its
`resource_filter_report.v1` artifact emits a top-level `model_limits` array
copied from `OrbitalDynamics.ResourceFilter.capabilities/0` so import gates can
inspect those boundaries directly; executable validation checks the list
against the same capability metadata so stale subsystem-simulation or
schedule-mutation claims fail schema lint. The same capability metadata advertises row
semantics for resource availability suppression, margin-policy suppression,
source-quality/trust-boundary count maps, resource battery/mode evidence
preservation, station-context passthrough, and invalid candidate or summary
review rows. Malformed non-map candidate handoffs are
preserved as `invalid_candidate_input` suppressed rows with raw input evidence,
and malformed map candidates missing stable identity, carrying malformed
stable-ID candidate/scenario/spacecraft/station/target/source-window identity,
declaring out-of-range contact/command success factors, or missing a usable
activity kind are also review-gated with source candidate evidence instead of
clamping malformed feedback confidence into suppression, review, or import
rows. Schema-facing suppressed rows sanitize those identity fields and
station-calendar ID lists instead of creating phantom links. Both forms flow through
operator-review and Cadence-import handoff instead of crashing or being dropped
before resource checks. Downlink, tracking, command, uplink, and health-check
contact candidates are suppressed when the externally supplied summary declares
`antenna_available: false`, including direction-only command/uplink/health-check
station windows with station and time context, with command/uplink rows still
kept out of downlink-margin suppression. When approval policy is supplied, command/uplink
antenna suppressions use `command_review` requirements and health-check
suppressions use `health_check_review` requirements instead of ground-network
schedule-change requirements. It also emits resource source-quality counts and
declared-vs-missing trust-boundary status counts for the summaries that informed
the filter, while each suppressed row carries its own
`resource_trust_boundary_status`. Top-level `activity_type` is accepted as the
candidate kind alias before invalid-input classification, matching operational
timeline re-ingestion. Supplying an `approval_policy` classifies
resource suppressions with row-level
`approval_requirements`, `approval_rule_matches`, and `policy_decision.v1`
evidence, including payload/degraded-resource blockers and margin-pressure risk
classifications. Suppressed resource rows always carry a deterministic
`resource_blocking_dimension` (`fuel`, `payload`, `spacecraft_health`, `power`,
`storage`, `antenna`, `thermal`, or `downlink`) so review queues and Cadence import
adapters can group suppressions without requiring an approval-policy run.
Invalid resource-filter summary rows can carry the same
`approval_requirements`, `approval_rule_matches`, and `policy_decision.v1`
fields as suppressed candidate rows when an approval policy is supplied.
Suppressed downlink/contact rows also preserve schema-safe provider result
labels from scalar, list-valued, or map-valued provider payloads, source
contact/command success flags, feedback confidence factors,
command result, and source labels through the resource-filter row, approval-policy
activity context, operator-review row, and Cadence import row. This remains
evidence on an already resource-suppressed row;
feedback alone does not create a resource suppression or mutate schedules.
Externally supplied resource battery capacity, energy-used, state-of-charge,
thermal margin, activity-type suppression/incompatibility lists, and spacecraft mode
likewise stay attached to resource-filter rows and their
approval, review, contact-allocation, and import handoffs, so operators can see whether
an antenna or margin suppression came from a low-battery or degraded-mode
summary without treating that context as a simulated subsystem state.
Resource-filter kept candidates are also annotated with the matched
`source_resource_summary` and its source-quality, trust-boundary, battery, mode,
margin, and availability evidence, preserving the external planning context for
downstream allocation without changing the filter's deterministic keep/suppress
decision.
The filter can also apply `min_activity_thermal_margin_c` to externally supplied
`thermal_margin_c`, producing `thermal_margin_below_policy` rows with
`resource_blocking_dimension: thermal`. This remains artifact evidence only,
not thermal propagation or subsystem simulation.
V3 campaign strategy branch derivation treats prior
`thermal_margin_below_policy` rows as `thermal_margin_c` pressure events, copies
the resource-filter policy threshold into branch-local refresh, preserves the
thermal margin on branch resource summaries, and surfaces it in branch
comparison rows. Operational-feedback `resource_margin_overrides`, source
timeline-feedback reports, and realized resource-telemetry rows can also derive
thermal margin pressure from clean numeric-string `thermal_margin_c` values when
the branch-generation policy declares a thermal threshold.
When the suppressed candidate already carries station reservation context,
resource-filter rows preserve reservation identity, owner/status, and
`station_reservation_match_status` through the same approval, review, and import
handoffs. Resource-filter rows also flatten `station_calendar_entry_id` from
nested provider source evidence when needed while retaining the source calendar
entry and overlap payload for ordinary suppressions and invalid candidate-input
review rows.
Payload-unavailable and degraded-spacecraft suppressions apply to observations.
Antenna-unavailable suppressions apply to native contact-like rows, including
downlink, tracking, command, uplink, health-check, and direction-bearing
`planned_contact` or provider `contact` rows, while downlink-margin
suppressions apply only to downlink-shaped rows, including `station_id`-only
provider rows, nested `station` / `ground_station` identity objects, and
provider-shaped station/time rows that omit explicit type or direction.
Command/uplink contacts do not consume that downlink resource boundary, and
command-result rows without command type/direction remain invalid review inputs.
Those suppressions also emit resource risk indicators so policy decisions
explain both the matched authority rule and the underlying resource availability
condition while preserving suppressed-row spacecraft, scenario, station, target,
and direction scope for approval-rule matching and downstream
operator-review/Cadence-import handoff rows. Resource suppression approval
requirements retain station-calendar
ambiguity and reservation context when the suppressed contact came from a
station-calendar-annotated candidate. V1 campaign and candidate-refresh
artifacts pass their
approval policy into embedded resource-filter reports so suppression evidence is
consistent across standalone and planner-generated artifacts. Standalone

## Resource Projection Report

`resource_projection_report.v1` exports a nested row schema for per-spacecraft
projection summaries: spacecraft ID, activity/observation/downlink counts,
effective/ignored activity counts plus ignored activity IDs,
estimated storage produced and downlinked, optional storage/downlink margins,
explicit projected storage overflow and downlink shortfall values, fuel/power
margins, externally supplied battery capacity/used/state-of-charge fields,
projected battery used/state-of-charge/overuse fields, resource-pressure
status/type classifications, resource source quality, warnings, first
resource-pressure activity fields, and optional `activity_resource_flow` rows
with typed station-calendar entry/provider/provider-entry identity.
Margin and state-of-charge fields are bounded to the unit interval, and
capacity/used/overflow/shortfall/overuse quantities are non-negative in both
the runtime validator and exported JSON Schema.
The first-pressure fields identify the earliest activity that creates storage
overflow, downlink shortfall, or battery-depletion pressure without requiring
consumers to scan the nested flow. The flow rows order matched activities by
schedule time and stable ID, then expose per-activity storage produced, planned
downlink capacity, storage-limited downlinked volume, unused downlink capacity,
storage delta, storage used before/after, running downlink used, margin-after
values, overflow, shortfall, declared battery energy consumed/generated,
projected battery state-of-charge after each activity, battery overuse, and
optional planned/actual data-volume plus completion-fraction evidence,
including provider-style delivered/received
actual-volume aliases. Explicit `completed_fraction` values and completion
aliases on flow rows must be clean unit-interval evidence; out-of-range
declarations become invalid activity inputs for review/import instead of being
clamped into flow evidence, while actual/planned data-volume completion remains
an unconstrained ratio so over-delivery can stay visible. Realized data-volume evidence is audit context
only; it does not reconcile projected storage or downlink state. Downlinked volume comes from native `downlink`
rows, `planned_contact` rows with `direction: downlink`, and inferred
provider-shaped downlink station/time rows; command, uplink, and tracking
contacts do not create storage relief. Downlink throughput can come from
top-level estimated-throughput/downlink fields, metadata aliases, nested
`throughput_model` estimates, or explicit capacity-adjusted throughput evidence.
When planned downlink
capacity exceeds stored data available at that point in the roll-forward, the
report preserves the planned capacity as demand while limiting storage relief
and exposing the unused capacity as a warning.
It uses capacity-adjusted contact throughput when station-calendar capacity
fractions are present, so reduced-capacity contacts do not over-credit storage
relief.
When an approval policy is supplied, rows with projected storage overflow,
downlink shortfall, or battery depletion also carry `approval_status`, typed
`approval_requirements`, `approval_rule_matches`, and an embedded
`policy_decision.v1`; approval requirement context includes the first pressure
activity fields, and the conservative operations bundle treats those pressure
risks as blocked planning boundaries. Battery projection is still planning-grade:
it only consumes explicitly declared activity energy estimates and does not
model spacecraft power generation, loads, thermal state, or battery health.
V3 branch evaluation also promotes projected storage overflow, downlink
shortfall, battery depletion, externally supplied negative thermal margin
pressure, and resource-summary activity-type suppression/incompatibility
pressure into branch-level risk indicators with first-pressure direction,
ground-station, station-calendar entry, and station-calendar
provider/provider-entry identity where present, and station-calendar directions,
allowing strategy approval policy and recommendation selection to act on nested
resource projection pressure.
Station-derived branch risks preserve canonical `ground_station_id` evidence,
including provider-shaped `station_id` inputs and nested `station` /
`ground_station` identity objects, so station-scoped policy rules can classify
generated branch risks without crossing stations.
Branch-comparison rows also flatten projected power margin, battery overuse,
storage-limited downlinked volume, unused downlink capacity, first-pressure
direction, ground-station, station-calendar entry, station-calendar directions,
provider-calendar identity, and peak unused capacity from nested
resource-projection flow rows so branch
review can distinguish data pressure from over-scheduled downlink capacity and
route station-calendar-specific pressure.
Downlink-completion branch derivation uses the same contact-direction boundary
as the communications artifacts: native `downlink` rows, direction-`downlink`
`planned_contact` rows, and provider-shaped station/time rows that omit explicit
type or direction, including nested `station` / `ground_station` identity
objects, count toward planned contacts, MB totals, completion ratios, and staged
branch-local candidates after normalization; command/uplink planned contacts do
not satisfy downlink objectives.
`OrbitalDynamics.ResourceProjection` and the public
`OrbitalDynamics.resource_projection_report/3` facade expose the same thin
projection model for standalone selected-activity lists. The report remains a
planning artifact only; the roll-forward is deterministic arithmetic over
externally supplied summaries and selected activities, including
capacity-adjusted downlink transfer from station-calendar throughput metadata,
station-capacity annotations, provider percent aliases, or contact-allocation
`capacity_fraction` rows, not subsystem simulation, link budgeting, or schedule
execution. `ResourceProjection.flow_report/3` and
`OrbitalDynamics.resource_projection_flow_report/3` expose a compact
artifact-only summary over the same projection rows for selected-activity
storage/downlink/battery flow and pressure inspection, including spacecraft and
activity ID routing maps by resource-pressure type, preserving the same
no-schedule-mutation and no-subsystem-simulation boundary. A single
summary is treated as a wildcard only when it does not declare a spacecraft ID;
spacecraft-specific single-summary inputs stay scoped to matching spacecraft or
scenario IDs. Wildcard projection rows use the stable `all_spacecraft`
spacecraft ID so downstream contracts still have a non-null row identifier.
Invalid external summaries remain outside `projected_resources` as
`invalid_resource_summary_inputs` with stable review IDs, invalid reason, and
`source_resource_summary` evidence. Duplicate valid summaries for the same
spacecraft or wildcard scope follow that same invalid-summary review path before
projection arithmetic, preserving each competing source summary for operator
review and Cadence import rather than emitting competing projected resource rows
for the same scope. ID-less wildcard summaries mixed with scoped summaries are
also review-gated before projection, so a fleet-default fallback cannot double-count
activities or compete with spacecraft-specific state.

## Resource Filter Report

`resource_filter_report.v1` exports a nested suppressed-candidate schema for
resource summary filters: candidate ID/type/scenario, suppression reason,
resource blocking dimension, timing, optional source-window lineage, optional
station context, optional `review_status` constrained to
`operator_review_required`, and
duplicate-ID disambiguation metadata (`base_candidate_id` plus collision index
and count) when multiple suppressed candidates share the same source ID. The
report can also carry resource source-quality counts and declared-vs-missing
trust-boundary status counts for the summaries that informed the filter, plus
row-derived `suppressed_resource_source_quality_counts` and
`suppressed_resource_trust_boundary_status_counts` for the emitted suppression
rows. Invalid external summaries remain outside suppression decisions as
`invalid_resource_summary_inputs` with stable review IDs, invalid reason, and
`source_resource_summary` evidence; their `review_status` is constrained to
`operator_review_required` by executable validation and exported JSON Schema.
`contact_filter_report.v1` validates scalar summary counts, station-reservation
match-status count maps, station-calendar trust-boundary count maps, and
suppressed-row station/duplicate counts as integers to match its exported schema
and keep adapter queue totals discrete.
Suppressed contact rows preserve station-calendar provider ID, provider entry
ID, direction scope, status, and source calendar entry evidence when branch-local
candidate refreshes overlay `station_calendar_provider.v1` inputs into the
generated `ground_network`. Provider-normalized station-calendar entries take
precedence over same-ID direct calendar rows across direct, mission-state, and
accepted-planning-state refresh inputs, preventing duplicate provider/direct
handoffs from becoming false ambiguous station states.
Executable validation cross-checks contact/resource suppressed-candidate totals
against the emitted suppressed rows, resource invalid-candidate counts/IDs and
invalid-summary counts/IDs plus suppressed-row count maps against the emitted
resource suppression rows, reservation match-status counts against emitted
contact suppression rows, and
reservation-overlap counts against reservation ID lists when reservation context
is present.
Suppressed-row contact and command success factors use the same unit-interval
contract as downstream policy, review, and import confidence evidence.
