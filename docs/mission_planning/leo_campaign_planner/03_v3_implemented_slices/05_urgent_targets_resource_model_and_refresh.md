# Urgent Targets, Resource Model, and Candidate Refresh

Urgent target handling is deliberately explicit. If a strategic urgent target
has candidate observation windows, V3 chooses a viable non-overlapping candidate
inside the remaining horizon and records the selected scenario, target ID,
source window, feasibility status, and approval requirement. If no candidate
exists, V3 only stages a placeholder when policy allows it, marks it
`unvalidated_placeholder`, adds a warning and risk, and requires operator
approval.
Branch-generated refresh candidates are included in the same validated-window
search, so a derived refresh can turn mission-state target visibility into a
validated strategic addition when the candidate does not overlap existing
branch activities.

The thin resource model uses mission-state summaries for fuel margin, power
margin, downlink capacity, onboard storage, spacecraft availability, and payload
availability. It does not simulate power, storage fill/drain, fuel use, or link
budgets. Low margins add explicit score adjustments, warnings, and risk
indicators.
Candidate refresh also applies thin availability and margin filters:
unavailable payload suppresses observation candidates, unavailable antennas and
unavailable ground stations suppress downlink candidates, configured fuel,
power, storage, and downlink margin thresholds can suppress candidates, and
`resource_filter_report.v1` / `contact_filter_report.v1` record the suppressed
candidate IDs and reasons. Duplicate suppressed candidate IDs are disambiguated
with deterministic suffixes while preserving `base_candidate_id` for
review/import traceability. Candidate diffing also matches duplicate candidate
IDs by row occurrence so refreshed duplicate rows are not collapsed into a
single retained/new/invalidated decision. Semantic replacement links are only
emitted when a semantic key has one candidate match; ambiguous semantic matches
carry candidate IDs/counts for review instead of arbitrary replacement IDs. A refresh can also declare
`candidate_limit_policy.max_candidate_activities`; candidate refresh applies
that limit after contact/resource filtering, keeps candidates by deterministic
score/start/ID order, restores artifact order, and emits
`refresh_budget_report.v1` with kept and dropped IDs. Duplicate candidate IDs
are budgeted by row occurrence, so keeping one duplicate ID does not erase the
matching dropped row from the budget report. This is a bounded
cost-control/reporting surface, not a search optimizer.
V3 branch-generated refresh requests inherit
`candidate_refresh_defaults.candidate_limit_policy`, and their nested V2 repair
artifacts preserve the resulting `source_refresh_budget_report`.
Generated V3 branch refreshes now feed station outage/reservation/capacity,
degraded-spacecraft plus low-fuel, low-power, low-storage, and low-downlink
resource-pressure, payload-unavailable, and antenna-unavailable events into
those same filters. Explicit `mission_state.resource_summaries` are treated as
the stronger planning-grade resource source for low fuel, storage, downlink,
power, degraded state, payload availability, and antenna availability branch
derivation and branch-comparison resource risks, instead of only filtering
generated refresh candidates. Generated refreshes also apply observation success
feedback to generated observation candidate value, instead of only changing the
already-selected repair plan.
Downlink-completion branches also consume generated downlink candidates as
validated strategic additions when they do not overlap existing branch
activities.
When operational feedback supplies station throughput factors, generated branch
refreshes also scale matching ground-network capacity fractions before building
contact candidates. When branch derivation is enabled, low station-throughput
feedback can derive its own branch-generated refresh, so operators can compare
the degraded-throughput case without hand-authoring a what-if branch.
Contact-success feedback is also copied into generated branch refreshes so
downlink candidates carry a `contact_success_factor` and a score adjustment that
makes the branch-local candidate set reflect station contact confidence, not
only branch-level scoring. Default station-throughput and contact-success
feedback applies to branch-generated candidates as well as station-specific
feedback, even before repair selects those contacts into the activity list; the
branch-comparison review/import rows identify that activity source explicitly.
Low contact-success feedback can likewise derive a
branch-generated refresh for the degraded contact-confidence case.
Terminal or degraded image-quality status feedback can also derive the
observation-quality refresh path when no scalar image score, cloud-cover, or
blur value is available, while preserving the original status text on the
branch event and refreshed observation evidence.
Downlink-demand feedback can derive a branch-generated refresh as well:
`operational_feedback.downlink_demand_mb` becomes required-demand evidence on
generated downlink candidates and adds a deterministic downlink-completion score
term before candidate-budget selection.
Derived `downlink_completion_gap` events with `required_downlink_mb` use the
same branch-local demand path before refresh execution, so candidates generated
for a data-volume gap carry required volume, candidate throughput, shortfall,
and requirement status rather than only a generic contact score.
If a branch carries multiple independent data-volume gaps for the same station,
their required downlink demand is accumulated before refresh execution.
Standalone candidate refresh likewise accumulates multiple matching
downlink-completion objective volume requirements for the same station before
scoring generated downlink candidates.
Low observation-success feedback can derive a target-specific branch-generated
refresh and stage validated observation candidates for operator review, keeping
the behavior in artifact space rather than a learned targeting model.
Low command-success feedback can derive command/health-check confidence review
branches scoped to selected command or health-check activities, so operators can
compare command-risk cases without hand-authoring a what-if branch.
High target-priority feedback can likewise derive a target-specific
branch-generated refresh and stage validated observation candidates, so
operator review can compare priority-driven observation work without hand
authoring a what-if branch.
Resource-availability feedback can derive a branch-generated refresh for
payload or antenna unavailability, letting Cadence-sourced availability changes
suppress generated observation or downlink candidates without hand-authored
resource summaries.
When the strategy request supplies an explicit approval policy, generated branch
refreshes preserve that policy into nested contact and resource filters,
contact-allocation rows, and refreshed contact intents so branch-local review
evidence carries the same policy authority as the top-level strategy decision.
After those filters, `candidate_diff_report.v1` compares refreshed candidates
against the prior candidate set so repair can distinguish retained, new, and
invalidated candidate IDs, including retained-row semantic changes for
throughput, station capacity, contact success, observation success, and target
priority. Paired replacement `new_candidates` are represented by the
invalidated candidate row, while unpaired semantic or ambiguous new-candidate
rows and retained candidates with semantic-change reasons are promoted into
candidate-diff review/import gates without marking the candidate invalidated.
`candidate_diff_row.v1` can be linted directly for focused semantic-change
regressions. `freshness_report.v1` records accepted snapshot age,
remaining-horizon start offset, policy thresholds, and whether the refresh is
current, stale, or not fully evaluable. The same artifact now carries a nested
`contact_allocation_report.v1` over refreshed contact candidates so generated
branch refreshes preserve deterministic allocated/deferred contact semantics,
including direct command and tracking station windows, without reserving
provider time or mutating schedules.
Candidate-refresh artifacts also expose top-level `model_limits` so downstream
branch-refresh consumers can inspect those sampled-window, thin-filter, and
artifact-only boundaries without parsing assumptions prose.
When a V3 mission-state snapshot carries a declared `station_calendar` or
`station_calendar_provider` artifact, strategy branch generation normalizes it
into ground-network intervals before branch-local candidate refresh. Derived
station outage, reservation, and reduced-capacity branches then carry provider
provenance and trust-boundary evidence into generated contact filtering without
calling provider APIs or reserving station time. Prior station-calendar,
operator-review, and Cadence-import station availability evidence is normalized
for case, whitespace, hyphen, atom, and outage/down/offline variants before V3
branch-event typing, so provider-shaped `Reserved` or `Reduced Capacity` rows
replay the same branch-local refresh as canonical planner rows. Catalog-only ground-station
defaults are not counted as competing calendar overlaps when a branch-local
event interval exists for the same station, so declared provider trust remains
declared in contact-filter review evidence. Suppressed-contact rows flatten the
applied provider entry ID as `station_calendar_entry_id`, including provider
rows that only supplied `id` or nested the provider ID under
`source_station_calendar_entry`, so Cadence-facing queues can route by stable
calendar entry without reopening nested source evidence, even when the contact
itself is malformed and routed to invalid-input review.
Strategy-level `operator_review_package.v1` rows lift those branch-local
allocation rows out of nested repair results, so Cadence-facing review queues
can see allocated, deferred, and blocked contact decisions alongside branch
comparison rows. Branch-comparison rows also flatten repaired link-capacity
requirement evidence, including selected capacity, required downlink demand,
selected and realized shortfall, realized completion ratio, and requirement
status, so strategy review does not need to unpack nested branch repair artifacts
to see downlink-capacity risk. They also flatten
repaired constraint counts/statuses, so inherited planner-local constraint
violations remain visible at the strategy comparison boundary.
contact/resource suppressions. Branch-local `resource_projection_report.v1`
rows are lifted into the same `resource_projection_review` row shape used by
standalone projection reports, preserving branch ID, first pressure activity,
storage-limited downlink utilization, and unused downlink capacity.
