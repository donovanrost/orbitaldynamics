# Timeline Feedback Report

`OrbitalDynamics.reconcile_timeline_feedback/2` builds
`timeline_feedback_report.v1` rows by comparing planned activity IDs with
`realized_activity.v1` feedback. Realized feedback accepts completed, executed,
partial, missed, failed, delayed, canceled/cancelled, and rejected provider
statuses. Provider-shaped rows whose `status` is a correlation state such as
`matched` and whose `realized_status` carries the execution outcome use
`realized_status` for feedback classification, status transitions, protection
decisions, operator review, and Cadence import while preserving the match state
as `feedback_status`. Realized rows can also derive terminal execution status
from normalized lifecycle-event tokens such as `record_completion` and
`record_failure`; lifecycle events that describe non-terminal states, such as
`start_execution`, stay reviewable as invalid realized feedback. The report embeds an
`operator_review_package.v1` with `realized_feedback` rows for completed,
variance, exception, missing-realization, and unplanned-realization review
cases, including typed planned-to-realized status transitions. When realized
feedback carries a provider timeline ID, the
`realized_activity_context` also includes a nested `timeline_identity`; the same
context, status-transition evidence, and planned timeline protection decision
are preserved into operator review and Cadence import rows. Timeline feedback
rows also lift station-calendar reduced-capacity context
(`capacity_fraction`, `capacity_fraction_min`, and `capacity_fraction_max`) from
declared fraction fields, provider percent aliases, nested model/context maps,
and source station-calendar entry/overlap evidence before preserving it through
operator review and Cadence import. Report-level
`status_counts`, feedback-kind, match-strategy,
Cadence-import-status, planned-protection, execution-uncertainty,
operational-feedback-exclusion, duplicate-feedback, and ambiguous-timeline
counters are validated against the emitted rows. The standalone JSON Schema also
exposes `model_limits`, operational-feedback provenance, and the nested Cadence
import manifest surface so feedback artifacts remain inspectable before review
or import handoff.
Those
feedback rows also preserve planned-versus-realized link-profile evidence
(`link_protocol`, `frequency_band`, `modulation`, `coding_scheme`,
`polarization`, and `data_rate_mbps`, with MB/s provider aliases converted to
Mbps), and contact feedback with a mismatched
link profile is routed through review-only variance handling instead of feeding
station-throughput or contact-success feedback automatically. Explicit realized
link-quality failures such as negative `link_margin_db`, lost `carrier_lock` or
`symbol_lock`, and low-margin/degraded/failure status aliases follow the same
review-only path. When those reviewed failures appear later as changed
downlink/contact timeline-diff rows, V3 strategy replay can now convert them
into branch-local contact-success pressure while preserving the RF metrics and
lock/status evidence on the derived event. Those
protection-decision payloads now expose a typed nested contract for stable
activity/timeline IDs, lifecycle status, lock/approval flags, timeline identity,
and the `mutable`/`preserve`/`review_change` decision categories. The report
can optionally accept a `timing_variance_threshold_s` reconciliation option;
when declared, rows publish `max_timing_delta_s`,
`timing_variance_threshold_s`, and `timing_variance_status`, and completed rows
that exceed the threshold are routed to variance review/import instead of
record-only completion.
Provider rows may also declare `feedback_weight` with an optional
`feedback_weight_source`; weighted rows preserve that evidence through
timeline-feedback, operator-review, and Cadence-import rows, and the derived
`operational_feedback` success/throughput/priority maps use deterministic
weighted averages instead of treating every provider row equally; additive
downlink-demand feedback is scaled by the same weight before branch-local
refresh consumes it. A zero feedback weight is accepted as explicit
no-confidence evidence and preserved on the row, but it is excluded from
weighted feedback aggregation, weighted-row counts, and feedback-weight source
summaries. Provider completion fractions, feedback weights, and
contact/command/observation/maneuver success factors are checked before those
feedback, review, or import artifacts are emitted. Clean unit-interval
success/completion factors and nonnegative feedback weights are accepted, while
out-of-range, negative, or malformed declarations are retained as invalid
realized-feedback sections on timeline-feedback, operator-review, and
Cadence-import rows instead of being clamped into derived operational feedback;
rows with invalid feedback weights are excluded from weighted operational
feedback until reviewed. Explicit valid realized success factors take
precedence over planned confidence factors when deriving operational feedback
from provider execution rows.
Clean provider numeric strings are accepted on planned and realized feedback
ingress for timing aliases, throughput/data-volume evidence, completion and
confidence factors, resource and pointing telemetry, maneuver vectors, and
execution-uncertainty scalars/vectors. Malformed optional numeric strings remain
missing evidence instead of being coerced into invalid numbers.
Planned or realized maneuver feedback may also declare
`execution_uncertainty`; timeline-feedback rows normalize the raw map into
`execution_uncertainty_status`, `timing_3sigma_s`, `delta_v_3sigma_km_s`,
`delta_v_3sigma_magnitude_km_s`, and `execution_uncertainty_source`, preserve
planned and realized variants inside their activity contexts, and carry the
selected declared context through the embedded operator-review package and
Cadence import manifest without implying command execution. Report-level
`execution_uncertainty_declared_count` and `execution_uncertainty_missing_count`
are derived from the emitted rows and executable validation rejects stale
summaries.
The report
also preserves planned timeline integrity evidence, including dependency
cycles, missing dependencies, dependency-order violations, and exclusivity
violations, so completed realized feedback cannot bypass
`review_timeline_integrity` just because the provider reported completion. The report
also preserves invalid planned activity inputs, including malformed planned
activity IDs, as `review_invalid_activity_input` feedback rows with
schema-stable synthetic review IDs, and malformed realized feedback handoffs
missing identity or shape, missing status, or unsupported provider status, as
`review_invalid_realized_feedback_input` rows with invalid-input reason and
source activity evidence, so malformed feedback inputs reach review/import
artifacts instead of raising before artifact generation. Unsupported provider
statuses are promoted to `unsupported_realized_status` on feedback, review, and
Cadence import rows, while missing status stays a distinct invalid-input reason,
so adapter queues can route them without unpacking the nested source payload.
Malformed realized rows that still identify a planned activity or timeline are
correlated back to that planned row before review, so operators see invalid
provider feedback against the intended activity rather than an unrelated
unplanned-realization row. Realized handoffs with malformed provider or
realized activity IDs are also preserved on that invalid-feedback path with
schema-stable synthetic review IDs and the original source feedback payload.
The report
also projects realized provider/source/adapter, external ID, schema contract,
trust boundary, source-quality label, received/ingested timestamps, and
provenance onto top-level timeline-feedback, operator-review, and
Cadence-import rows so import queues can filter provider handoffs without
unpacking nested realized context. Rows that
declare realized provider, adapter, or adapter-version metadata must also
declare `realized_trust_boundary` directly or through
`realized_provenance.trust_boundary`, matching the executable validation and
exported JSON Schema rule for external feedback provenance. The report also
embeds a `cadence_import_manifest.v1` with deterministic record/review
adapter rows for those feedback comparisons. This is also artifact-only: it
records feedback review/import rows but does not update the source schedule.
The upstream `realized_activity.v1` contract and `realized_state_snapshot.v1`
activity rows expose the same trust-boundary requirement in exported JSON Schema:
provider, adapter, adapter-version, or external ID context requires
`external_id` plus a direct `trust_boundary` or `provenance.trust_boundary`;
`realized_activity.v1` rows may also declare `source_quality`, `quality`, or
`quality_level`, which normalize to `realized_source_quality` in downstream
feedback, review, and import rows. Realized activity exports also type
actual data-rate and duration aliases such as `actual_data_rate_mbps`,
`actual_downlink_rate_mb_s`, `delivered_rate_mb_s`, `received_rate_mb_s`,
`actual_duration_s`, and `actual_contact_duration_s`, matching the telemetry
shape used to derive actual throughput for timeline feedback and branch-local
refresh. When timeline feedback derives throughput from rate and duration
instead of provider-supplied `actual_throughput_mb`, rows preserve an
`actual_data_rate_throughput_derivation` audit object with the rate unit,
duration, formula label, and derived megabytes.
`realized_state_snapshot.v1` executable validation also checks snapshot-level
`model_limits` against `CampaignPlanner.realized_state_snapshot_model_limits/0`,
so provider-feedback snapshots cannot silently drift from the planner's
artifact-only no-mutation boundary.
It also emits a normalized `operational_feedback` map for V3 strategy and
candidate-refresh handoff, deriving contact success, station throughput,
observation success, command success, maneuver success, and maneuver execution
uncertainty maps from the realized feedback rows, plus observation
target-priority overrides when provider feedback declares target priority and
station-specific downlink demand when partial/failed downlink feedback carries
required downlink evidence, so downstream planners do not have to reinterpret
provider status semantics. `OrbitalDynamics.timeline_operational_feedback/1`
accepts both string-keyed JSON artifacts and atom-keyed Elixir report maps for
that handoff. Downlink-demand feedback also carries
`downlink_demand_sources` keyed by the same station/default key, preserving the
timeline-feedback row or realized-activity source that produced the demand so
candidate refresh can annotate generated downlink completion evidence with
exact lineage. Malformed source entries are treated as invalid operational
feedback sections rather than partially applied source evidence.
Realized resource telemetry rows with spacecraft or scenario identity also
publish resource-margin and resource-availability override maps, with
conservative merging for repeated spacecraft snapshots, including battery
state-of-charge as a planning-grade power-margin alias and battery capacity /
energy-used evidence, so V3 can consume a timeline-feedback artifact as the
source of resource-pressure branch refresh.
The same telemetry is lifted onto typed timeline-feedback rows and carried
through the embedded operator-review package and Cadence import manifest:
spacecraft ID, fuel/power/storage/downlink margins, battery state-of-charge,
battery capacity and energy-used fields, spacecraft/payload/antenna availability,
degraded mode, mode label, and incompatible or suppressed activity type lists
remain top-level row fields. Top-level or metadata-supplied trimmed case-insensitive JSON-style
availability/degraded booleans normalize before row and operational-feedback
emission, and explicit `false` availability values are preserved instead of
being treated as absent feedback.
Standalone `realized_activity.v1` rows that declare provider, adapter,
adapter-version, or external-ID metadata must also declare `external_id` plus
either `trust_boundary` or `provenance.trust_boundary`; executable validation
and exported JSON Schema share that external-feedback boundary.
Thermal telemetry and planned thermal context use the same reusable
activity-context fields as operational timeline rows: thermal zone ID,
planned/measured temperature, operating bounds, derived margin, status, model,
source, and confidence. Timeline-feedback row reconciliation lifts those fields
to row-level evidence and preserves them in source/realized activity contexts
through operator-review and Cadence-import handoffs; this is still artifact
evidence, not thermal propagation or subsystem simulation.
Observation lighting and eclipse evidence follows the same feedback handoff:
planned and realized eclipse-overlap fraction/duration, lighting condition,
detail/model labels, and confidence are normalized into feedback rows, preserved
inside source/realized activity contexts, and lifted into operator-review and
Cadence-import rows for adapter routing without claiming penumbra or sensor
illumination fidelity.
Observation quality evidence follows the same artifact-only handoff: planned
and realized image/product quality score, quality status/source, cloud-cover
fraction, and blur score normalize from common provider aliases, emit
planned/realized/delta or match fields in `timeline_feedback_report.v1`, and
flow through operator-review and Cadence-import rows without claiming image
processing or sensor-product validation. When realized observation feedback has
no explicit success factor or result label, numeric realized image-quality
score also feeds the existing `operational_feedback.observation_success_rate`
handoff so branch-local candidate refresh can consume it through the same
reviewable feedback path as lower-level observation-success evidence. When a
standalone `candidate_refresh.v1` request supplies no explicit observation
success rate or image-quality score, target-keyed cloud-cover or blur feedback
and target catalog quality fields use a deterministic inverse-quality factor
for observation scoring while still preserving the original cloud/blur evidence
on refreshed observe candidates.
Branch-authored `observation_success_feedback` events accept the same
image/product quality score aliases and preserve quality status/source,
cloud-cover fraction, and blur score on the normalized branch event; when no
explicit `observation_success_factor` is supplied, the image-quality score is
used as that existing feedback factor with `feedback_source:
branch_event.image_quality_score`. Branch comparison, operator-review, and
Cadence-import strategy-tradeoff rows summarize that branch-event quality
evidence as minimum image-quality score, status/source lists, maximum
cloud-cover fraction, and maximum blur score for adapter routing. When that
branch is selected, the strategy-recommendation operator-review row and the
Cadence import row derived from that review package flatten the same
branch-event quality summary so adapter queues do not need to reopen
`source_recommendation.explanation`. The nested operator-review and Cadence
import row schemas declare those flattened fields, and executable validation
checks list shapes, count maps, stable branch IDs, and unit-interval quality
metrics.
The exported JSON Schema now declares those source and realized activity
contexts as reusable nested activity-context objects rather than opaque maps,
including stable identity, timeline identity, throughput/completion,
maneuver-uncertainty, observation-quality, and lighting/eclipsing fields.
Nested activity contexts accept lighting confidence as either the qualitative
sampled-eclipse label used by candidate/timeline rows or the numeric confidence
used by realized feedback handoffs.
Cadence import manifest rows expose the same schema for import, source,
realized, and replacement activity contexts so adapters can validate the known
handoff fields without unpacking opaque source-review payloads.
When feedback is derived, the report also emits
`operational_feedback_provenance` using the same source-list shape consumed by
V3 strategy artifacts, including source report status, feedback-kind, match
strategy, Cadence-import status, realized source-quality, planned-protection
decision counts, input keys, source-report count and row count, declared
feedback trust boundaries, and the
count of rows excluded from derived operational feedback because they require
identity review. Contact direction,
station, or source-window mismatches and observation target mismatches are kept
in timeline-feedback/operator-review/Cadence-import rows but marked review-only
for `operational_feedback`, preventing mismatched provider telemetry from
silently changing strategy feedback maps.
Executable validation enforces non-negative integer top-level counts and checks
`model_limits` against `OrbitalDynamics.TimelineFeedback.capabilities/0`, so
stale feedback boundary claims fail schema lint instead of drifting silently. It
also checks `status_counts` against the emitted row statuses plus planned,
realized, row, duplicate, and ambiguity totals against the emitted feedback
rows, matching the exported JSON Schema contract. It also emits and validates
row-derived `feedback_kind_counts`, `match_strategy_counts`,
`cadence_import_status_counts`, and `planned_protection_decision_counts`, so
V2/V3 repair and adapter queues can route realized feedback by operational kind,
match source, import readiness, and preservation decision without recounting or
reinterpreting rows.
When multiple realized provider rows match the same planned activity, the
report preserves all realized activity IDs and normalized realized rows on the
matched feedback row, increments duplicate-feedback counts, and routes the row
to operator review instead of silently dropping one provider record.
When a realized row only identifies a timeline ID that maps to multiple planned
activities, the report keeps the row `realized_only` with
`ambiguous_timeline_id` match strategy, preserves all possible planned activity
IDs and source rows, and routes it to ambiguity review instead of attaching it
to an arbitrary planned activity.
Feedback rows now carry command/contact semantics when the planned or realized
activity has that context: feedback kind, direction, ground station, source
window lineage, Cadence import status plus adapter external ID/contract when
declared, command success/result, command/contact/observation success factors
and factor sources, contact success/result, planned-versus-actual
throughput deltas, planned-versus-actual data-volume deltas, product/collection
identity, resource identity, payload/instrument IDs, pointing target/mode match
status and off-nadir/slew deltas, match strategy, planned and realized timeline IDs, planned
timeline identity, dependency/exclusivity stable-ID arrays, timeline-integrity
review evidence from the shared typed activity normalizer, realized activity
IDs, realized activity type, and planned
operator-action context. Feedback rows, embedded operator-review rows, and
Cadence import rows also preserve reusable source and realized activity-context
maps plus normalized source planned and realized activity objects. Realized
feedback rows now separately expose planned and realized direction, ground
station, and source-window IDs plus match-status fields; completed contact or
command feedback with an identity mismatch is review-gated instead of recorded
as a clean completion. Realized
activity contexts now include the provider planned-activity ID when supplied,
the reconciled planned activity ID when matched by timeline identity or activity
ID, the match strategy or ambiguity evidence, and provider/import provenance
fields such as source, provider, adapter, adapter version, external ID, schema
contract, trust boundary, received/ingested timestamps, provenance, product
identity, actual data volume, and
metadata. This lets adapters correlate provider feedback without reopening the
source schedule or provider payload.
The embedded operator-review package
and Cadence import manifest preserve that same feedback correlation context,
including planned timeline identity, dependency/exclusivity context, and
timeline-integrity review fields from the planned activity, plus
the planned item Cadence import ID, type, contract, preparation status, product
identity, and planned/actual data-volume comparison fields. When a
realized feedback row
declares `contact_success` or `command_success`, reconciliation preserves that
provider flag instead of inferring success only from status; operator-review
rows require review when a completed contact or command still carries an
explicit false success flag, or when a completed contact delivers less
throughput than the planned contact expected. Completed contact and command
rows with a partial `completed_fraction` also preserve that fraction as
`contact_success_factor` or `command_success_factor` evidence with
`realized_activity.completed_fraction` provenance before the row is handed to
operator review, Cadence import, or V3 operational-feedback calibration. The
timeline-feedback operational-feedback provenance also records per-field,
per-key trust boundaries for contributing rows, so V3 derived command/contact
feedback branches can carry the source trust boundary even when the report
mixes contact and command feedback from different operational queues.
The public timeline-feedback operational-feedback helper now applies the same
stable-ID guard to direct row-list inputs before deriving station, target,
spacecraft, maneuver, or command keys, and malformed provider-shaped realized
target/station/spacecraft/source-window/resource identities are preserved as
review-gated invalid feedback rows instead of leaking into calibration maps.
Planned dependency ordering,
exclusivity, or opt-in missing-dependency integrity issues are also routed to
`review_timeline_integrity` before a matched feedback row can become a
record-only completion. Feedback rows now also expose planned/realized/match
fields for target, resource, collection, product, payload, and instrument identity, and a
completed realized observation or product row with an identity mismatch is
review-gated as realized variance before Cadence import. Those rows also carry
`identity_match_status`, `identity_mismatch_fields`, and
`identity_mismatch_count`, preserved through operator-review and Cadence-import
manifests, so adapter queues can route variance reviews without scanning each
individual `*_match_status` field. Executable validation now enforces stable-ID
syntax for planned/realized feedback, review, and import identity fields,
matching the exported JSON Schema patterns instead of accepting arbitrary strings. Malformed `nil`,
boolean, object-without-ID, or non-stable string entries inside planned or
realized product-ID arrays are ignored before match classification so they do
not create phantom product mismatches, and absent or malformed optional
collection, payload, or instrument identity fields remain absent instead of
being stringified as IDs. Executed
contact, command, and
generic activity feedback records completion through the same review/import
surface as completed feedback, but completed or executed contacts and commands
whose planned activity lacks a Cadence import identity remain review-gated as
`prepare_cadence_import` and receive `blocked_missing_cadence_import` manifest
status rather than becoming record-only imports. Completed or executed feedback
for planned work already marked status- or approval-policy-blocked or rejected
also remains review-gated through `resolve_blocked_activity` or
`resolve_rejected_activity` instead of becoming a record-only completion.
Cancelled or rejected feedback
is treated
as status-specific exception review after provider status strings are trimmed,
case-normalized, and whitespace/hyphen separators are folded to underscores.
Completed command feedback with a terminal
provider result such as `rejected` is likewise treated as unsuccessful and
review-gated even when the status is `completed`; completed contact feedback
with a terminal provider `contact_result` such as `dropped` is treated the same
way and feeds contact-success operational feedback plus downlink-completion
gap derivation for V3 strategy handoff; list-valued, map-valued, or
comma-delimited mixed provider results are normalized with terminal failures
taking precedence.
Collection-latency branch derivation
uses the same provider-result precedence, so a `completed` downlink with a
failed provider result no longer satisfies latency recovery or blocks the
replacement contact, including when the failed contact is supplied through
array/object missed-downlink lineage such as `missed_downlink_activity_ids`;
the exported `strategy_branch.v1` and nested
`campaign_strategy.v3` branch event schemas expose the associated
`contact_result`, realized status, missed downlink ID, contact count,
downlink-volume, latency, downlink-demand and downlink-completion source
lineage, and combined-branch source lineage fields as typed optional
compatibility fields. Branch event `required_downlink_mb` and
target-priority feedback are bounded to non-negative planning values before
branch-local refresh uses them. Objective-satisfaction rows that derive
branch-local target or downlink refreshes preserve row scenario, station,
time-window, target geometry, candidate-window, spacecraft-selector, and direct
required/selected observation-count aliases on the generated branch events, so
refresh candidates remain scoped to the reviewed objective gap. Provider target
gap fields may be scalar IDs or inline target spec objects in `targets`,
`target_specs`, `required_targets`, `committed_targets`, `priority_targets`,
`uncovered_targets`, `unsatisfied_targets`, `missing_targets`,
`missed_targets`, or
`target_gap_targets`; inline specs carry target identity,
priority, geometry, and minimum elevation into the generated branch event even
when the mission-state target catalog omits that target. Mission-state target
objectives use the same inline target-spec selector aliases for branch-local
target coverage, target observation, target revisit, and priority-commitment
refreshes, including `target_specs`, `required_targets`, `committed_targets`,
and `priority_targets`. Mission-state objective rows canonicalize `type`,
`objective_type`, or `objective` tokens before branch derivation, so
provider-style casing, whitespace, hyphen, or atom variants such as
`target revisit` still emit executable `target_revisit` refresh branches, and
delivery-latency objective aliases such as `Max Delivery Latency` plus
`max_delivery_latency_s` emit executable collection-latency refresh branches. If
that row is a downlink-completion objective, provider contact-count aliases
such as `required_contact_count`, `expected_contact_count`, and required contact
ID lists determine the branch-local `required_contacts` value before candidate
refresh staging. If that row also carries required
downlink volume, the same provider result produces `downlink_demand_mb`
feedback for generated replacement contacts. Successful provider result aliases
such as `delivered` suppress status-only downlink gap and demand derivation,
matching the provider-result-before-status precedence used for contact success.
Timeline feedback and V3 strategy derivation normalize provider result aliases by
trimming whitespace, case-folding, folding whitespace-or-hyphen separators to
underscores, splitting comma-separated result tokens, and flattening list- or map-valued
provider result payloads; failure aliases win when mixed provider evidence
contains both success and failure tokens.
Operator-review rows and Cadence import manifest rows preserve that
`contact_result` alongside `command_result` and `observation_result`; list- and map-valued
provider results are flattened to deterministic comma-joined strings in derived
timeline-feedback rows, realized activity context, review rows, import rows, and
V3 review events so downstream adapter queues can distinguish provider contact,
command, maneuver, and observation outcomes from status-derived success without
violating artifact schemas.
Completed
non-command and non-contact activities with a partial `completed_fraction` are
also routed to realized-variance review before import. Observation feedback rows
that declare `completed_fraction` but no explicit observation success factor use
that fraction as artifact-level `observation_success_factor` evidence with
`realized_activity.completed_fraction` as the source label. Provider
`observation_result` aliases use the same normalized success/failure grammar as
contact, command, and maneuver results, so a completed observation with
`accepted, failed` becomes unsuccessful observation feedback and records
`realized_activity.observation_result` as the factor source; explicit provider
success factors still win. Maneuver feedback rows expose planned and realized
delta-v vectors, vector deltas, magnitude deltas, and match status; completed
maneuver feedback with a planned/realized delta-v mismatch is routed to
realized-variance review before Cadence import.
`realized_activity.v1` itself now types direction, flat station/target/spacecraft IDs,
provider-shaped `station`, `ground_station`, `target`, `spacecraft`, and `satellite` identity objects,
source-window ID, actual start/end timing, completion fraction, provider reason,
received/ingested timestamps, top-level `activity_type` as the realized
activity-kind alias for canonical `type`, declared pointing mode/target, boresight axis,
resource identity/source/trust/provenance/blocking dimension, fuel/power/storage/
downlink/battery margins, availability/degraded flags and activity suppression arrays,
collection/product/payload/instrument identity, planned/realized/estimated
data-volume fields, required downlink, delivery/latency fields,
off-nadir/slew angles, pointing error/status/model/source/confidence,
explicit attitude mode/target, roll/pitch/yaw, attitude
error/status/model/source/confidence, declared/measured thermal zone,
temperature, operating-bound, margin, status/model/source/confidence evidence,
lighting condition/detail/model/confidence and eclipse-overlap fraction/duration,
link protocol/band/modulation/coding/polarization, link margin and quality metrics,
planned and actual throughput,
command/contact/observation success fields,
command/contact/observation result aliases,
contact/command/observation/maneuver success-factor evidence, maneuver delta-v
vectors, execution-uncertainty maps and 3-sigma timing/delta-v fields, feedback
weights, provider-declared observation/product quality score/status/source,
cloud-cover fraction, blur score, provider/import provenance fields,
source/provenance, and metadata for
standalone execution feedback snapshots.
Executable validation rejects reversed actual execution intervals, negative
actual throughput/data-volume evidence, out-of-range completion fractions and
success factors, and malformed success-factor evidence before feedback rows
reach review/import surfaces; `timeline_feedback_report.v1` applies the same
non-negative actual-throughput and actual-data-volume checks to embedded
feedback rows and activity context, carries the same unit-interval checks for
completion and success-factor evidence, and the downstream operator-review and
Cadence-import contracts preserve those checks when review/import rows are
validated directly.
Provider-shaped realized activity rows that declare a provider or adapter must
also declare `external_id` and a `trust_boundary` either directly or in
provenance. Provider-shaped realized contact rows may use `station_id`;
timeline feedback normalizes that alias into canonical `ground_station_id`
report and context fields while preserving the original realized activity row.
Standalone `realized_activity.v1` rows can be replayed directly by V3 strategy
as branch-local contact, throughput, observation, command, or maneuver feedback,
and can be normalized through `OrbitalDynamics.operator_review_package/1` and
`OrbitalDynamics.cadence_import_manifest/2`; without planned activity context
they are reconciled as `realized_only` feedback and routed to
`review_unplanned_realization` / `review_realized_feedback` rows.
Standalone `realized_state_snapshot.v1` rows use the same replay and facade
paths by expanding their embedded activities into deterministic branch-local
feedback and realized-feedback review/import rows while preserving the snapshot
ID as the source artifact.
The exported JSON Schemas type realized activity rows, realized spacecraft-state
summary rows, and timeline-feedback rows with status, timing-delta, and
command/contact reconciliation fields.
