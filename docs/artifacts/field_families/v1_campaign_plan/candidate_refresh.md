# Candidate Refresh and Strategy Branch Derivation

Candidate refresh also passes its approval policy into embedded
`contact_filter_report.v1` and `resource_filter_report.v1` generation, keeping
suppression policy evidence consistent with the standalone filter artifacts.
Generated downlink candidates that consume ground-network capacity,
availability, or reservation overlays now preserve the station-calendar
trust-boundary status and source calendar evidence on the candidate row, so
score and throughput changes remain traceable even when the contact is not
suppressed.
Campaign strategy branch derivation also treats prior
`contact_filter_report.v1` suppressed downlink rows, including rows embedded in
prior `source_result_artifact` / `result_artifact` wrappers, as branch-local
`downlink_completion_gap` pressure. The generated branch carries the suppressed
contact identity, nested provider-shaped station identity, suppression reason,
station-calendar/reservation evidence, exact downlink demand/completion source
lineage, and declared or wrapper trust boundary into the candidate-refresh
feasibility metadata before any operator-approved replacement contact can be staged.
Prior `resource_filter_report.v1` suppressed rows, including rows embedded in
prior `source_result_artifact` / `result_artifact` wrappers, likewise become
branch-local resource pressure when the suppression reason maps to a resource
availability or margin. Availability suppressions such as payload, antenna, or
spacecraft unavailability generate resource-overlay summaries for the branch,
and margin suppressions preserve the reported margin value, source activity ID,
suppression reason, source quality, and declared or wrapper trust boundary for
branch comparison and downstream review.
Refresh-local `operational_feedback.resource_margin_overrides` and
`operational_feedback.resource_availability_overrides` are folded into
planning-grade `resource_summary.v1` rows before filtering, so explicit
resource-margin, payload, and antenna feedback can suppress generated
candidates without adding a subsystem simulator. The legacy
`operational_feedback.availability_overrides` alias is merged with the
canonical resource-availability map, with canonical keys winning on conflict,
so empty canonical maps do not mask adapter-supplied alias entries.
Source `resource_projection_report.v1` rows now feed that same
candidate-refresh resource-feedback path, including rows preserved in
operator-review packages and Cadence-import manifests. Replayed review/import
handoffs split projected resources from invalid projection activity or summary
inputs before branch-local refresh derivation, so invalid projection evidence is
preserved in source-report provenance and warnings without being treated as
resource feedback. Projected storage, downlink, and battery pressure is
normalized into schema-valid resource-margin overrides; top-level resource
projection pressure counts, pressure types, spacecraft ID sets, and
activity/spacecraft ID maps by pressure type are derived from the projected rows
so readiness and Cadence handoffs can route resource pressure without reopening
each flow row. Payload, antenna, spacecraft, or degraded availability fields
become availability overrides before the shared resource filter runs.
Prior `resource_filter_report.v1` suppressed rows also replay into the same
candidate-refresh resource-feedback path from direct source reports, wrapped
result artifacts, operator-review packages, and Cadence-import manifests, so
resource suppressions can affect regenerated candidates instead of remaining
review-only evidence. Replayed resource-filter review/import handoffs split
invalid resource-summary inputs from suppressed candidates first, so invalid
resource-state evidence is preserved in source-report provenance and warnings
without being treated as operational feedback.
Prior `contact_filter_report.v1` suppressed rows likewise replay into
candidate-refresh ground-network state from direct source reports, wrapped
result artifacts, operator-review packages, and Cadence-import manifests,
mapping unavailable, reserved, and zero-capacity station suppressions back onto
the shared contact-filter path before regenerated contacts are selected.
Prior result-artifact wrappers may use either canonical embedded report keys or
their adapter-facing `source_*_report` variants for resource-projection,
resource-filter, contact-filter, contact-allocation, contact-contention
resolution, link-capacity, and station-calendar replay; the chosen wrapper key
is preserved in feedback-source paths for audit. Standalone
`candidate_refresh.v1` builds follow the same wrapper rule for objective,
constraint, score, resource, link, allocation, contention, and filter source
reports, plus passive candidate-diff, freshness, and refresh-budget provenance
reports, including list-valued embedded report keys with indexed source paths
and inherited wrapper trust boundaries in `provenance.source_reports`.
When a result-artifact wrapper carries nested operator-review packages or
Cadence-import manifests, Candidate Refresh applies the same wrapper trust
boundary before reconstructing embedded source reports from those review/import
rows, so operational-feedback and pressure replay keep the containing bundle's
review boundary even when individual rows omit row-level trust.
The same canonical-or-`source_*_report` wrapper rule applies to prior
timeline-feedback, operational-timeline, command-window, and maneuver-review
reports that feed V3 operational feedback. Strategy provenance records the
selected wrapper path and inherited wrapper trust boundary before deriving
station-throughput, observation, command, maneuver-success, or maneuver
execution-uncertainty branches.
Prior `station_calendar_report.v1` affected-contact rows replay into the same
candidate-refresh ground-network state from direct source reports, wrapped
result artifacts, operator-review packages, and Cadence-import manifests.
Unavailable, reserved, and zero-capacity calendar rows become shared
contact-filter station intervals before regenerated contacts are selected while
preserving calendar-entry IDs, reservation owner/status metadata, source-review
payloads, source paths, provenance, and report or wrapper trust-boundary
evidence. Nested operator-review packages and Cadence-import manifests inside a
result-artifact wrapper inherit the wrapper trust boundary before those
station-calendar review rows are reconstructed, so suppression rows and
source-report provenance keep the same review boundary as the containing
bundle.
Prior `station_calendar_report.v1` provider-calendar contention groups replay
through that same path. Candidate refresh derives the blocking station state
from each group's source calendar entries, so reserved, unavailable, or
zero-capacity provider overlap groups can suppress regenerated contacts while
preserving source provider entries, provider IDs, provider-entry IDs,
reservation IDs, reservation owner/status lists, directions, provenance, and
trust-boundary evidence through the contact-filter report. The provider-specific
contention status and reservation evidence remain flattened on the generated
suppression row, so review/import consumers can distinguish provider-calendar
overlap evidence from ordinary reservation overlap suppression without reopening
nested source entries.
Prior `contact_intent.v1` rows with unavailable, reserved, or zero-capacity
station evidence replay into the same candidate-refresh ground-network path
from direct source intents, wrapped result artifacts, operator-review packages,
and Cadence-import manifests, preserving policy, reservation, timing, and
trust-boundary evidence before regenerated contacts are filtered. Result-artifact
wrappers pass their trust boundary into embedded contact-intent rows, including
rows recovered from nested operator-review packages and Cadence-import
manifests, when those rows do not declare row-level trust, so generated
suppression rows and source-report provenance keep the bundle's review
boundary. Candidate
refresh provenance now also summarizes those replayed contact-intent inputs
under `provenance.source_reports.contact_intent`, including source paths,
station feedback counts, station-calendar status counts, Cadence import status
counts, policy-classification counts, and trust-boundary status.
Prior `contact_contention_resolution_report.v1` deferred downlink
recommendations replay into candidate-refresh downlink-completion objectives
from direct source reports, wrapped result artifacts, operator-review packages,
and Cadence-import manifests, preserving selected/deferred contact,
source-window, selection-reason, policy, and trust-boundary evidence before
regenerated downlinks are scored.
Prior `contact_allocation_report.v1` deferred, blocked, or policy-blocked
downlink rows replay into candidate-refresh downlink-completion objectives from
direct source reports, wrapped result artifacts, operator-review packages, and
Cadence-import manifests, preserving station, contact, source-window, status,
policy, and trust-boundary evidence before regenerated downlinks are scored.
Prior `link_capacity_report.v1` selected or actual downlink shortfall rows
replay into candidate-refresh downlink-completion objectives from direct source
reports, wrapped result artifacts, operator-review packages, and Cadence-import
manifests, preserving station identity, source contacts/source windows, and
report or row trust-boundary evidence before regenerated downlinks are scored.
Rows with realized throughput evidence also derive branch-local
`operational_feedback.station_throughput_factor` from explicit completion
fractions or actual-versus-selected throughput, so regenerated contacts inherit
prior station throughput pressure instead of only demand shortfall.
Candidate-refresh provenance now summarizes behavior-driving
`timeline_feedback_report`, `operational_timeline_report`,
`timeline_diff_report`, `timeline_transition_application_report`,
`command_window_report`, `maneuver_review_report`, `constraint_report`, `objective_satisfaction_report`,
`objective_tradeoff_report`, `score_term_report`, `station_calendar_report`,
`contact_contention_resolution_report`, `contact_allocation_report`, and
`link_capacity_report` source inputs alongside the existing resource/contact
filter summaries, including source paths, row or recommendation counts,
status/reason/type counts, operational-feedback input keys, and declared trust
boundaries.
Battery state-of-charge feedback is treated as a planning-grade power-margin
alias when an explicit `power_margin` is absent, and `thermal_margin_c`
feedback is applied through the same refresh-local resource-margin override
path when thermal policy thresholds are declared, while battery capacity and
energy-used evidence remain available on resource summaries. Struct-style availability flags such as `payload_available?`,
`antenna_available?`, and `degraded?` are canonicalized to the JSON field names
before branch-refresh filtering, and caller-facing `downlink_capacity_margin`
is canonicalized to `downlink_margin`. Mode/degraded and spacecraft-unavailable
availability feedback is applied to the refresh-local resource summaries before
the shared resource filter runs, so standalone refresh can suppress degraded
payload work or spacecraft-wide unavailable activity without adding a subsystem
simulator.
Standalone candidate refresh also preserves `command_success_rate` and
`maneuver_success_rate` in operational-feedback provenance. Those fields do not
create new refresh candidates by themselves, but branch-generated refresh
artifacts retain the command/maneuver confidence context that V3 used to derive
the branch. Malformed scalar feedback entries for contact-success,
station-throughput, downlink-demand, or target-priority maps, plus negative
downlink-demand and target-priority values, are excluded from effective feedback
and preserved as invalid operational-feedback provenance, so the emitted
`candidate_refresh.v1` artifact stays schema-valid while adapters can still
review the rejected input values.
Contact-filter suppressed rows disambiguate duplicate suppressed candidate IDs
with deterministic suffixes and preserve the original candidate ID as
`base_candidate_id`.
It also emits `refresh_budget_report.v1` after contact, resource, and effective
allocation filtering.
The embedded `candidate_diff_report.v1`, `freshness_report.v1`, and
`refresh_budget_report.v1` subreports carry schema-visible `model_limits`
copied from `OrbitalDynamics.CandidateRefresh.capabilities/0`, matching the
parent artifact boundary when those subreports are reviewed or imported on
their own. Executable validation checks those subreport `model_limits` against
`OrbitalDynamics.CandidateRefresh.model_limits/0` so stale candidate-refresh
trust-boundary declarations fail validation. The parent and subreport JSON
Schema exports now constrain those model limits as exact string sets, including
embedded candidate-refresh subreports, so import gates can detect drift without
the Elixir validator.
The embedded `candidate_diff_report.v1` matches duplicate candidate IDs by row
occurrence so prior/refreshed duplicate IDs can still produce separate retained,
new, and invalidated rows. Semantic prior or replacement matches are linked only
when exactly one candidate shares the semantic key; ambiguous semantic matches
carry candidate IDs/counts for review instead of arbitrary replacement IDs.
Embedded candidate-diff reports also carry the refresh artifact's
`source_window_lineage` rows directly, so review/import consumers can validate
candidate, source-window, and scenario linkage without reconstructing parent
artifact context.
Retained or semantically matched candidates also record operational semantic
changes for throughput, station capacity/availability/reservation context,
contact-success factors, observation-success factors, and target priority so
feedback-only refreshes do not appear unchanged. Those semantic changes now
include deterministic detail rows with the changed field, prior/refreshed
paths, and prior/refreshed values, so review queues can explain the actual
delta without reopening both candidate sets. Candidate-diff producers also
derive sorted `candidate_diff_changed_fields`, matching `changed_fields`, and
`candidate_diff_changed_field_count` summaries from those detail rows for
operators and adapters that only need field-level routing.
Generated retained/new candidate-diff rows, and invalidated rows when source or
replacement context is available, also carry target identity plus source-target
catalog metadata, target latitude/longitude/minimum-elevation fields, and
target-priority value/source/objective evidence. This keeps candidate-diff
reports useful as standalone review inputs instead of requiring consumers to
reopen `candidate_activities`.
Malformed prior candidate rows missing or carrying invalid stable identity,
scenario identity, source-window/station-calendar identity, or activity type are
preserved as `invalid_prior_candidate_input` invalidated rows with sanitized
schema-facing IDs plus source candidate evidence, and are excluded from
retained/new semantic matching.
Provider-shaped prior downlink rows that omit explicit type/direction are
normalized before this validation when they carry `station_id`,
`start_s`/`end_s`, and no command feedback markers, so stale provider contact
history can match refreshed downlink candidates without false invalid/new churn.
Direction-only prior command, uplink, tracking, and health-check station windows
with station and time context are also kept as valid prior contact history, even
when the refreshed candidate set no longer contains them.
Prior candidate rows may also use top-level `activity_type` as the activity
kind alias for non-contact candidates; blank aliases remain invalid
prior-candidate inputs.
Repair and strategy handoff preserve candidate-diff ambiguity metadata rather
than collapsing duplicate invalidated or replacement rows by ID. Operator-review
approval rows and Cadence import manifest rows lift the key candidate-diff
fields, including ambiguity and budget-dropped replacement metadata, to row
level so queues can filter ambiguous or budget-constrained replacement
decisions without parsing the nested source requirement. Strategic-addition
approval requirements also carry staged candidate activity context, so
operator-review and Cadence-import rows retain source-window, score,
target-priority, and observation-feedback evidence for review gates.
Standalone `candidate_refresh.v1` artifacts also lift invalidated
`candidate_diff_report.v1` rows into typed `candidate_diff_review`
operator-review rows and `review_candidate_diff` Cadence import rows, preserving
replacement candidate IDs, semantic-change reasons, source-window lineage, and
the source candidate-diff row for refresh handoff queues. Candidate-diff
handoff rows also preserve candidate-activity source-target metadata
(`source_target_id`, `source_target`, and target latitude/longitude/minimum
elevation fields) plus target-priority value/source/objective evidence, so
target-catalog and target-priority context survives review/import routing
without reparsing the nested diff row. Semantic-change detail rows are also
preserved at row level for adapter queues that need before/after evidence
without parsing only reason labels, and those rows carry changed-field
summaries derived from the same evidence for deterministic queue filtering.
When a replacement candidate has a
`source_window_lineage.v1` row, the generated review and import
rows also carry `replacement_source_window_id`, `replacement_source_window`,
and `replacement_source_window_lineage` so adapter queues can audit the new
window boundary without reopening the candidate-refresh artifact. Replacement
`new_candidates` already represented by an invalidated row are not duplicated,
but unpaired semantic or ambiguous new-candidate rows are lifted into the same
review/import gate. Retained candidates with semantic-change reasons are also
lifted without pretending they were invalidated, so stable candidate IDs with
changed throughput, confidence, or station state still reach operator review.
Candidate-diff import
rows expose `refresh_gate=candidate_diff`, a derived gate status, and a
semantic-change reason count so refresh handoff queues can route candidate
identity churn without unpacking the source diff row. V2 repair artifacts lift
source candidate-diff reports into the same top-level repair review/import
package, and V3 strategy artifacts lift branch-local candidate-diff rows with
`branch_id` flattened for adapter routing. V3 branch derivation replays
candidate-diff review or import rows only when they name a concrete
`replacement_candidate_id`; the branch then stages that validated prior/refresh
candidate as a strategic addition with candidate-diff metadata, while rows
without a replacement candidate remain review-only. Mission-state
`source_candidate_diff_report` inputs now feed the same branch-local replacement
path directly when invalidated rows name a concrete replacement candidate.
Mission-state `source_result_artifact` / `result_artifact` wrappers can carry
`source_candidate_diff_report` or `candidate_diff_report` inputs through the
same path, preserving the nested report source path and inheriting wrapper trust
boundaries when the embedded report has none.
Stale or unknown
`freshness_report.v1` status is lifted into typed `freshness_review` rows and
`review_refresh_freshness` Cadence import gates, preserving snapshot age,
horizon alignment, state-quality status, and stale/unknown reasons separately
from generic warnings. Those Cadence gates now expose
`refresh_gate=accepted_state_freshness`, the row-derived gate status, and a
reason count so adapter queues can route freshness review without parsing the
source report. Prior freshness review/import rows with stale or unknown status
can derive branch-local refreshes from current mission-state inputs, preserving
the review/import source path and trust boundary on the branch event while
keeping the Cadence handoff review-only. Mission-state `source_freshness_report`
inputs now derive the same branch-local refresh-freshness pressure directly.
Embedded `source_freshness_report` or `freshness_report` inputs inside
mission-state result-artifact wrappers replay through that same branch-local
pressure path with wrapper trust boundaries and precise source-report audit
paths.
V2 repair artifacts lift source freshness reports into the same
top-level repair review/import package, and V3 strategy artifacts lift
branch-local repair freshness reports with `branch_id` flattened for adapter
routing. When `refresh_budget_report.v1` drops candidates or receives a malformed
candidate-limit policy value or shape, refresh
handoff also emits typed `refresh_budget_review` rows and
`review_refresh_budget` Cadence import gates with
`refresh_gate=candidate_budget`, exceeded-budget or invalid-policy gate status,
kept/dropped counts, candidate IDs, selection order, overflow count, invalid-policy
reason/source evidence, and max-candidate policy evidence. V2 repair artifacts lift source refresh-budget drops into the same
top-level repair review/import package, and V3 strategy artifacts lift
branch-local repair refresh-budget drops with `branch_id` flattened for adapter
routing. Prior refresh-budget review/import rows with dropped candidates can
derive a branch-local refresh that relaxes
`candidate_limit_policy.max_candidate_activities` to the reported input
candidate count, and mission-state `source_refresh_budget_report` inputs now
derive the same relaxed branch-local budget comparison directly.
Mission-state result-artifact wrappers can likewise carry
`source_refresh_budget_report` or `refresh_budget_report` inputs into that
relaxed branch-local budget comparison, preserving the nested source path and
wrapper trust boundary on the branch event while keeping the Cadence boundary
review-only.
When `candidate_limit_policy.max_candidate_activities` is supplied, the refresh
keeps the highest-score candidates with deterministic start-time and ID
tie-breakers, restores artifact order, records kept and dropped candidate IDs,
and warns when candidates are dropped. Malformed values are preserved in the
refresh-budget report as invalid policy evidence instead of silently disabling
the review gate. Candidate diffs distinguish prior
candidates whose refreshed replacement was generated and then dropped by the
budget from candidates that were never present in the refreshed set, preserving
the dropped replacement ID for downstream repair/review explanation. This is a
cost-control/reporting surface, not an optimizer search or schedule mutation.
Exact prior contacts excluded by allocation are marked
`dropped_by_contact_allocation` so deferred, blocked, and policy-blocked
contacts are not reported as usable refreshed opportunities.
V3 strategy branch-generated candidate refreshes preserve an explicit strategy
approval policy into those same nested filter reports, embedded allocation
rows, and refreshed contact intents so branch-local suppression and review
evidence retains the strategy policy bundle context. Strategy-derived branches
carry explicit `resource_margin_pressure`, `resource_availability_constraint`,
and `degraded_spacecraft` events into generated
`candidate_refresh.v1.operational_feedback` overrides as well as resource
summary overlays, preserving operational-feedback input-key and trust-boundary
evidence for branch-local resource filters. Incompatible activity lists on
those degraded branch events accept atom- or string-style inputs and normalize
to deterministic string arrays before scoring and filtering. Strategy-derived branches
also accept station-calendar style mission-state reservations declared as
`availability: reserved`, preserving reservation IDs, owner, and status into
the branch-local refresh contact filters; `availability: maintenance` is
derived as a station outage for the same branch-local refresh path. Prior
station-calendar, operator-review, and Cadence-import station availability
pressure rows use the same case/whitespace/hyphen/atom normalization before V3
branch-event typing, so provider-shaped status tokens replay as executable
candidate-refresh requests instead of being dropped as unknown strings. Candidate
refresh canonicalizes ground-network availability, status, and contention tokens
for case, whitespace, and hyphen differences before outage, reservation, and
reduced-capacity filtering. The
checked-in V3 strategy request includes a branch-specific `candidate_refresh.v1`
artifact and is covered by a JSON-input regression, so example branch refresh
windows must remain valid against the current candidate-refresh contract.
V1 campaign artifacts embed the report over
`campaign_plan.candidate_activities`. The report can be normalized into
`operator_review_package.v1`
`contact_allocation_review` rows and then into `cadence_import_manifest.v1`
typed `review_contact_allocation` rows so allocated, deferred, and blocked
contact handoffs expose top-level allocation fields plus
`source_contact_allocation`, suppression, contention, policy context, and
matched policy-escalation routing fields without
granting execution authority.
