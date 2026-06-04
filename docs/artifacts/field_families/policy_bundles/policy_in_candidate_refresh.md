# Policy in Candidate Refresh

## Candidate Refresh

`candidate_refresh.v1` exports a nested source-window lineage schema that ties
each refreshed candidate activity back to its source window ID, window type, and
scenario ID. Candidate-diff review/import rows consume that lineage for paired
replacement candidates and preserve the compact nested source-window evidence
beside the invalidated candidate diff.
Newly generated candidate-refresh artifacts also include a top-level
`model_limits` array copied from `OrbitalDynamics.CandidateRefresh.capabilities/0`,
covering the precomputed-event, sampled-window, thin resource/contact filter,
and artifact-only schedule-mutation limits. The exported JSON Schema constrains
that top-level array as the same exact candidate-refresh model-limit set.
It also exports nested candidate-activity rows with stable candidate, scenario,
target, ground-station, and source-window IDs plus score terms and source-window
metadata for generated observation and downlink opportunities.
Generated downlink candidate rows now expose declared station capacity,
station-throughput feedback factors, contact-success factors with source
labels, station-calendar direction evidence, flattened provider-calendar
provider/entry identity, and reservation-overlap metadata when present.
Candidate refresh accepts reduced-capacity station evidence from declared
fractions, `capacity_percent` / `station_capacity_percent` aliases, and nested
throughput/capacity/activity context before computing generated downlink
throughput and score terms.
Candidate-refresh requests also consume mission-state and accepted-state
fallback target catalogs, resource summaries, ground-network rows, and station
calendar providers when the explicit refresh request omits those top-level
inputs, keeping branch-local refresh generation tied to the current accepted
mission snapshot instead of requiring callers to duplicate every planning input
at the refresh boundary. Study-manifest `candidate_refresh` requests preserve
the optional `mission_state` object in executable refresh metadata as well, and
use `mission_state.spacecraft_states`, `mission_state.targets`, and
`mission_state.ground_stations` as run-input fallbacks when explicit accepted
planning state, refresh targets, or top-level ground stations are omitted.
Mission-state objective target selectors, including nested `target` objects,
can also provide fallback target geometry. Mission-state collection-latency and
downlink-completion objective selectors accept nested `collection`, `product`,
`data_product`, `products`, `payload`, and `instrument` objects before
branch-local refresh, and staged provider-shaped downlink candidates promote
those identities onto canonical `collection_id`, `product_id`, `product_ids`,
`payload_id`, and `instrument_id` fields for review/import routing.
When a provider objective supplies a broad product selector list, derived
collection-latency branch events use the product identity that intersects the
matched source observation as `product_id` and retain the full normalized
selector list in `product_ids`; objective-only downlink-completion branch
events omit singular data-identity fields for broad selector sets and retain
normalized plural selector sets such as `collection_ids`, `product_ids`,
`payload_ids`, and `instrument_ids`; `strategy_branch.v1` and nested
`campaign_strategy.v3` branch-event validation now check those plural fields as
stable-ID arrays, and the exported branch-event JSON Schema exposes the same
array contracts.
Provider-shaped
`mission_state.ground_network` entries with station geometry can provide
fallback ground-station definitions even when the corresponding mission-state
catalog arrays are present but empty, and explicitly empty manifest-level
refresh target or ground-station lists fall through to those mission-state
fallbacks for candidate-refresh runs.
File-backed and V2/V3-generated refresh runs therefore keep mission-state
objective, spacecraft, operational-feedback, and catalog fallback context
through `Manifest.from_map/1` before `CandidateRefresh.build/2` scores
candidates. Executable refresh metadata now also records
`candidate_refresh.run_input_sources`, and the emitted `candidate_refresh.v1`
artifact copies that map into `provenance.run_input_sources`, so import/review
tools can tell whether accepted planning state, target geometry, and
ground-station geometry came from explicit refresh fields, orbit-data adapters,
mission-state spacecraft states, mission-state target/objective catalogs, or
mission-state ground-network geometry. Candidate-refresh operator-review rows
and derived Cadence-import rows preserve that same run-input source map, and
Cadence import manifests also lift it into manifest provenance, so review queues
can route mission-state-derived refreshes without parsing the raw refresh
artifact.
Candidate diffs compare those feedback, station-capacity, station-calendar
entry, and provider-calendar identity values for retained or semantically
matched contacts, so refresh handoff queues can see confidence or
provider-calendar changes even when candidate IDs are stable. Outage or maintenance
state remains the applied station availability when it overlaps reserved time,
while reservation IDs, owners, and statuses stay visible for review and import
audit. Branch-derived refresh inputs that already carry station-throughput
feedback as ground-network capacity are not multiplied by the same operational
feedback a second time.
For branch-derived refresh, mission-state `ground_stations` define canonical
station geometry; `ground_network` geometry is only a fallback for station IDs
without a definition, so calendar entries do not silently override station
definitions when generating branch-local access windows.
When no resource summaries are supplied, candidate refresh still emits the
shared `resource_filter_report.v1` shape with model limits, policy, and empty
source-quality/trust-boundary counts instead of a reduced hand-built report.
Malformed explicit resource summaries, malformed resource-summary shapes, or
feedback-mutated summaries that violate unit-interval/non-negative resource
contracts are excluded from `candidate_refresh.v1.resource_summaries` and
preserved in the nested `resource_filter_report.invalid_resource_summary_inputs`
review/import path instead of suppressing refreshed candidates from invalid
resource state.
Resource summaries synthesized from operational feedback preserve a declared
feedback `trust_boundary` when present and otherwise fall back to
`provenance.trust_boundary: operational_feedback`, so resource filter,
operator-review, Cadence-import, and projection reports can distinguish
feedback-sourced resource state from unknown-boundary summaries. Feedback
availability overrides can also supply `suppressed_activity_types` and
`incompatible_activity_types`, which candidate refresh normalizes through the
same `resource_summary.v1` facade before resource filtering. The public
`OrbitalDynamics.resource_summary_from_map!/1`,
`OrbitalDynamics.resource_summary_to_map/1`, and
`OrbitalDynamics.resource_summaries_to_maps/1` facades expose the same
planning-grade normalization and `resource_summary.v1` row conversion outside a
campaign or candidate-refresh run. Resource summaries normalize canonical and
alias spacecraft identities into stable string IDs and reject unstable IDs before
artifact serialization; they also preserve and validate unit-interval margins,
nested `spacecraft` / `satellite` identity aliases, non-negative resource
capacity/used fields, optional signed `thermal_margin_c`, and battery fields including `battery_capacity_wh`,
`battery_energy_used_wh`, and `battery_state_of_charge`; clean numeric-string quantities and margins normalize
to numeric artifact fields, and JSON-style availability/degraded booleans
normalize to typed boolean fields while malformed strings still fail the same
  validation path. Standalone summary normalization also accepts explicit
  `suppressed_activity_types` and `incompatible_activity_types` as atoms, typed
  maps, comma-separated strings, or string arrays and emits canonical string
  arrays for downstream resource filtering/projection. The standalone and nested
  `resource_summary.v1` JSON Schemas expose the same battery, thermal,
  availability, trust-boundary, activity-type constraint, and bounded margin
  fields as executable validation. When `power_margin` is absent, normalization derives that
planning-grade margin from battery state of charge without creating a subsystem
simulator. Resource-filter summaries that declare
`spacecraft_available: false` or `spacecraft_availability: false` now suppress
all candidates for that spacecraft with `spacecraft_unavailable` evidence,
`spacecraft_health` blocking dimension, and the same review/import handoff fields
used for payload, antenna, and margin suppressions. Candidate refresh preserves
that spacecraft-level availability signal from explicit `resource_summary.v1`
inputs and from `operational_feedback.resource_availability_overrides`, including
trimmed case-insensitive `"false"` spacecraft-availability strings, so
refresh-local summaries and V3 branch-generated resource overlays do not degrade
whole-spacecraft outages into separate payload or antenna suppressions.
Observation candidate rows preserve the existing coarse `lighting_condition`
while adding sampled eclipse-overlap fraction, lighting-detail band, detail
model, and confidence fields. These lighting fields use a schema-visible enum
vocabulary in standalone `candidate_activity.v1` and embedded
candidate-refresh rows, so downstream import/review code can reject unsupported
labels instead of treating them as opaque strings. Standalone refresh requests can also apply
`operational_feedback.observation_success_rate` and
`operational_feedback.target_priority_overrides` to generated observation
scores; branch-derived refresh inputs that already encode observation-success
feedback on target rows expose that evidence without multiplying it a second
time. Branch-authored observation-success feedback can also be declared through
image/product quality score aliases, which normalize to the same branch-local
observation-success feedback factor while preserving quality status/source,
cloud-cover, and blur evidence on the branch event and summarizing those
quality fields onto strategy branch-comparison and selected-recommendation
review/import rows. These remain planning tags derived from sampled cylindrical eclipse
overlap, not a penumbra or sensor illumination model.
Standalone refresh requests can also apply
`operational_feedback.downlink_demand_mb` and explicit downlink-completion or
collection-latency objectives to generated downlink rows. When operational
feedback and matching objectives both contribute demand, candidate refresh adds
the declared volumes instead of letting one source shadow the other, while the
`downlink_completion_source` records the aggregate source category and
`downlink_completion_sources` preserves the exact contributing source strings.
Candidate refresh records required downlink demand, candidate throughput,
completion ratio, shortfall, requirement status, and source evidence on the
downlink row, throughput model, and activity context, and adds a deterministic
`downlink_completion_value` score term so candidate-budget selection can prefer
the downlink opportunity when current demand makes it more valuable than a
higher nominal observation score.
Multiple matching explicit downlink-completion objectives for the same station
are accumulated before scoring, so separate data-volume gaps do not disappear
because of objective order. Objectives scoped by `spacecraft_id`,
`satellite_id`, `scenario_id`, nested `spacecraft` / `satellite` selector
identity, or nested `station` / `ground_station` identity objects apply only to
matching generated downlink candidates, so a shared ground station does not
spread one spacecraft's demand to every contact at that station.
V3 branch-generated refresh applies the same demand path for
`downlink_completion_gap` events that carry `required_downlink_mb`, translating
the gap into branch-local `downlink_demand_mb` feedback before candidate
generation so refreshed branch downlinks retain requirement and shortfall
evidence, including resource-projection pressure source lineage and station
identity plus required/planned volume evidence from matching flow rows when
supplied, with report-level provenance trust boundaries inherited onto derived
pressure events when row-level trust is absent. When branch events carry `downlink_completion_source` or exact
`downlink_completion_sources`, or a derived `downlink_demand_feedback` event
carries `downlink_demand_sources`, those strings are copied into branch-local
`operational_feedback.downlink_demand_sources` so refreshed downlink rows,
throughput models, and activity contexts retain the source lineage from the
provider row that triggered the refresh. When a branch contains multiple
independent volume gaps for the same station, their required downlink demand is
accumulated before refresh generation instead of being overwritten by event
order.

## Candidate Refresh Operational Feedback

When standalone operational feedback changes generated candidate scoring or
filtering, `candidate_refresh.v1.provenance.operational_feedback` records the
feedback input keys and classifies the feedback trust boundary as `declared` or
`missing`, and valid non-empty feedback is also emitted as top-level
`candidate_refresh.v1.operational_feedback` for downstream strategy/review
handoff without parsing provenance. Candidate-refresh requests may also supply a
ready `source_timeline_feedback_report` or `timeline_feedback_report` directly
at the top level, mission-state level, or accepted-planning-state level, or
inside `source_result_artifact` / `result_artifact` wrappers at those same
levels; refresh generation derives the same contact-success,
station-throughput, target, command/maneuver, resource, and downlink-demand
feedback maps from the report rows before applying explicit
`operational_feedback`, so callers do not need to hand-copy
`timeline_feedback_report.v1.operational_feedback` into the request. Standalone
and V3 branch-generated refresh requests use the same typed source-report path
for mission-state timeline-feedback and operational-timeline reports, allowing
branch candidate-source provenance to retain report paths and row counts even
when strategy-level operational feedback has already been flattened.
Operational-timeline dependency/exclusivity integrity issue rows are preserved
as CandidateRefresh warning and provenance counts, so refresh artifacts keep
review pressure visible even when the integrity rows do not change candidate
scores directly. V3
branch-generated refresh requests also carry wrapper-discovered mission-state
source reports for candidate-diff, freshness, refresh-budget, timeline-diff,
resource reports, and communications reports, including canonical and
`source_*_report` result-artifact wrapper keys, through
`candidate_refresh.mission_state`, keeping live result-artifact bundles visible
to CandidateRefresh source-report provenance without requiring callers to
duplicate those reports at the mission-state top level or accidentally duplicate
objective/constraint pressure as raw refresh objectives. Standalone
refresh requests can also provide `source_timeline_diff_report` or
`timeline_diff_report` directly, or inside the same result-artifact wrappers;
removed downlink rows with station identity and required-downlink evidence are
replayed as station-scoped downlink-demand feedback with source timeline ID,
source activity ID, required operator action, report path, and trust-boundary
provenance preserved; removed observation rows with target identity are replayed
as target-revisit objectives so the existing observation scoring path can
recover missed target work without a hand-authored objective; changed downlink
rows with explicit shortfall or required-vs-planned volume evidence replay the
shortfall as station-scoped downlink-demand feedback while preserving
source/replacement activity IDs, changed fields, timing, and volume evidence;
changed contact rows with failed result/status or degraded replacement
success-factor evidence replay station-scoped contact-success feedback; changed
observation rows with failed result/status or degraded replacement
success-factor evidence replay target-revisit objectives for the affected
target; changed command rows with failed result/status or degraded replacement
success-factor evidence replay command-key-scoped command-success feedback for
downstream strategy and review handoff. The same timeline-diff replay works
after transition-application and review/import handoff:
`timeline_transition_application_report.v1` application rows,
`operator_review_package.v1` timeline-diff review rows, and
`cadence_import_manifest.v1` review-timeline-diff rows are normalized back into
branch-local refresh evidence through their embedded
`source_timeline_diff` payloads.
Standalone
refresh also accepts wrapper-level `operational_feedback` maps as a
lower-priority replay source, recording source paths, input keys, and wrapper
trust-boundary summaries plus per-field/key trust-boundary routing before
explicit request feedback takes final precedence. When an embedded report lacks
its own trust-boundary evidence, the
wrapper provenance or metadata can supply it for the derived feedback and
source provenance. The feedback provenance records the source report paths, row
counts, input keys, status/count maps, and trust-boundary summary used for that
derivation while keeping explicit request feedback as the final override layer.
Candidate-refresh provenance also records supplied source
`candidate_diff_report.v1`, `freshness_report.v1`, and
`refresh_budget_report.v1` inputs from top-level, accepted-state, or
mission-state refresh request locations. Those audit summaries preserve source
paths, report counts, row/status totals, kept/dropped candidate counts, and
trust boundaries without treating the reports as candidate-selection commands.
Candidate-refresh manifest inputs may supply
`operational_feedback.realized_activities` directly; those rows share the
provider-shaped `target`, `station`, `ground_station`, `spacecraft`, and `satellite` identity objects from
`realized_activity.v1` and are reconciled into ordinary station, target, and
downlink-demand feedback maps during refresh generation, with provenance marking
the derivation, timeline-feedback contract/row-count identity and trust-boundary
summary, realized-row count, positive weighted-row count, and
feedback-weight source labels, per-field/key feedback trust-boundary maps, and
realized source-quality, row-status, feedback-kind, match-strategy,
Cadence-import-status, protection-decision, execution-uncertainty declared/
missing, and operational-feedback exclusion counts from the timeline-feedback
handoff. Malformed
provider-shaped realized row identities, invalid unit-interval realized telemetry such as
`completed_fraction`, image-quality score, cloud-cover fraction, or blur score,
zero realized feedback weights, and negative or malformed realized feedback
weights are excluded from the effective refresh feedback; invalid weights are
retained as invalid operational-feedback sections in the same provenance before
the timeline-feedback handoff can turn those values into scoring inputs, so
review/import warning rows carry both the
provenance and replayable `source_operational_feedback` map for the rejected
realized feedback. Candidate-refresh requests also replay standalone
`source_realized_activity`, `realized_activity`, `source_realized_activities`,
`realized_activities`, `source_realized_state_snapshot`,
`realized_state_snapshot`, `source_realized_state`, and `realized_state` rows
from root, accepted-planning-state, mission-state, and result-artifact wrapper
inputs through the same realized feedback handoff, preserving source paths and
inherited snapshot or wrapper trust boundaries in operational-feedback provenance.
Operator-review-package `realized_feedback` rows and Cadence-import
`review_realized_feedback` / `record_realized_feedback` rows also replay through
that CandidateRefresh handoff, including nested
`source_review_row.source_feedback` rows, so reviewed execution evidence can
become refresh input without pre-flattening. Repair and strategy candidate-source
summaries preserve the refresh feedback input keys, trust-boundary status, and
nested source operational-feedback provenance so downstream review packages can
see that a candidate set was feedback-driven. Missing feedback trust boundaries
also produce an artifact warning because those values can change candidate scores.
Malformed non-object
`operational_feedback` inputs are preserved as invalid feedback provenance and
warning review/import rows instead of raising during candidate generation;
out-of-range unit-interval success, quality, and throughput feedback factors are
removed from effective feedback maps and preserved as invalid feedback sections
instead of being clamped into candidate scoring;
malformed nested maneuver-execution-uncertainty, resource-margin, or
resource-availability feedback sections are dropped from filtering and preserved
in the same invalid feedback provenance. Operational-feedback map keys that
represent station, target, activity, or spacecraft IDs must also satisfy the
stable-ID shape; invalid keys are removed from effective feedback maps and
reported as invalid feedback sections in provenance instead of driving candidate
scoring, filtering, or branch refresh.
At the strategy layer, malformed explicit request `operational_feedback` is
ignored for branch scoring but retained in `operational_feedback_provenance` as
invalid request feedback evidence; malformed nested resource-margin or
resource-availability sections are dropped from scoring and preserved in the
same provenance as invalid feedback sections, negative or malformed
downlink-demand and target-priority map entries are excluded from effective
request feedback, and the same stable-ID key guard applies before explicit
request feedback can affect branch scoring.
Operator-review and Cadence-import replay rows use the same unit-interval guard
for reviewed contact, observation, command, maneuver, and quality feedback
factors, preserving invalid row factors as operational-feedback provenance
instead of clamping them into derived strategy branches.
Operator-review and Cadence import warning rows preserve the same operational
feedback trust-boundary status, trust boundary, input keys, and source
provenance so downstream review queues can route the warning without parsing
warning text.
It also exports nested invalidated-candidate rows so stale prior opportunities

## Refreshed Contact Intents and Resource Summaries

carry stable candidate IDs, invalidation reasons, replacement IDs when matched,
source-window IDs, and semantic change reasons.
Refreshed `contact_intents` and `resource_summaries` are exported with nested
row schemas matching their standalone contracts. When a refresh approval policy
is supplied, contact intents carry the same approval requirements,
approval-rule matches, and `policy_decision.v1` evidence as standalone
`ContactIntent.from_activities/2` output. V3 strategy-generated branch refresh
requests keep an explicit strategy approval policy attached to the generated
refresh input, so branch-local contact-intent evidence carries the same policy
bundle and rule context as the parent strategy review. V2 repair-generated
refresh requests likewise inherit an explicit repair approval policy unless the
nested refresh request declares its own policy, keeping generated repair
contact-intent evidence tied to the repair authority bundle. They also inherit
the normalized repair mission-state snapshot when the executable refresh request
omits its own mission-state fallback inputs, so repair-generated candidates can
use the same accepted-state target catalogs and resource summaries without
duplicating them inside the refresh request. Resource summaries
include declared or provenance-inferred resource source quality and preserve
declared or provenance-supplied trust boundaries as schema-visible
`trust_boundary` fields. Resource projection rows also expose boolean
`payload_available` and `antenna_available` flags from checked-in projection
fixtures. Resource-summary map inputs accept the struct-style
`payload_available?`, `antenna_available?`, and `degraded?` aliases but still
export canonical JSON fields; `downlink_capacity_margin` likewise feeds the
canonical `downlink_margin` field, and flattened handoff aliases
`resource_source_quality` and `resource_trust_boundary` feed the canonical
`source_quality` and `trust_boundary` fields. Resource filter and projection reports
preserve the same resource trust boundary and provenance on
suppressed-candidate, projection, approval-context, operator-review, and
Cadence import rows.

## Candidate Diff, Freshness, and Refresh Budget Reports

`candidate_diff_report.v1`, `candidate_diff_row.v1`, and
`freshness_report.v1` are exported as standalone executable contracts in
addition to their embedded `candidate_refresh.v1` use. Candidate-diff
validation checks retained, new, invalidated, prior, and refreshed counts
against row arrays; the promoted row contract separately validates stable
candidate/source IDs, diff-reason vocabulary, semantic change reasons, and
budget-match evidence for focused regression fixtures. Invalid prior candidate
inputs are counted separately with stable synthetic IDs when needed, while still
flowing through invalidated-candidate review/import rows. Standalone
`candidate_diff_report.v1` artifacts may also carry `source_window_lineage`
rows. The executable contract validates each lineage row as
`source_window_lineage.v1`, cross-checks its candidate ID, source-window ID,
and scenario ID against the referenced retained/new/invalidated diff row, and
carries paired replacement source-window evidence into `candidate_diff_review`
and `review_candidate_diff` rows. Lineage and candidate-diff rows now preserve
the same scoped collection/product/payload/instrument identity, source activity
IDs, latency objective evidence, downlink demand quantities, and trust-boundary
feedback context carried by refreshed downlink candidates, including compact
nested `source_window` copies for lineage consumers. The checked-in
`study_results/candidate_diff_report_v1.json` fixture includes that optional
lineage shape plus source-target metadata on candidate-diff rows, so contract
consumers can lint the standalone handoff without a full candidate-refresh
wrapper. Standalone
`candidate_diff_report.v1` artifacts also emit `model_limits` copied from
`OrbitalDynamics.CandidateRefresh.capabilities/0`, so candidate-refresh
handoff queues can inspect the artifact-only model boundary without resolving
the parent refresh artifact. Standalone
`candidate_diff_report.v1` artifacts can also be normalized directly through
`OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`, lifting invalidated candidates,
unpaired semantic or ambiguous new candidates, and retained semantic-change
rows into `candidate_diff_review` and `review_candidate_diff` gates without
requiring a full candidate-refresh wrapper; those review/import rows preserve
the same scoped downlink and collection context as row-level fields rather than
leaving it only inside nested `candidate_diff` evidence. When prior operator-review packages
or Cadence import manifests replay candidate-diff replacement rows into V3
branch-local refresh, the replayed branch events and staged replacement
metadata preserve the same source-target metadata and target
latitude/longitude/minimum-elevation fields, target-priority evidence, scoped
collection/product/payload/instrument identity, source activity IDs, latency
objective evidence, downlink demand quantities, and trust-boundary context, and
strategic-addition approval contexts expose those fields for policy and review
routing. Replayed candidate-diff branch events also carry semantic-change
detail rows plus changed-field summaries so replacement approval can cite the
compared prior/refreshed values and route by changed field. Freshness
validation preserves the
current/stale/unknown status vocabulary for refresh trust gates, including
`unknown_reasons` so import gates can distinguish missing or invalid
accepted-state timing, horizon alignment, and state-quality evidence. Executable
validation now requires string reason entries and derives `status` from
`stale_reasons`/`unknown_reasons` using the same stale-before-unknown precedence
as candidate refresh generation.
`refresh_budget_report.v1` is also exported as a standalone executable contract
with input/kept/dropped counts, kept and dropped stable-ID arrays, the applied
selection order, optional `max_candidate_activities`, and assumptions that make
the post-filter budget stage explicit. The budget stage counts duplicate
candidate IDs by row occurrence, so selecting one duplicate ID does not hide
  other dropped rows with the same public candidate ID. Executable validation
  checks the input, kept, and dropped counts against the kept/dropped ID arrays so
  stale budget summaries cannot pass while preserving duplicate-ID row semantics.
  Candidate-diff and refresh-budget scalar counts, plus candidate-diff semantic
  and budget match count fields, are executable integer counts matching the
  exported JSON Schema rather than float-shaped numeric summaries.
  Standalone freshness timing and state-quality status fields export as typed
  number/string JSON Schema properties, matching executable validation and the
  embedded candidate-refresh freshness shape.
  Standalone `freshness_report.v1` and `refresh_budget_report.v1` artifacts can
  also emit `model_limits` copied from the same candidate-refresh capability
declaration, keeping refresh-trust and budget-gate imports explicit about their
sampled-window, thin-filter, and artifact-only boundaries. They can
also be normalized directly through `OrbitalDynamics.operator_review_package/1`
and `OrbitalDynamics.cadence_import_manifest/2`, producing the same
`freshness_review`/`review_refresh_freshness` and
`refresh_budget_review`/`review_refresh_budget` gates without requiring a full
candidate-refresh wrapper. The exported operator-review and Cadence-import row
schemas now reuse the nested `candidate_diff_report.v1`,
`freshness_report.v1`, and `refresh_budget_report.v1` schemas for those
`source_*` report fields instead of leaving them as opaque objects. The same
handoff schemas now expose permissive typed nested source-row contracts for
`source_contact_intent`, `source_operational_timeline`,
`source_timeline_diff`, `source_timeline_application`,
`source_timeline_transition_application`, and
`source_timeline_protection`; these keep partial source evidence valid while
publishing stable-ID, timeline identity, activity context, diff status,
transition-application, and protection-decision field types for adapters.
Strategy and scoring handoff fields use the same permissive nested-row approach
for `source_branch_comparison`, `source_ranking_comparison`,
`source_pareto_frontier`, `source_objective_satisfaction`,
`source_objective_tradeoff`, `source_score_term`, and `source_tradeoff`.
Resource, contact, and command handoff fields preserve source evidence for
`source_contact_allocation`, `source_contention_group`,
`source_contention_recommendation`, `source_command_window`,
`source_station_calendar_review`, `source_link_capacity`,
`source_resource_projection`, `source_resource_summary`,
`source_maneuver_review`, `source_contact_suppression`, and
`source_resource_suppression`. For review/import `source_*` snapshots, the
exported schemas intentionally keep partial source rows valid while still
publishing stable-ID hints and executable checks for known identity fields such
as activity, timeline, station, maneuver, provider, and calendar IDs.
