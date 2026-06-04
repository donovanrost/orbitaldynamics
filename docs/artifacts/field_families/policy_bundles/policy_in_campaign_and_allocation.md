# Policy in Campaign and Allocation Artifacts

## Campaign Plan and Contact Allocation

`campaign_plan.v1` exports nested activity, candidate-activity, ranked-timeline,
proposed-contact, and contact-intent schemas. Activity rows include stable
activity, scenario, subject, and source-window IDs plus score terms and
source-window metadata; proposed-contact rows add Cadence import identifiers,
direction, throughput, and station availability fields. Campaign, repair, and
candidate-refresh warning arrays are typed as strings.
`contact_allocation_report.v1` exports its embedded station-calendar,
contact-filter, contact-contention, and contention-resolution reports with
formal nested properties, so downstream import tools can inspect reservation,
suppression, and contention rows without treating those artifacts as opaque
objects. The embedded report schemas also expose the checked-in
`model_limits` arrays and contact-contention `provenance` object used by
allocation fixtures, keeping subreport boundary and source evidence visible to
schema-driven import gates. Contact-allocation summaries canonicalize
provider-shaped station availability, overlap availability, and reservation
match-status tokens before deriving routing ID maps from existing report rows,
so summary consumers see the same status buckets as allocation, review, and
import handoffs.
Its nested `optimizer_contract.v1` schema also types selected/candidate activity
ID arrays, ranked scenario IDs, score-term keys, deterministic ordering,
preserved lineage fields, and known limits. Executable validation checks those
known limits against `OrbitalDynamics.Optimizer.capabilities/0`, so checked-in
optimizer contracts cannot silently drift from the runtime optimizer boundary,
and count fields must match the selected, candidate, and ranked ID arrays. The
exported JSON Schema also constrains optimizer known-limit arrays, ranking
comparison `model_limits`, and Pareto frontier `model_limits` as exact string
sets so import gates can detect capability-boundary drift without invoking the
Elixir validator. Pareto frontier row `objective_values`, branch-comparison row
`score_terms`, and V3 strategy branch `score_terms` are also exported and
validated as numeric maps rather than opaque objects.

## Link Capacity and Resource Projection Review

`link_capacity_report.v1` artifacts can be normalized into
`link_capacity_review` rows carrying ground-station contact counts,
selected-contact counts, fixed-rate throughput totals, capacity-adjusted
throughput totals, capacity-fraction bounds, optional approval-policy evidence,
source contact IDs, station-calendar entry/provider/provider-entry ID rollups,
duplicate/ambiguous selected-contact evidence, and invalid candidate or
selected downlink input evidence for operator cleanup. V1
campaign and V2 repair embedded link-capacity reports pass their approval policy
through to those rows, and V1 campaign plans plus V3 branch repair results now
expose them as top-level operator-review and Cadence import rows instead of
leaving them only in the embedded report. V3 branch repair rows also preserve
low `actual_completion_fraction` evidence through ground-network policy review,
operator-review packaging, and Cadence import handoff. V3 strategy rows preserve
`branch_id` with source
`campaign_strategy.branches.repair_result.link_capacity_report.rows`.
Standalone `resource_projection_report.v1` artifacts can be normalized into
`resource_projection_review` rows carrying per-spacecraft activity counts,
storage/downlink projections, margin fields, projected storage overflow and
downlink shortfall values, deterministic `resource_pressure_status` and
`resource_pressure_types` classifications, availability flags including
`spacecraft_available`, resource
source-quality labels, declared-vs-missing resource trust-boundary status,
warnings, invalid selected-activity input evidence, and the source projection
row. Cadence import manifest rows preserve the same trust-boundary status and
top-level `activity_type` aliases are accepted before projection so exported
timeline-style activity rows do not become false invalid selected-activity
inputs. Resource projection parses clean numeric-string summary fields,
activity timing aliases, storage/downlink/battery resource estimates, capacity
fractions, and completion fractions before roll-forward; malformed declared
resource-estimate strings are preserved as invalid selected-activity evidence
instead of being silently treated as zero-effect inputs.
Externally supplied negative `thermal_margin_c` values are classified as
planning-grade thermal resource pressure and preserved through projection rows,
policy context, operator-review rows, and Cadence-import rows without adding
thermal propagation.
Provider `capacity_percent` and `station_capacity_percent` aliases, including
aliases nested under throughput/capacity/activity context or source
station-calendar entry/overlap evidence, feed the same station-capacity
downlink projection instead of remaining review-only source metadata, with
out-of-range capacity fractions or percentage aliases preserved as invalid
selected-activity inputs before they can change roll-forward capacity.
Provider `source_window`, `metadata.source_window`, or
`activity_context.source_window` maps likewise derive contract-valid
`source_window_id` / `source_window_type` evidence for resource-flow rows,
first-pressure projection summaries, approval-policy context, operator-review
rows, and Cadence-import rows without turning the roll-forward into a provider
reconciliation model.
Malformed activity, scenario, spacecraft, station, target, or
source-window stable-ID values are now invalid selected-activity inputs with
schema-facing identity fields sanitized while the original source activity is
preserved for review/import cleanup. Selected activities that declare malformed
capacity fractions, malformed resource quantity strings, or negative storage,
throughput, or battery energy quantities are likewise preserved as invalid
selected-activity inputs before roll-forward, so bad provider estimates cannot
improve projected storage, downlink, or power state. Malformed external resource summaries with
invalid spacecraft identity, negative capacity or used quantities, or
out-of-range margins are now `invalid_resource_summary_input` rows with the
original source resource summary preserved for operator review and Cadence
import cleanup instead of being projected into resource state. When an approval
policy is supplied, invalid activity and invalid resource-summary rows carry
`approval_requirements`, `approval_rule_matches`, and `policy_decision.v1`
evidence through operator-review and Cadence-import handoffs. Executable
validation constrains invalid activity and invalid resource-summary
`review_status` values to `operator_review_required` in the shared nested
schemas so resource review/import queues cannot invent readiness labels.
Executable
validation cross-checks
`invalid_activity_input_count`, `valid_activity_count`, and
`invalid_activity_input_ids` against the `invalid_activity_inputs` rows so
resource-projection summaries cannot drift from their review evidence. It also
cross-checks `valid_resource_summary_count`,
`invalid_resource_summary_input_count`, and
`invalid_resource_summary_input_ids` against the invalid-summary rows, and
checks `input_resource_summary_count` and top-level `warnings` against the
emitted projected and invalid-summary rows. The exported resource-projection and
resource-filter schemas now put stable-ID patterns on those invalid activity and
resource-summary ID arrays to match executable validation.
invalid-input source activity context as first-class adapter context. V1 campaign
embedded projection reports now use the same typed
`resource_projection_review` and Cadence `review_resource_projection` surface
with campaign-source provenance. The report also carries
`resource_source_quality_counts` and
`resource_trust_boundary_status_counts` derived from the projection rows that
the summaries produced, and `ResourceProjection.capabilities/0` advertises both
row semantics so adapter queues can inspect source quality and trust evidence
without recounting nested rows. Executable validation checks report-level
`model_limits` against `ResourceProjection.capabilities/0`, keeping the
projection artifact tied to its thin externally supplied resource-summary
boundary. When projection rows include
`activity_resource_flow`, the review rows also flatten flow count, peak storage
overflow, peak downlink shortfall, peak battery overuse, and the first activity
that creates resource pressure so import queues can sort or route resource-pressure review without
unpacking the nested projection. That first-pressure context now includes
contact direction, ground station, station-calendar entry, provider ID,
provider-entry ID, and normalized `station_calendar_directions`, allowing
resource-pressure policy, review, and
import rows to route provider-calendar direction evidence without conflating it
with the requested contact direction. The same first-pressure context preserves
the effective reduced-capacity fraction and source-window identity/payload when
station-calendar capacity limited projected downlink relief. Flattened Cadence
`review_resource_projection` rows are treated as replayable resource-pressure
evidence for storage, downlink, battery, externally supplied negative thermal
margin, availability pressure, and resource-summary activity-type
suppression/incompatibility pressure even when they do not carry nested
`source_resource_projection` context; top-level source activity IDs remain
branch-event lineage for flattened rows. Flow rows also carry activity status,
approval status, and `resource_effect_status`; terminal or approval-rejected
activities remain audited with zero projected storage/downlink effect rather
than being counted as future resource demand or relief, and approval rejection
is preserved as the ignored reason even when the activity is also terminal.
Resource summaries that
declare `spacecraft_available: false` or `spacecraft_availability: false` are
projected as `spacecraft_unavailable` pressure rows: selected activity resource
effects are audited as ignored with zero storage/downlink effect, conservative
policy blocks the row through `review_resource_projection`, and operator-review
plus Cadence import rows preserve the spacecraft-availability evidence.
Provider-shaped
direction-`downlink` contact rows, including rows that use `station_id` instead
of `ground_station_id` or nested `station` / `ground_station` identity objects,
and provider-shaped station/time rows that omit explicit type or direction, are
projected as downlink relief through the same storage/downlink roll-forward
path as native downlinks and planned downlink contacts; command/uplink contacts
remain resource-neutral, and command-result rows without command type/direction
remain invalid review inputs. Supplying an approval policy also emits
row-level `approval_requirements` with `review_resource_projection` action
context for projected storage overflow, downlink shortfall, and battery-depletion pressure, plus
approval-rule matches and the embedded `policy_decision.v1`; those approval
requirements and rule matches are preserved on the normalized operator-review
and Cadence import rows as well as in the source projection row.
Executable validation treats resource-filter and resource-projection scalar
counts plus resource trust/source count maps as integer counts while preserving
margins, MB totals, timing, and utilization fields as numeric planning values.
It also cross-checks `resource_pressure_status`, `resource_pressure_types`, and
the first-pressure activity pointer against projected overflow/shortfall/battery
depletion fields, spacecraft-availability evidence, and `activity_resource_flow`, so hand-authored
or stale resource projection artifacts cannot route pressure review with
contradictory summary evidence.
Nested flow rows validate schema-visible contact direction and
`station_calendar_directions` evidence when supplied, and nested flow activity
IDs are unique when present, keeping first-pressure pointers
and per-activity roll-forward evidence unambiguous.

## Link Capacity Report

`link_capacity_report.v1` exports a nested row schema for ground-station
throughput summaries: station ID, contact and selected-contact counts,
effective and ignored contact counts,
estimated throughput totals, capacity-adjusted throughput totals derived from
declared station capacity fractions, optional capacity-fraction bounds, and
contact ID lists. Provider-shaped `throughput_model.estimated_throughput_mb`
and estimated-downlink/planned-throughput/data-rate aliases are normalized into those
same totals rather than only triggering downlink inference; selected realized
downlinks can likewise derive actual throughput from actual data-rate plus
duration evidence, with `actual_data_rate_throughput_derivations` preserving
the source contact, formula, rate, duration, and reconstructed MB total on the
report, station rows, operator-review rows, and Cadence-import rows. The same
nested throughput-model aliases are schema-visible through standalone
candidate, proposed-contact, and activity-context exports. When an approval policy is supplied, rows also carry
approval requirements, rule matches, and `policy_decision.v1` evidence for
reduced-capacity review boundaries. It remains a fixed-rate capacity summary,
not a link-budget model.
