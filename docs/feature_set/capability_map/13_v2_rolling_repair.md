# 13. V2 Rolling Repair

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** items noted below).

## Repair entry point and inputs

- **Entry point** — `CampaignPlanner.repair/1`.
- **Inputs** — the prior plan plus realized state.
- **Optional candidate replacement** — `candidate_refresh.v1` candidate replacement.

## Realized-activity handling

- Handles missed, failed, delayed, canceled/cancelled, rejected, partial, completed, and executed activities.
- Produces preserved activities, plan deltas, churn costs, and degraded payload suppression.
- Produces approval requirements with `policy_decision.v1` approval classification.
- Carries candidate-source provenance.
- Carries operational activity context in deltas, replacement metadata, and approval requirements.
- Carries source/replacement `timeline_identity` metadata for moved or replaced activities.

## Reports emitted over repaired activities

- **`operational_timeline_report.v1`** rows over the repaired activity list.
- **`timeline_transition_application_report.v1`** rows over the source and repaired activity lists, including:
  - selected safe activities;
  - review-required transition applications;
  - repair metadata counts for selected/review-gated application rows;
  - embedded operator-review plus Cadence-import rows for those review-gated transition applications, including approval-policy rule-match and policy-decision evidence when repair policy rules match transition/application/protection context.
- Runtime V2 validation applies the complete nested transition contract, pins
  its repair source and replacement count to repaired activities, and reconciles
  selected/review-required counts with `repair_metadata`.
- **`contact_allocation_report.v1`** over repaired contact activities. The
  optional report is a declared V2 nested contract; runtime validation applies
  its full row, count, summary, nested contention/resolution, stable-identity,
  and model-limit checks and requires source `campaign_repair.activities`.
- **`command_window_report.v1`** over repaired command/uplink/tracking/health-
  check activities. The optional report is a declared V2 nested contract;
  runtime validation applies its row, derived-count, approval/dependency,
  timeline-identity, and model-limit checks and pins both repair source fields.

## Timeline protection

- `repair_metadata.timeline_protection` counts and lists preserved or changed locked/approved/executed activities.
- Locked or approved activities are preserved before degraded-mode payload suppression when they are not already realized as missed, failed, delayed, or terminal.
- Partial, completed, or executed preserved-executed activities carry realized timing and `completed_fraction` evidence in their repair metadata when supplied.
  - Their plan deltas, review rows, and Cadence import rows preserve the `preserved_executed` action instead of flattening them to generic preserved items.

## Duplicate realized rows

- Duplicate realized activity rows for the same planned activity no longer collapse to one status during repair.
- Instead, repair preserves the planned activity with:
  - `review_realized_feedback` repair metadata;
  - plan-delta evidence;
  - a `realized_feedback_review` approval requirement;
  - an operator-review warning.

## Constraint reports

- V2 repair artifacts emit `constraint_report.v1` rows over inherited planner-local constraints:
  - max-timeline-activity;
  - minimum-duration;
  - eclipse-avoidance;
  - resource projection and link-capacity constraints.
- These are evaluated against the repaired activity set and source resource summaries, preserving explicit warning severity in repair and branch-comparison rows.
- The optional embedded report is declared as a direct `constraint_report.v1`
  nested contract in the V2 registry and schema export. Runtime repair
  validation applies the standalone row/count/status/model-limit checks and
  additionally requires the repair-specific model, constraint-model assumption,
  and `campaign_repair.assumptions.constraints` source identity. For campaign-
  local reports, `constraint_count` records configured supported constraints
  and may exceed distinct evaluated row IDs when inputs are unavailable, but it
  cannot be lower than the evaluated constraint count.

## Repair score terms

- V2 computes `link_capacity_report.v1` before repair scoring so selected repaired
  downlink capacity participates in the same decision artifact it explains.
- A positive `selected_downlink_shortfall_mb` contributes one normalized
  `risk_weight` unit through `link_capacity_pressure_penalty`; satisfied or
  undeclared demand does not emit that conditional term.
- Replacement ranking projects each alternative with already repaired and
  not-yet-processed planned activities, then uses the same selected-shortfall
  classifier and normalized unit within the existing semantic candidate-diff
  priority tier. This can prefer a slightly lower-value contact that satisfies
  declared demand, while a smaller weight can still select the higher-value
  shortfall alternative. The projection is a greedy repair-time estimate, not
  a global contact optimizer; the final link-capacity report remains
  authoritative after later activities are repaired.
- Repair-time station-calendar rows contribute one normalized `risk_weight`
  unit through `station_calendar_pressure_penalty` only when the affected
  contact ID is present in the repaired selected activities and the shared V3
  calendar-pressure classifier identifies reserved, unavailable, or reduced
  capacity pressure. Affected but unselected alternatives do not change score.
  Replacement ranking uses the same classifier and subtracts the same calibrated
  unit from pressure-bearing candidates within each semantic candidate-diff
  priority tier. This can prefer a slightly lower-value nominal contact while a
  smaller weight can still select the pressured alternative; calendars remain
  annotation/review evidence rather than hard candidate suppression.
- Exact viable rows from a supplied candidate-refresh
  `contact_allocation_report.v1` contribute the same unit when the shared
  classifier identifies reduced-capacity station evidence. Ranking and final
  scoring remain selected-contact scoped; deferred, blocked, reserved, nominal,
  nonmatching, or unselected allocation rows do not contribute. If the repair-
  time calendar independently reports the same contact pressure, the sources
  collapse to one calibrated unit while both artifacts remain reviewable.
  Replacement-ranking rows expose the contributing allocation/calendar artifact
  paths as a stable ordered `station_calendar_pressure_sources` list; nominal
  rows omit it.
- `resource_projection_pressure_penalty` counts every risk emitted by
  `ResourceProjectionRisk.risk_indicators/1`, including storage/downlink/battery,
  negative thermal margin, spacecraft or payload/antenna availability, degraded
  payload, and selected activity compatibility pressure. Nominal projections
  still omit the conditional term. Replacement ranking projects each alternative
  against the same candidate-refresh resource summaries and subtracts the same
  normalized unit per risk within the semantic candidate-diff priority tier.
  This can reassign an observation to a nominal spacecraft while a smaller
  weight can still retain a higher-value pressured alternative. The projection
  remains the documented thin, greedy planning model; final recomputation after
  all repairs is authoritative.
- A candidate-refresh `freshness_report.v1` with normalized `stale` or `unknown`
  status contributes exactly one source-wide normalized `risk_weight` unit
  through `refresh_freshness_pressure_penalty`. Current or absent reports omit
  the conditional term while stale/unknown review and import gates remain
  preserved.
- A candidate-refresh `candidate_diff_report.v1` contributes exactly one
  source-wide normalized `risk_weight` unit through
  `candidate_diff_pressure_penalty` when the shared V3 replay classifier finds
  new, invalidated, semantic-change, candidate-routing, or station-routing
  pressure. Multiple rows remain one aggregate unit; empty or absent reports
  omit the term.
- Candidate-refresh contact intents contribute one normalized `risk_weight` unit
  per unique pressured downlink contact selected in the repaired activities.
  V2 reuses the V3 contact-intent identity classifier for blocked-policy,
  invalid/missing Cadence-import, and invalid-activity pressure, then intersects
  its exact contact IDs with the selected activity IDs. The dedicated
  `contact_intent_pressure_penalty` therefore ignores nonselected, duplicate,
  command/non-downlink, nominal, and operator-review-only intent rows.
- The repair score, `score_terms`, and `score_term_report.v1` preserve the same
  total and expose the selected communications gap without claiming a link
  budget, provider reservation, or schedule mutation.
- Runtime `campaign_repair.v2` validation requires numeric score terms, verifies
  their sum against the top-level score, and—when the optional score-term report
  is present—requires the repair-specific model, exact embedded scoring policy
  and score-term source assumption, sorted unique term/value rows, source-plan
  scenario and deterministic row IDs, rank/selection, and timeline score against
  the enclosing artifact. When a
  `contact_intent_pressure_penalty` term is present, runtime validation also
  recomputes it from unique exact pressured downlink IDs selected in repaired
  activities and the declared `risk_weight`. The exported schema constrains
  every `score_terms` value to a number; these cross-field comparisons remain
  executable contracts. When `activity_score` is present, runtime validation
  recomputes it from the repaired activity collection with the producer's
  numeric/default-zero semantics, so coordinated edits to the total and report
  rows cannot mask aggregate activity-value drift. Present schedule-churn and
  movement terms are likewise recomputed from counted moved/replaced/canceled/
  suppressed deltas, repaired activity churn seconds, and their declared policy
  weights; missing weights retain the producer defaults. Present link-capacity
  and resource-projection terms are recomputed from the final selected-shortfall
  status and the shared source-report risk-indicator count respectively, using
  the declared `risk_weight` or its producer default. Nominal reports remain
  neutral, and older score maps may omit either term. CandidateRefresh diff,
  freshness, and budget pressure terms are likewise reconciled through shared
  producer/runtime counts: one replay-classified diff event, one stale/unknown
  freshness event, or one event per nonblank dropped candidate ID with the
  declared count and invalid-policy fallbacks. Operational-readiness and
  quality-gate terms use shared producer/runtime source-row expansion and exact
  reviewability classifiers, so each embedded review or blocking row contributes
  one declared-risk-weight penalty. Contact/resource-filter and candidate-
  rejection terms use shared producer/runtime suppression or rejection counts,
  including their declared count and exact nonblank-ID fallback precedence.
  Contact-allocation pressure likewise uses a shared normalized unusable-row
  count for deferred/blocked/policy-blocked contacts, with exact effective-status
  summary fallbacks when rows are absent.
- When the optional repair `objective_tradeoff_report.v1` is present, runtime
  validation requires the repair-specific single-timeline model and pins its
  score-term keys, policy, rank, source-plan scenario, score, zero selection
  delta, score terms, activity IDs/count, and producer-default selected counts
  to the enclosing V2 repair artifact.

## Refreshed missed-contact repair

- Treats the following as movable contact windows after canonical downlink/station/time normalization:
  - native downlink rows;
  - `planned_contact` rows whose direction is `downlink`;
  - provider-shaped prior-plan station/time rows that omit explicit type or direction, including nested `station` / `ground_station` identity objects.
- Command/uplink planned contacts remain outside the downlink repair path.
- Refreshes contact intents, contact allocation reports, and resource summaries when supplied by `candidate_refresh.v1`.

## Candidate-diff replacement selection

- Semantic candidate-diff replacement links from supplied `candidate_refresh.v1` artifacts are used to prefer matching refreshed replacement candidates and are preserved in moved/replaced activity repair metadata.
- Duplicate replacement candidate IDs are excluded from automatic move/replacement selection, so repair does not choose between ambiguous candidate rows by sort order.
- Mission-state and supplied-refresh `candidate_rejection_report.v1` evidence is consulted during automatic replacement selection, so rejected replacement candidates are excluded even when they have higher scores. Repair artifacts preserve the source candidate-rejection report and lift it into operator-review and Cadence-import handoff rows for audit.
- Moved and replaced activities preserve a deterministic
  `repair.replacement_ranking` explanation over viable, unique alternatives.
  Ranked rows expose candidate ID, semantic-diff match/priority, candidate value,
  churn, schedule-move, station-calendar, projected link-capacity, and projected
  resource contributions plus exact contact-intent pressure, final greedy
  ranking score, and selected flag. Contact-intent pressure applies one
  `risk_weight` unit when the alternative's contact ID has one or more exact
  normalized pressure statuses; rows retain the sorted unique statuses without
  multiplying the penalty for duplicate or multi-status evidence.
  Pressured alternatives retain the candidate-specific selected downlink
  demand, selected capacity-adjusted throughput, and shortfall or resource-risk
  indicators that produced those projected contributions; the link-capacity
  operands satisfy `selected throughput + shortfall = required demand`.
  Nominal alternatives omit the corresponding evidence keys. Validation keeps
  fully pre-slice shortfall-only rankings compatible, but once any row carries
  the new operands it rejects another pressured row that omits them, a partial
  operand pair, or inconsistent arithmetic.
  The station-calendar contribution can derive from exact reduced-capacity
  allocation evidence when no separate repair-time calendar is supplied, and
  its source-path list distinguishes allocation-only, calendar-only, and
  dual-source evidence without changing the penalty.
  The explanation copies no full candidate or projection payloads and
  explicitly declares that it is not global optimization.
- Runtime `campaign_repair.v2` validation and its exported JSON schema cover the
  nested ranking model/scope, stable candidate IDs, row/evidence types, derived
  row count, sequential ranks, unique candidates, and selected-candidate
  consistency while leaving unrelated repair metadata extensible. Current
  producers emit a numeric `contact_intent_pressure_penalty` on every ranking
  row, while validation treats the field as optional and defaults it to zero in
  ranking arithmetic so previously emitted V2 artifacts remain compatible.
- Runtime validation additionally verifies that each final ranking score equals
  candidate value plus its emitted penalties, semantic-diff match and priority
  agree, nonzero pressure terms carry their source evidence, and rows remain
  ordered by diff priority then score. Current rankings additionally replay the
  producer's deterministic tie-break order by schedule churn, embedded source
  candidate start time, and candidate ID; fully legacy rankings retain the
  priority/score-only check. Zero-weight pressured evidence remains valid so
  policy calibration can intentionally neutralize a known pressure.
  Each ranking candidate ID must also resolve to exactly one embedded
  `source_candidate_activities` row, and its candidate value must equal that
  source row's validated score; corrected row arithmetic cannot mask a missing,
  ambiguous, or altered source value. The current selected activity must also
  equal that exact source candidate snapshot outside its added `repair`
  metadata, preventing coordinated source/ranking drift from describing a
  different selection. Every current row's unique source candidate must also
  overlap `remaining_horizon` and start at or after `current_epoch_s`, so past
  or out-of-horizon candidates cannot remain in an otherwise consistent
  ranking explanation. A current row also cannot identify a candidate whose ID
  is rejected by the preserved `source_candidate_rejection_report`, using the
  producer's rejection-status and candidate-ID normalization. Fully legacy
  rankings retain their historical rejection-membership compatibility, and
  validation does not infer IDs from additional source rejection reports that
  the Repair artifact did not preserve.
  Current candidate-identified resource-risk
  indicators must additionally use a spacecraft scope from a valid embedded
  source resource summary applicable to that exact candidate under the resource
  projection's shared spacecraft/scenario and single-wildcard rules. Indicators
  in a fully legacy ranking may all predate candidate identity; once any
  indicator carries the current identity, every projected-resource indicator in
  that ranking must carry it.
  Current ranking envelopes also require `repair.source_activity_context`, so
  source-to-candidate start-time churn cannot become unreplayable by deleting
  context while retaining current pressure evidence. They also require stable
  source/replacement handoff IDs and a complete four-ID `timeline_link`; source
  IDs must match `source_activity_context.timeline_identity`, while replacement
  IDs remain bound to the enclosing repaired activity. Fully legacy rankings
  may omit the current markers, source context, and entire timeline handoff.
  Station-pressure penalties and source paths are recomputed from exact
  candidate IDs in the embedded allocation and station-calendar reports, so a
  row cannot claim allocation-only, calendar-only, or dual-source pressure for
  the wrong alternative even when its arithmetic is internally consistent.
  Once any row uses the current contact-intent explanation, every row must emit
  its numeric penalty and runtime validation recomputes both that value and its
  optional sorted statuses from exact `source_contact_intents` identities and
  `risk_weight`. Rankings whose rows all predate these fields remain compatible.

## Additional reports and reconciliation

- Thin V2 resource projection reports over repaired activities and source resource summaries.
- Source timeline-feedback reconciliation over planned-vs-realized activities when realized activities are supplied.
- Repaired-activity contact allocation reports over the repaired contact set.

## Executable refresh requests

- Repair-level executable `candidate_refresh_request` support when a prebuilt refresh artifact is not supplied, including preservation of explicit repair approval policy into generated refresh contact intents and nested review evidence.
- Generated and supplied refresh warnings — including resource-filter suppression warnings and invalid source contact-filter input warnings — are preserved on the V2 repair artifact alongside source resource-filter and contact-filter report provenance, so operator-review and Cadence-import queues can see refresh-time suppression evidence.

## Station-calendar and examples

- Repair-time station-calendar annotation with `source_station_calendar_report`.
- Repaired JSON artifact examples.

## Operator-review package (`operator_review_package.v1`)

Status: **implemented**.

V2 repair `operator_review_package.v1` now emits:

- **Plan-delta review rows** for repaired timeline changes and preservation decisions, including:
  - explicit timeline-protection rows for locked, approved, or executed activities preserved or changed by repair;
  - source and replacement timeline identity/context fields on plan-delta review rows;
  - flattened source/replacement Cadence import status, import type, external ID, schema contract, and presence flags alongside invalid non-object source/replacement Cadence import evidence when repair activity contexts are malformed, while sanitizing the nested contexts before operator-review and Cadence-import validation.
- Approval requirements.
- Repair score-term and objective-tradeoff review rows.
- CandidateRefresh source operational import-eligibility summaries, preserving
  exact eligibility, classification, readiness status, gate counts, source
  identity, assumptions, and explicit no-approval/no-import limits without
  performing a Cadence write.
- CandidateRefresh source operational-readiness gate summaries, preserving exact
  gate rows, status/classification routing maps, non-passed gate IDs, source
  lineage, assumptions, and summary-only model limits without recomputing or
  changing readiness.
- CandidateRefresh source operational execution-boundary summaries, preserving
  exact handoff-only status, execution/write/operator-authority denials,
  classified boundary, operational-mode gate, assumptions, and model limits
  without granting authority or performing a write, import, or command.
- CandidateRefresh source operational quality-gate summaries, preserving exact
  rows, normalized status/classification routing maps, non-passed gate and row
  IDs, source report identity, assumptions, and model limits without
  recalculating gates or changing readiness.
- CandidateRefresh source unavailable-resource quality-gate summaries,
  preserving exact resource pressure reasons and blocked contact routing by
  blocking dimension, spacecraft, and status without changing allocation,
  reserving a station, or mutating a schedule.
- CandidateRefresh source operator-training quality-gate summaries, preserving
  exact typed requirement counts and stable operator-role, training,
  certification, and qualification IDs without granting certification,
  approval, or operator authority.
- CandidateRefresh source schema-validation quality-gate summaries, preserving
  exact pass/fail/error/warning/remediation counts and blocked/review row IDs
  without treating validation evidence as approval or performing an import.
- CandidateRefresh source import-readiness quality-gate summaries, preserving
  exact freshness, preparation, blocked/missing/invalid-import counts, row IDs,
  and publication lineage without approving or performing an import.
- CandidateRefresh source constraint fail/warning rows, preserving exact
  upstream scenario, threshold, value, score, and status evidence beside the
  recomputed repaired-plan report without changing feasibility or scoring.
- CandidateRefresh source objective-satisfaction gap rows, preserving exact
  upstream objective, target, count, selected/candidate identity, and status
  evidence without changing objective evaluation, scores, or ranking.
- CandidateRefresh source objective-tradeoff rows, preserving exact upstream
  scenario, rank, score delta, activity identity, and score-term evidence beside
  the recomputed repaired-plan report without changing scores or ranking.
- CandidateRefresh source score-term rows, preserving exact upstream stable row
  ID, scenario, rank, term key, value, timeline score, and selected state beside
  the recomputed repaired-plan report without changing scores or ranking.
- CandidateRefresh source timeline-diff review rows, preserving exact timeline
  identity, changed fields, status/approval transitions, source/replacement
  contexts, and required operator action without applying source transitions.
- CandidateRefresh source schema-validation issue rows, preserving exact
  contract/family, artifact path, validation mode/status, issue severity/path/
  message, counts, and remediation without changing V2 validation outcomes.
- CandidateRefresh source model-acceptance rows, preserving exact report/model
  identity, intended use, acceptance status, validation level, implementation,
  reason, counts, and model-limit context without certifying models or adding
  Cadence import rows.
- CandidateRefresh source validation-safety-case rows, preserving exact case/
  evidence identity, source contract/reference, evidence status, rollup counts,
  routing maps, and model-limit context without granting certification/import
  authority or adding Cadence import rows.
- CandidateRefresh source provider-counteroffer rows, preserving exact offer,
  provider/station, negotiation, reason, cost/timing, lock-deadline, and source-
  calendar context in review-gated Cadence rows without requesting, accepting,
  reserving, or executing an offer.
- CandidateRefresh source provider-counteroffer plan-impact summaries,
  preserving exact proposed timing/cost deltas, lock-deadline status, affected
  calendar identity, assumptions, and source lineage in review-gated handoffs
  without changing the repaired schedule or provider state.
- CandidateRefresh source provider-counteroffer import-readiness summaries,
  preserving exact review-only classification, review-before-import status,
  required action, lock-deadline evidence, assumptions, and source lineage
  without performing an import or provider action.
- Repaired-plan and CandidateRefresh source link-capacity review rows,
  preserving the upstream report independently from the recomputed repair
  report without applying another scoring effect.
- Repaired-plan and source contact-allocation review rows.
- CandidateRefresh source contact-allocation provider-reservation request
  summaries, preserving exact request-ready/review-required rows plus match,
  station, direction, reservation, and contact routing as review-only Cadence
  handoffs without creating a provider reservation or schedule mutation.
- Source contact-contention conflict-group and invalid-input rows, preserving
  the exact audit context for review-gated Cadence import without applying the
  group evidence to candidate eligibility or schedules.
- Source contact-contention resolution recommendation rows, preserving exact
  selected/deferred contact identities for review-gated Cadence import without
  applying the recommendation to candidate eligibility or schedules. Exact
  deferred IDs contribute one advisory `risk_weight` unit to replacement
  ranking and selected-plan scoring, with sorted resolution group IDs retained
  as the explanation; selected/recommended and unrelated IDs remain neutral.
- CandidateRefresh source station-reservation affected-contact and provider-
  contention rows, preserving exact reservation identities for review-gated
  Cadence import without requesting, accepting, expiring, or mutating a
  reservation.
- CandidateRefresh source station-reservation hold import-readiness summaries,
  preserving exact expired/missing hold IDs, provider ownership, expiration
  status, and review actions without accepting, renewing, reserving, importing,
  or writing a hold.
- CandidateRefresh source station-reservation hold summaries, preserving
  aggregate hold counts, earliest expiration, provider ownership, and complete
  review rows without creating, accepting, renewing, expiring, or mutating a
  reservation.
- CandidateRefresh source station-reservation review summaries, preserving
  row-derived reservation counts, active/expired/missing routing, provider
  ownership, and complete review rows without creating, accepting, renewing,
  expiring, or mutating a reservation.
- CandidateRefresh source station-calendar precedence summaries, preserving
  applied/overlap availability, affected contacts, and
  reserved-under-higher-precedence ownership/status routing without provider
  reservation or schedule mutation.
- Direct repair `station_calendar_provider.v1` inputs, preserving every
  declared entry plus provider identity, provenance, and assumptions as
  `source_station_calendar_provider`. The raw input remains distinct from the
  derived station-calendar report and creates no review/import row or provider
  action.
- CandidateRefresh source provider-counteroffer review summaries, preserving
  status, negotiation state, expired/missing/active lock-deadline routing,
  review IDs, and exact review rows without accepting an offer, provider writes,
  or schedule mutation.
- Source candidate-diff rows.
- Source contact/resource-suppression rows.
- Source refresh-freshness and refresh-budget review rows.
- Source resource-projection review rows.
- Warnings.

## Cadence import manifest (`cadence_import_manifest.v1`)

- V2 repair artifacts now include `cadence_import_manifest.v1` rows that convert the full repair operator-review package — including contact-allocation, link-capacity, refresh-budget, and resource-projection review rows plus typed policy-escalation authority queues — into deterministic, review-gated import actions for downstream Cadence schedule/import adapters without executing those imports.
- V3 strategy artifacts emit the same manifest contract over branch-comparison rows with selected-branch recommendation import actions and non-selected branch alternative-review rows.
- Checked-in V2 repair and V3 strategy JSON requests can be executed through public file-backed helpers that resolve `source_plan_ref` into the prior plan artifact before planning.
- V1 campaign import manifests now include station-contention recommendation review rows, and standalone contact-contention group/resolution reports can be converted into review-gated import manifests.

## Partial

Status: **partial**.

Repair consumes refreshed candidate sets, contact intents, resource summaries, refresh budget reports, and contact-allocation reports when supplied or generated from a repair refresh request, and can annotate repair source contacts from station-calendar updates. However, it:

- still has thin degraded-mode semantics;
- has no reservation/schedule-mutation model;
- has no calibrated subsystem resource simulation.

## Near-term

Status: **near-term**.

Deepen calibrated behavior behind the artifact-only review/import queues. Adapter-facing row status and deterministic source-queue summaries are now present.

## Later

Status: **later**.

Rolling-horizon service boundary, resource-aware repair, uncertainty margins, and plan-delta APIs designed for operator review.

## Out of scope

Status: **out of scope**.

Cadence realized-state database ownership or automatic operational schedule mutation.
