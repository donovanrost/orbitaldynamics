# V2: Rolling Operations Planner

LEO Constellation Campaign Planner V2 turns the static campaign generator into a
rolling operations planner.

It answers:

> Given the current realized state of operations, what should change in the plan
> now?

## Rolling Horizon Replanning

V2 should replan on a cadence and after operational changes:

- a missed contact,
- a failed activity,
- new tasking,
- updated orbit determination,
- a spacecraft health change,
- ground-station availability changes,
- an operator-requested plan change.

The planning loop becomes:

```text
planned activity -> approved schedule -> realized operation -> delta -> replanned campaign
```

Cadence becomes the source of realized operational state. OrbitalDynamics
produces the next candidate plan from that state.

## Resource-Aware Scheduling

V2 should understand constrained mission resources:

- onboard storage,
- power and battery state,
- payload duty cycles,
- antenna and link availability,
- ground-station conflicts,
- command-window requirements,
- downlink volume,
- operator approval gates.

This is the point where the planner becomes operational instead of only
analytical.

When the repair request carries a mission-state downlink-completion objective
with `required_downlink_mb`, the repaired plan's `link_capacity_report.v1`
compares selected repaired downlink capacity against the aggregate requirement
across all mission-state downlink-completion objectives unless the repair
scoring/link-capacity policy declares an explicit override. The report remains
artifact-only and does not reserve provider time. A positive selected shortfall
also contributes one normalized `risk_weight` unit to the V2 repair score as
`link_capacity_pressure_penalty`; satisfied or undeclared demand omits that
conditional score term.
Repair-time station-calendar pressure likewise contributes one normalized
`risk_weight` unit as `station_calendar_pressure_penalty` for each affected
contact that is actually selected into the repaired activity list. Calendar
pressure on unselected source candidates remains reviewable context but does not
change the repair score.
Standalone candidate refresh applies spacecraft-, satellite-, or scenario-scoped
downlink-completion and collection-latency objectives only to matching generated
downlinks, so shared-station contacts for other spacecraft keep their ordinary
contact score.

## Plan Repair

V2 should repair existing plans after disruption instead of always generating a
new plan from scratch.

Examples:

- Move a missed downlink to the next viable station pass.
- Reassign an observation to another spacecraft.
- Remove payload activities when a spacecraft enters a degraded mode.
- Recompute downstream windows after a maneuver slips.
- Preserve already-approved activities when possible.

Schedule churn should become an explicit cost. The best repaired plan is not
always the globally optimal plan; it is often the best plan that minimizes
operational disruption while protecting mission value.

## Implemented V2 Repair Slice

The first V2 implementation is intentionally a repair layer over V1 artifacts,
not a new optimizer. It uses the prior plan's selected activities plus either
the prior candidate windows or a `candidate_refresh.v1` artifact as the
reproducible planning substrate, then applies realized operations state to
produce a repaired remaining-horizon plan. Provider-shaped prior-plan contact
rows that carry station/time fields but omit explicit type or direction are
normalized into canonical downlink activities before repair, so preserved
provider contacts remain schema-valid and continue to satisfy downlink
objectives in V3 branch comparison.

The public API is `OrbitalDynamics.CampaignPlanner.repair/1`. It accepts either
a map or `%OrbitalDynamics.CampaignPlanner.ReplanRequest{}` with:

- `prior_plan`: a V1 `campaign_plan` artifact.
- `realized_state`: realized activities plus optional spacecraft degraded-mode
  state.
- `current_epoch_s`: the rolling repair epoch.
- `remaining_horizon`: optional `starts_at_s` and `ends_at_s` bounds.
- `constraints`, `scoring_policy`, `repair_policy`, and `approval_policy`:
  optional overrides.
- `candidate_refresh`: optional `candidate_refresh.v1` artifact. When present,
  its refreshed `candidate_activities` replace the prior plan candidates for
  repair while the prior selected activities remain the plan being repaired.
- `candidate_refresh_request`: optional executable refresh manifest. When no
  prebuilt `candidate_refresh` is supplied, V2 repair runs the request through
  the study pipeline and uses the generated `candidate_refresh.v1` artifact as
  the repair candidate source. If the repair request supplies an explicit
  approval policy and the refresh request does not override it, the generated
  refresh inherits that policy for contact intents, filters, and allocation
  review evidence. Repair artifacts preserve the refresh budget report when the
  refresh applied a deterministic candidate limit.
- `ground_network` or `station_calendar`: optional repair-time station
  availability/capacity intervals. These annotate source downlink candidates
  and produce a `source_station_calendar_report`; they do not reserve contacts
  or suppress candidates.

The supporting V2 concepts live with the planner:

- `RealizedActivity`: completed, missed, failed, delayed, canceled, or partial
  operational outcomes.
- `PlanDelta`: planned-vs-realized comparison rows with repair decisions.
- `RepairPolicy`: preservation, locked-change, degraded-mode, and churn-cost
  knobs.
- `ReplanRequest`: prior plan, realized state, epoch, horizon, constraints,
  repair policy, approval policy, optional executable candidate-refresh request,
  and optional repair-time ground-network calendar inputs.
- `ReplanResult`: wrapper for a JSON-serializable V2 repair artifact.

The V2 artifact includes:

- `source_plan_id`, `source_planner`, and source provenance.
- `study_id`, `source_planner`, `change_summary`, `preserved_activities`, and
  `approval_rule_matches` are represented in the generated V2 schema while
  remaining optional for older repairs. Runtime validation pins stable study
  identity, typed policy rows, row-derived delta-action counts, and the exact
  preserved subset of repaired activities.
- `realized_state_snapshot` exactly as normalized for the repair.
- `deltas` explaining what changed and why.
- `activities` for the repaired plan and `preserved_activities` for unchanged
  work.
- operational activity context in planned delta snapshots, replacement repair
metadata, and approval requirements, including approval state, locks,
dependencies, exclusivity groups, provenance, and source-window lineage when
those fields are present on the source activity. Station-calendar entry identity
is flattened from nested provider source evidence when needed while retaining
the full source entry and overlap context. The context now includes
`timeline_identity` metadata with a preserved or derived `timeline_id`,
normalized dependency/exclusivity stable-ID arrays, plus source/replacement
timeline IDs on moved or replaced deltas so replans can be traced without
relying only on transient activity IDs. Timeline diffs also route contact
direction changes to operator review because downlink, uplink, tracking, and
command directions carry different authority boundaries. Timeline diff inputs
reuse the same dependency-cycle integrity checks as operational timelines, so
unchanged cyclic source/replacement payloads become reviewable
`review_timeline_integrity` rows instead of passing through as no-op diffs.
Diff and transition-application artifacts also schema-type nested status/
approval transition objects and source/replacement protection-decision payloads
so review/import adapters can route lifecycle changes without reopening raw
activities, with nested timeline identity stable IDs validated at the same
handoff boundary. Timeline-link and timeline-protection summary handoffs also
schema-type their stable IDs, invalid-input flags, and protected/change counts.
- `operational_timeline_report.v1` over the repaired activity list, using the
  same report-only timeline summary contract as V1 campaign artifacts, including
  deterministic dependency/exclusivity stable-ID arrays when planned activities
  carry those relationships. Standalone operational timeline reports can also
  normalize command/contact review for command- and uplink-directed planned
  contacts, activity approval review, conflict resolution, and missing Cadence
  import preparation rows into
  `operator_review_package.v1` and `cadence_import_manifest.v1` without
  executing approvals or schedule writes. Cadence import rows preserve the
  original timeline row as `source_operational_timeline` so adapters can read
  schedule, approval, dependency, exclusivity, and import-presence context
  without unpacking the generic source review row. Dependency-cycle integrity
  now runs over both activity-ID and timeline-ID dependency graphs, preserving
  `dependency_cycle_activity_ids` and `dependency_cycle_timeline_ids` on
  review/import rows so cyclic handoff payloads are review-gated without
  mutating the plan or Cadence schedule. V1 campaign and V2 repair embedded
  operator-review packages lift embedded operational-timeline rows that require
  operator action into the same review surface.
- `source_candidate_activities` so later V3 strategy branches can reuse the
  repair search space. This is either the prior plan candidate set or the
  refreshed candidates from a supplied or repair-generated `candidate_refresh.v1`.
- `source_contact_intents` and `source_resource_summaries` when repair consumes
  a `candidate_refresh.v1`, preserving Cadence-facing contact rows and thin
  resource summaries alongside the refreshed candidate set. Repair-generated
  refreshes inherit the repair approval policy unless the nested refresh request
  declares its own policy, so contact-intent evidence remains tied to the repair
  authority bundle. Standalone `candidate_refresh.v1` artifacts can now be
  converted directly into operator-review packages and Cadence import manifests
  for refresh-time contact-intent, allocation, candidate-diff, suppression, and
  warning review; candidate-diff review/import rows preserve source-target
  metadata, target latitude/longitude/minimum-elevation fields, and
  target-priority value/source/objective evidence from the refreshed activity
  context, and V3 branch-local candidate-diff replay carries those fields into
  derived replacement events, staged repair metadata, and strategic-addition
  approval contexts. Candidate-diff replacement replay also preserves plural
  objective identity in `objective_ids` through staged feasibility, approval
  activity contexts, and branch-comparison summaries. Approval activity contexts
  also schema-type source event, source branch, source timeline, feedback, trust
  boundary, derivation, and source-event provenance fields used by branch-local
  replay, including nested source-event provenance trust-boundary labels and
  actual-data-rate throughput derivation details, plus staged candidate scoring,
  source-window, feasibility, repair reason, and candidate-diff changed-field
  evidence; nested source-window evidence is schema-checked for stable identity
  and timing fields. Candidate-diff review/import rows also expose typed
  source and replacement source-window lineage handoffs, so exported row schemas
  and executable validation reject malformed nested source-window IDs and
  candidate/window lineage mismatches before Cadence import. Candidate-diff
  handoff rows and replayed branch events also
  carry `semantic_change_details` with prior/refreshed values, so operators can
  audit why a replacement is reviewable without reconstructing both candidate
  sets; the same rows expose sorted changed-field summaries and counts for
  deterministic queue filtering.
- station-calendar review rows preserve both the applied highest-priority
  provider entry and the full overlapping entry ID/availability set, plus
  matched policy escalation queue, role, required authority, and SLA metadata
  for downstream review routing.
- contact-allocation review/import rows flatten the applied station-calendar
  entry ID from either `station_calendar_entry_id` or nested provider source
  evidence, and allocated contacts return the same ID while still preserving
  the full source entry and overlap context for audit.
- `source_resource_projection_report` when repair has source resource
  summaries, projecting repaired observation storage production and downlink
  transfer estimates through the thin planning resource model. Downlink transfer
  uses station-capacity-adjusted throughput when a repaired contact carries a
  reduced-capacity station-calendar fraction. Projection rows also carry
  `activity_resource_flow` entries that order repaired activities by schedule
  time and expose storage/downlink roll-forward, intermediate margins, overflow,
  and shortfall without claiming subsystem simulation.
  Rows with projected storage overflow or downlink shortfall can carry
  `policy_decision.v1` evidence when an approval policy is supplied, and the
  embedded V1/V2/V3 projection reports pass planner approval policy into that
  classification. V2's generic `resource_projection_pressure_penalty` applies
  one normalized `risk_weight` unit to every emitted selected-plan projection
  risk, including storage/downlink/battery, negative thermal margin,
  spacecraft/payload/antenna availability, degraded payload, and selected
  activity compatibility pressure; nominal projections omit the term.
  Candidate-refresh `freshness_report.v1` inputs with normalized `stale` or
  `unknown` status likewise apply one source-wide normalized `risk_weight` unit
  through `refresh_freshness_pressure_penalty`; current or absent reports omit
  that conditional term while their source evidence remains available to the
  repair artifact and review/import handoff.
  Candidate-refresh `candidate_diff_report.v1` inputs likewise apply one
  source-wide normalized `risk_weight` unit through
  `candidate_diff_pressure_penalty` when the shared V3 replay classifier finds
  new, invalidated, semantic-change, candidate-routing, or station-routing
  pressure. Multiple diff rows remain one aggregate unit, and empty or absent
  reports omit the term.
  The same projection model is available through
  `OrbitalDynamics.ResourceProjection` and
  `OrbitalDynamics.resource_projection_report/3` for standalone selected
  activity lists. Projection rows distinguish planned downlink capacity from
  storage-limited data relief and warn when a scheduled downlink has more
  capacity than stored data available in the roll-forward. Greedy replacement
  ranking projects each alternative with already repaired and not-yet-processed
  planned activities against the same candidate-refresh resource summaries,
  subtracting one calibrated `risk_weight` unit per shared projection risk
  within the candidate's semantic-diff priority tier. Executable V2 validation
  recomputes that row penalty from the embedded risk-indicator count and the
  enclosing scoring-policy weight, so compensating ranking-score edits cannot
  contradict the explanation while preserving arithmetic. Final resource
  projection is recomputed after repair and remains authoritative; this does
  not turn the thin planning model into a subsystem simulator or global
  optimizer.
- `score_term_report.v1` and `objective_tradeoff_report.v1` over repaired
  activity value, churn, schedule-move, and resource-projection pressure score
  terms plus selected link-capacity shortfall pressure, preserving the same
  scored-objective explanation shape used by V1 ranked timeline artifacts.
  During greedy replacement ranking, each alternative is projected with already
  repaired and not-yet-processed planned activities; a projected selected
  shortfall subtracts the same calibrated `risk_weight` unit within the
  candidate's semantic-diff priority tier. Executable V2 validation requires
  exactly that one negative weight unit when the row carries positive shortfall
  evidence, and zero link pressure when the evidence is absent. The final report
  is recomputed after all repairs and remains authoritative rather than claiming
  global contact optimization.
- `link_capacity_report.v1` over repaired downlink activities, preserving the
  same fixed-rate throughput summary shape used by V1 campaign artifacts.
- `source_contact_filter_report`, `source_contact_allocation_report`,
  `source_contact_contention_resolution_report`, and
  `source_resource_filter_report` when present on the refresh artifact,
  preserving candidate suppression reasons, allocated/deferred contact review
  rows, exact selected/deferred contention recommendations, allocation
  reservation evidence, and spacecraft resource decisions caused by unavailable
  ground-network or resource constraints. The contention-resolution handoff is
  recommendation-only and does not suppress candidates or alter schedules. If
  an otherwise viable replacement candidate is named exactly in a preserved
  recommendation's `deferred_contact_ids`, replacement ranking applies one
  calibrated `risk_weight` unit and records the contributing resolution group
  IDs. Recommended and unrelated candidates remain neutral, and the selected-
  plan score reconciles the same advisory evidence.
- `source_station_calendar_report` when repair-time `ground_network` or
  `station_calendar` intervals annotate source contact candidates. Reserved,
  unavailable, or reduced-capacity affected rows participate in repair scoring
  only when their contact IDs are selected into repaired activities. Repair
  replacement ranking uses the same pressure classifier as one calibrated
  `risk_weight` unit within the existing semantic candidate-diff priority tier.
  A nominal alternative can therefore outrank a slightly higher-value pressured
  contact, while smaller weights can still select the pressured contact and
  preserve its score, review, and import evidence; the calendar remains
  annotation-only and does not mutate schedules.
- V1 `contact_contention_report.v1` on campaign plans, marking same-station
  and same-spacecraft cross-station overlapping contacts without scheduling or
  suppressing them. Generated campaign and refresh contact rows use
  planner-native `scenario_id` as spacecraft scope when no explicit
  `spacecraft_id` is declared.
- V1 `contact_contention_resolution_report.v1` recommendations for overlapping
  contacts, preserving operator review and avoiding station reservations.
- Standalone `ContactContention` APIs and `OrbitalDynamics` facades for
  generating the same contact-contention reports and advisory recommendations
  outside a full campaign build, with duplicate contact IDs treated as
  ambiguous contact identity instead of deterministic selections and malformed
  contact-like rows preserved as invalid-input review handoffs instead of being
  dropped before overlap detection.
- Standalone `LinkCapacity` APIs and `OrbitalDynamics.link_capacity_report/3`
  for generating the same fixed-rate throughput summary outside a full campaign
  build without claiming a link-budget or reservation model; duplicate candidate
  contact IDs and unmatched selected IDs are reported rather than counted as
  selected throughput, and downlink-like candidate or selected rows missing
  stable contact identity or station identity are preserved as invalid-input
  review/import handoffs instead of being dropped before grouping.
- Standalone `ContactAllocation` APIs plus
  `OrbitalDynamics.allocate_contacts/3` and
  `OrbitalDynamics.contact_allocation_report/3` for composing declared
  ground-network rows or `station_calendar_provider.v1` inputs with station- or
  spacecraft-scoped contention
  recommendations into
  allocated/deferred/blocked contact rows without provider reservation,
  approval, or schedule mutation. Contact-like rows missing identity, station,
  or timing fields are preserved as blocked invalid-input review rows instead of
  being dropped before allocation. When supplied an approval policy, reviewable
  allocation rows carry `policy_decision.v1` rule-match and escalation evidence
  for blocked or operator-review allocation boundaries, and the nested
  station-calendar affected-contact rows retain the same policy evidence for
  outages, reservations, and severe capacity reductions. Allocation rows
  preserve station-calendar overlap IDs/counts and reservation overlap evidence
  plus provider ID/entry ID evidence from that nested station-calendar overlay
  for downstream review/import adapters. V1 campaign plans and candidate
  refresh artifacts pass their
  approval policy into embedded
  allocation reports; candidate refresh evaluates post-resource-filter contact
  candidates for allocation while adding contact-filtered station suppressions
  back into the allocation report as blocked review rows. V1 campaign plans now
  embed the same report over campaign contact candidates. Those reports can be normalized into
  `operator_review_package.v1` `contact_allocation_review` rows and
  `cadence_import_manifest.v1` typed `review_contact_allocation` rows for
  review-gated Cadence handoff, preserving `source_contact_allocation`,
  suppression, contention, and policy context.
- Timeline-diff review rows normalize into typed `review_timeline_diff`
  Cadence import rows with source/replacement timeline identities, transition
  fields, activity context, changed fields, and source diff context.
- Timeline-protection review rows normalize into typed
  `review_timeline_protection` Cadence import rows with protection category,
  decision, and source protection summary context.
- V1 `station_calendar_report.v1` on campaign plans when `ground_network`
  availability or capacity intervals affect generated contacts.
- `source_candidate_diff_report`, `source_freshness_report`, and
  `source_refresh_budget_report` when present on the refresh artifact,
  preserving candidate-set churn, stale/unknown freshness status, and the
  deterministic kept/dropped candidate budget at the repair decision boundary.
  V2 declares all three as optional direct nested contracts and runs their
  standalone validators. When the diff report marks
  an invalidated candidate as replaced by a semantically similar refreshed
  candidate, V2 repair prefers that `replacement_candidate_id` for matching
  missed contacts or failed observations and records the semantic diff row in
  the moved/replaced activity repair metadata. Duplicate invalidated or
  replacement candidate-diff rows are kept as explicit ambiguity metadata
  instead of being collapsed by source or replacement ID, and the key ambiguity
  fields are lifted onto operator-review and Cadence import rows. Each selected
  replacement also carries `repair.replacement_ranking`: ordered compact rows
  for viable unique alternatives with semantic-diff priority, value, churn,
  schedule-move, station-calendar, projected link-capacity, and projected
  resource contributions, the resulting greedy ranking score, and selected
  flag. Executable validation replays source-to-candidate start-time churn from
  the embedded source context and unique source candidate, then pins fixed churn
  and churn-times-move penalties to the enclosing scoring policy. It also
  recomputes semantic-diff priority from exact source ID/window and replacement-
  candidate links in the embedded source diff report, and pins the selected row
  to the enclosing repaired activity and optional source/replacement timeline
  handoff IDs. The evidence does not copy candidate payloads or claim global
  optimization.
- `source_contact_intents` and `source_resource_summaries` are optional typed
  source arrays backed by direct `contact_intent.v1` and `resource_summary.v1`
  definitions. Their existing standalone row validators run before V2 uses the
  inputs for scoring, replacement ranking, and strategy handoff.
- `source_contact_allocation_report` and `source_station_calendar_report` are
  optional direct nested V1 contracts. Their standalone validators run before
  V2 consumes station availability, capacity, reservation, allocation, and
  deferral evidence in station-pressure scoring and replacement ranking.
- `source_contact_filter_report`, `source_resource_filter_report`, and
  `source_resource_projection_report` are also optional direct nested V1
  contracts. Their existing standalone validators keep suppression and
  projected-resource pressure tied to typed rows, counts, trust context, and
  exact thin-model limits.
- `source_timeline_feedback_report` is an optional direct nested
  `timeline_feedback_report.v1` contract. V2 validates its row-derived counts,
  exact model limits, operational feedback, and nested operator-review package
  before accepting realized-feedback provenance at the repair boundary.
- `approval_requirements` for moved contacts, reassigned observations, delayed
  maneuver impacts, cancellations, and degraded-mode suppressions.
- Approval requirements include machine-readable `requirement_type` values so
  operator queues can distinguish contact schedule changes, observation
  reassignments, maneuver timing changes, downstream-window reviews, strategic
  additions, and cancellations without parsing free-text reasons.
  Cadence import manifests preserve standalone and embedded requirements as
  typed `review_approval_requirement` gates with the source requirement and
  activity context attached.
- `approval_policy`, `approval_status`, `approval_rule_matches`, and
  `policy_decision.v1` so repair artifacts carry the same explicit authority
  classification as V3 branches.
- `score_terms.activity_score`, `score_terms.schedule_churn_penalty`, and
  `score_terms.schedule_move_penalty`, plus conditional pressure terms such as
  `score_terms.link_capacity_pressure_penalty` when repaired selected downlink
  capacity falls short of declared demand and
  `score_terms.station_calendar_pressure_penalty` when a selected repaired
  contact carries calendar pressure.
- plan-delta source/replacement activity contexts, timeline links, and lifted
  operator-review timeline identities for import correlation.
- `assumptions`, `provenance`, `scoring_policy`, `repair_policy`, and
  `repair_metadata` with a reproducible `repair_id` and explicit
  `candidate_source`.

The current repair behavior is deliberately transparent:

- A missed downlink is moved to the next viable matching access candidate.
- A failed observation is reassigned to a viable candidate for the same target,
  including another spacecraft when available.
- A delayed maneuver is shifted to the realized start time and downstream
  same-spacecraft activities are marked for operator review.
- A degraded spacecraft suppresses incompatible payload activities while leaving
  command and health-check activities eligible for preservation.
- Completed, partial, locked, approved, or auto-approvable activities are
  preserved when policy says to preserve them.
- Churn is scored explicitly so a lower-value but less disruptive repair can
  beat a higher-value plan that moves too much of the schedule.

Example V2 inputs and outputs are checked into:

- `studies/leo_constellation_campaign_repair_v2.json`
- `study_results/leo_constellation_campaign_repair_v2.json`

## Multi-Objective Optimization

V2 should support competing objectives:

- maximize collected target value,
- maximize successful downlink volume,
- minimize collection-to-downlink latency,
- minimize fuel use,
- minimize schedule churn,
- preserve high-priority contacts,
- balance activity across the constellation.

The planner should explain tradeoffs instead of only returning a single best
score.

## Uncertainty-Aware Planning

V2 should reason about margins and confidence:

- orbit uncertainty,
- station availability uncertainty,
- maneuver execution uncertainty,
- access-window timing margin,
- contact elevation margin,
- estimated downlink success probability.

Cadence should be able to show plans as robust, tight, or fragile.
