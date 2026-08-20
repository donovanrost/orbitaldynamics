# 14. V3 Strategy/Orchestration

Status: **implemented** (with **partial**, **near-term**, **later**, and **out of scope** notes below).

## Core entry point and artifacts

- **Entry point** — `CampaignPlanner.strategy/1`.
- **Artifacts / structs** — `MissionState`, `WhatIfScenario`, `PlanBranch`,
  `StrategyRecommendation`, `StrategicScoringPolicy`, `ApprovalPolicy`, and
  `OperationalFeedback`.
- **Branches** — explicit and derived branches.

## Branch event types

Derived from the following events:

- ground-station outage
- station reservation
- urgent target
- degraded spacecraft
- missed/delayed maneuver
- downlink completion gap by contact count or required data volume
- reduced capacity
- station-throughput feedback
- contact-success feedback
- observation-success feedback
- target-priority feedback
- fuel preservation events

Branches carry branch-specific `candidate_refresh.v1` overrides and executable
or mission-state-derived `candidate_refresh_request` inputs.

## Branch events feeding generated candidate-refresh reports

Station outage/reservation/capacity, station-throughput feedback,
contact-success feedback, observation-success feedback, target-priority
feedback, and degraded-spacecraft branch events now flow into generated
candidate-refresh filter reports.

Explicit strategy approval policy is preserved into those generated branch
refreshes, so nested contact/resource suppression, contact-allocation, and
contact-intent rows retain policy evidence plus matched escalation level,
queue, role, authority, and SLA routing metadata.

Branch events that synthesize missed/delayed realized rows preserve station
availability, contention status, reservation identity, owner, and reservation
status through realized-feedback operator-review rows and Cadence import rows,
including typed tracking and health-check station activities.

### Ground-station reservation risk flattening

Ground-station reservation risk indicators and branch-comparison rows now
flatten:

- station availability
- contention
- station-calendar entry/provider identity
- provider entry identity
- calendar direction
- calendar status
- provider trust-boundary status
- reservation identity
- reservation owner
- reservation status
- reservation match status

This lets provider- or reservation-specific approval rules route branch
candidates without reopening contact-filter reports.

Branch-comparison rows aggregate branch-event station IDs, directions,
station-calendar entry/provider IDs, calendar statuses, trust-boundary
statuses, reservation identities, owners, and match statuses, so adapter-facing
operator-review and Cadence-import rows can route branch-local ground-network
pressure without reopening raw branch events. The same station-calendar summary
fields are also flattened onto selected strategy-recommendation review/import
rows when the recommended branch carries those events.

They also preserve conflicts with provider realized feedback as duplicate
realized evidence for operator review instead of overwriting the provider row.

## Combined / derived branches and recommendation artifacts

- Opt-in combined derived mission-state branches for joint-case review.
- Structured recommendation artifacts.

## Branch comparison report

Schema-validated `branch_comparison_report.v1` rows for deterministic what-if
branch comparison, with:

- **Flattened resource-impact fields** — branch-level resource-projection
  summaries when source summaries are available, including storage-limited
  downlink and unused downlink capacity.
- **Downlink-capacity-only resource summaries** — no longer synthesize
  required-contact denominators or low-downlink branch risk unless the mission
  declares a real downlink-completion requirement.
- Row-derived resource source-quality and trust-boundary status counts.
- Repair-link selected capacity, required downlink demand, shortfall, and
  requirement status.
- Non-negative integer bounds for branch, row, branch-event, target, and
  revisit count evidence, plus downlink contact cardinalities carried into
  review/import source rows.
- Executable validation for branch-count and recommended-vs-selected branch
  consistency.
- Explicit raw score, branch probability, and expected score fields.

## Opt-in hard recommendation eligibility

V3 accepts an optional `recommendation_eligibility` request object with
`mode: "hard"`. It reuses the typed hard-feasibility configuration fields
`evidence_registry` and `candidates`; each registry parameter identity is bound
to the exact computed branch `score_terms` rather than to a caller-repinned
duplicate. The emitted eligibility surface retains the complete normalized
registry snapshot, so schema validation recomputes its content-derived identity
from the canonical entries instead of trusting a copied summary ID. The default
path does not emit the new surface and retains its existing recommendation
behavior and 22-key artifact shape.

Hard mode combines `candidate_feasibility.v1` results with each branch's
already-derived `policy_decision.v1` before ordering. Only eligible branches are
ranked, deterministically by score descending and then `branch_id` ascending.
Authority status and evidence come from the branch policy decision; request
fields cannot override that result.

When no branch is eligible, `recommended_branch_id` and
`selected_branch_id` are JSON null, the eligible ranking is empty, and no
selected recommendation review or import row is emitted. The highest-scoring
rejected branch remains as a `review_only: true`, `importable: false`
counterfactual with its hard-feasibility and policy/authority blocker evidence.
Its direct branch and derived strategy-tradeoff Cadence rows are both explicitly
review-only, carry `cadence_import_status: "not_applicable"`, and can never be
`ready_for_import`.

Malformed `CampaignPlanner.strategy/1` request options retain the public
`ArgumentError` convention. The no-raise guarantee is specifically the
`Schema.validate_artifact/2` boundary: malformed hard-mode maps, improper lists,
and non-JSON-safe values return typed schema-validation errors.
All outputs remain artifact-only and perform no Cadence writes.

## Score-term and tradeoff reports

Branch-level `score_term_report.v1` and `objective_tradeoff_report.v1` rows
over the same strategy score terms now feed typed operator-review and
Cadence-import score-term/tradeoff handoff. Optimizer, ranking-comparison,
Pareto-frontier, score-term, and objective report scalar counters are exported
and executable-validated as non-negative integers.

## Operator review package

Strategy `operator_review_package.v1` rows surface:

- **Branch repair candidate-diff rows** — from source candidate-diff reports.
- **Contact suppressions** — from source contact-filter reports, including
  nested provider-shaped station identity and exact downlink demand/completion
  source lineage on branch-local downlink pressure.
- **Contact-allocation review rows** — from source contact-allocation reports
  and repaired-activity contact-allocation reports, including same-spacecraft
  contention with branch IDs for adapter routing.

Strategy-derived branch refreshes can be inspected with the contact-contention
replay summary to route conflict groups, invalid contact inputs, resource-scope
maps, contact/station routing, and required-action pressure without mutating
contact allocation or selecting candidates.

- **Capacity-pack review/import rows** — with preserved
  `source_contention_recommendation` evidence replaying into branch-local
  contact-contention pressure while retaining capacity-pack fractions and trust
  boundaries.

Strategy-derived branch refreshes can be inspected with the
contact-contention-resolution replay summary to route recommendation/deferred
counts, resolution-status and selection-reason maps, capacity-pack demand, and
station maps without mutating contact allocation or selecting candidates.

Strategy-derived branch refreshes can be inspected with the model-acceptance
replay summary to route validation-record and model counts, intended-use/status
maps, validation-level maps, model-ID routing maps, and review/blocking/
unknown-model pressure without certifying models or approving imports.

Strategy-derived branch refreshes can be inspected with the quality-gate replay
summary to route readiness/import/status maps, gate status/classification maps,
analysis-mode counts, import blockers, schema/freshness status maps, resource
availability reason maps, and review/import pressure without approving imports
or writing to Cadence.

Strategy-derived branch refreshes can be inspected with the timeline-diff replay
summary to route duplicate timeline identities, removed activities, changed
feedback counters, status/action maps, duplicate-scope maps, and review
pressure without mutating timelines or selecting candidates.

Strategy-derived branch refreshes can be inspected with the constraint replay
summary to route downlink-gap and resource-margin counts, status maps,
station/metric/resource/spacecraft routing maps, and constraint pressure without
creating objectives, mutating resource state, or selecting candidates.

Strategy-derived branch refreshes can be inspected with the objective-gap replay
summary to route downlink, target, and collection-latency gap counts,
objective-status/type maps, score-term maps, station/target/collection routing,
and score/routing pressure without creating objectives or recalculating scores.

Strategy-derived branch refreshes can be inspected with the command-window
replay summary to route command-feedback counts, feedback input keys, and
command-window pressure without executing commands or approving imports.

Strategy-derived branch refreshes can be inspected with the maneuver-review
replay summary to route maneuver-success feedback, execution uncertainty,
feedback input keys, and maneuver-review pressure without executing maneuvers
or approving imports.

Strategy-derived branch refreshes can be inspected with the station-calendar
replay summary to route affected contacts, provider-contention groups,
provider/station/status/availability maps, and station-availability pressure
without mutating station calendars or schedules.

Strategy-derived branch refreshes can be inspected with the storage/downlink
pressure replay summary to route contact-allocation, link-capacity, and
resource-projection pressure together, including capacity-pack demand,
downlink shortfalls, throughput, station/spacecraft/contact/activity routing,
and storage/downlink flags without mutating allocation or projection state.

Strategy-derived branch refreshes can be inspected with the
timeline-transition-application replay summary to route selected/review/
withheld applications, transition decisions, required actions, duplicate
identity scopes, and operator-review pressure without applying transitions or
mutating timelines.

- **Contact-intent review/import rows** — with blocked policy or
  missing/invalid Cadence-import status replaying into branch-local downlink
  pressure, while ordinary approval-required intents remain review-only.
- **Plan-delta review/import rows** — for canceled or suppressed source work
  replaying into the existing branch-local timeline-diff removed-work pressure
  path.
- **Resource suppressions** — from source resource-filter reports with branch
  IDs for generated repair refreshes.

Prior `operator_review_package.v1` contact/resource suppression rows that
preserve `source_contact_suppression` or `source_resource_suppression` now feed
the same branch-local contact/resource pressure derivation without requiring
the original filter reports to be resubmitted, with suppression import rows
flattening `branch_id` for adapter routing.

## Source reports as branch-local review-pressure branches

The following source inputs become branch-local branches:

- **Mission-state source candidate-diff reports** — as branch-local
  candidate-diff replacement branches.
  Candidate-refresh exposes a compact candidate-diff replay summary over
  preserved source-report provenance so branch-local consumers can route
  retained/new/invalidated counts, diff reasons, semantic-change reasons,
  changed fields, candidate IDs, and station maps without regenerating or
  selecting candidates.
- **Mission-state source candidate-rejection reports** — as branch-local
  rejection review-pressure branches.
  Candidate-refresh exposes a compact candidate-rejection replay summary over
  preserved source-report provenance so branch-local consumers can route
  rejected/reviewable/invalid-input counts, rejection reasons, required
  actions, candidate IDs, and station maps without selecting or importing
  rejected candidates. Rejection reason and required-action maps are derived
  from rows when row evidence is present, so stale top-level aggregate maps do
  not drive replay pressure.
  Candidate-refresh operator-review packages also lift direct
  `source_candidate_rejection_report` / `candidate_rejection_report` rows into
  `candidate_rejection_review` rows with `candidate_refresh.*` source paths,
  including list-valued source reports, without selecting or importing rejected
  candidates.
  Result-artifact-wrapped candidate-rejection reports are lifted into the same
  review-row family with wrapper-qualified source paths.
- **Source provider-counteroffer reports** — as branch-local counteroffer
  review-pressure branches that preserve provider timing/cost/deadline
  evidence, including start/end/duration timing deltas, without accepting the
  offer.
  Candidate-refresh exposes a compact provider-counteroffer replay summary over
  preserved source-report provenance so branch-local consumers can route
  reviewable counts, cost/timing/lock pressure, plan-impact status, affected
  station/provider IDs, and counteroffer ID sets without provider writes,
  schedule mutation, or import approval. Status and required-action maps are
  derived from rows when row evidence is present, preventing stale top-level
  counteroffer aggregates from steering review pressure.
  CampaignPlanner selects `rows`, `import_readiness_rows`, or `impact_rows`
  from the matching provider-counteroffer schema contract; shadow row
  collections and unsupported contracts cannot become review-pressure branches.
  Branch-generated refresh requests preserve direct and `source_result_artifact`
  / `result_artifact`-wrapped plan-impact summaries with wrapper-qualified
  source paths, affected station/provider maps, counteroffer ID sets, timing
  deltas, lock evidence, and inherited trust-boundary evidence.
  Candidate-refresh operator-review packages also lift direct
  `source_provider_counteroffer_plan_impact_summary` /
  `provider_counteroffer_plan_impact_summary` impact rows into
  `provider_counteroffer_review` rows with `candidate_refresh.*` source paths,
  without accepting offers, mutating schedules, or approving imports.
  Result-artifact-wrapped provider-counteroffer reports and plan-impact
  summaries are lifted into the same review-row family with wrapper-qualified
  source paths.
- **Source schema-validation reports** — as branch-local validation
  review-pressure branches that preserve issue/remediation evidence without
  changing candidate selection. Direct/list-valued schema-validation batch
  inputs are flattened to their nested report entries with batch-entry paths
  preserved.
  Branch-generated refresh requests carry direct mission-state batch inputs and
  `source_result_artifact` / `result_artifact` wrapped batch reports, preserving
  flattened nested report paths and inherited trust-boundary evidence.
  Candidate-refresh exposes a compact schema-validation replay summary over
  preserved source-report provenance so branch-local consumers can route
  validation status, contract/mode, error/warning, and remediation pressure
  without regenerating refresh candidates.
  Candidate-refresh operator-review packages also lift direct/list-valued
  source schema-validation batch report entries into `schema_validation_review`
  rows with indexed `candidate_refresh.*.reports[N].report` source paths.
- **Source operational-readiness reports** — as branch-local readiness
  review-pressure branches that preserve non-importable summary/gate evidence
  without approving operator actions or writing to Cadence.
  Candidate-refresh exposes a compact operational-readiness replay summary over
  the preserved source-report provenance so branch-local consumers can route
  readiness gate, import, freshness, schema-validation, adapter-boundary, and
  resource-pressure evidence without regenerating refresh candidates.
  Branch-generated refresh requests preserve direct and result-artifact-wrapped
  operational-readiness reports with wrapper-qualified request input paths and
  indexed embedded replay copies.
  Candidate-refresh operator-review packages also lift operational-readiness
  reports wrapped in `source_result_artifact` / `result_artifact` containers
  into `operational_readiness_review` summary/gate rows with wrapper-qualified
  source paths.
- **Source quality-gate reports** — as branch-local gate review-pressure
  branches that preserve non-passed gate rows with row-derived
  readiness/status/count context and resource-availability reason IDs/counts
  without approving operator actions or writing to Cadence.
  Candidate-refresh also exposes a compact quality-gate replay summary over
  the preserved source-report provenance so branch-local consumers can route
  review/import pressure from the same gate, freshness, schema-validation, and
  resource-availability maps without regenerating refresh candidates.
  Branch-generated refresh requests preserve direct and result-artifact-wrapped
  quality-gate reports with wrapper-qualified request input paths and indexed
  embedded replay copies.
- **Source model-acceptance reports** — as branch-local validation
  review-pressure branches that preserve model ID, intended-use,
  validation-level, and acceptance-status evidence plus model-ID routing maps
  without certifying models, with branch-event schema validation rejecting
  malformed routing maps.
  Candidate-refresh exposes a compact model-acceptance replay summary over the
  preserved source-report provenance so branch-local consumers can route
  review, blocking, unknown-model, intended-use, validation-level, and model-ID
  evidence without certifying models or regenerating refresh candidates.
  Branch-generated refresh requests preserve direct and result-artifact-wrapped
  model-acceptance reports with wrapper-qualified request input paths and indexed
  embedded replay copies.
  Validation-level counts and model-ID routing maps come from rows when present,
  preventing stale top-level model-acceptance aggregates from steering
  branch-local pressure.
  Candidate-refresh operator-review packages also lift direct/list-valued
  source model-acceptance rows that require review or are blocked into
  `model_acceptance_review` rows with indexed `candidate_refresh.*.rows` source
  paths, source row payloads, and report-level count context, without
  certifying models or approving imports.
  Model-acceptance reports wrapped in `source_result_artifact` /
  `result_artifact` containers are lifted into the same review-row family with
  wrapper-qualified source paths.
- **Source validation-safety-case summaries** — as branch-local validation
  review-pressure branches that preserve evidence status, input contract,
  evidence-reference maps, aggregate safety counts, trust boundary, and source
  path without certifying models or approving imports.
  Candidate-refresh exposes a compact validation-safety-case replay summary
  over the preserved source-report provenance so branch-local consumers can
  route evidence status, input-contract, evidence-reference, schema, fixture,
  model, readiness, and quality-gate pressure without certifying safety cases
  or regenerating refresh candidates. Evidence-status maps come from evidence
  rows when present, preventing stale top-level `evidence_status_counts`
  aggregates from steering review/blocking pressure.
  Strategy-derived branch refreshes can be inspected through that replay summary
  from V3 branch `candidate_source` metadata without certifying safety cases,
  accepting models, approving imports, or writing to Cadence.
  Branch-generated refresh requests preserve direct and `source_result_artifact`
  / `result_artifact`-wrapped `source_validation_safety_case_summary` /
  `validation_safety_case_summary` inputs with wrapper-qualified source paths,
  evidence maps, and inherited trust-boundary evidence; the replay remains
  artifact-only and does not certify, approve, import, or write.
  Candidate-refresh operator-review packages also lift direct/list-valued
  source validation-safety evidence rows that require review or are blocked
  into `validation_safety_case_review` rows with indexed
  `candidate_refresh.*.evidence` source paths, source evidence payloads,
  evidence refs, input contracts, and summary count context, without certifying
  safety cases or approving imports.
  Result-artifact-wrapped validation-safety summaries are lifted into the same
  review-row family with wrapper-qualified source paths.
- **Source freshness and refresh-budget reports** — as branch-scoped
  `freshness_review`/`review_refresh_freshness` and
  `refresh_budget_review`/`review_refresh_budget` rows.
  Candidate-refresh exposes a compact freshness replay summary over preserved
  source-report provenance so branch-local consumers can route stale/unknown
  freshness pressure and reason counts without regenerating refresh candidates.
  Branch-generated refresh requests preserve direct and result-artifact-wrapped
  mission-state freshness reports with wrapper-qualified request input paths and
  indexed embedded replay copies.
  It also exposes a compact refresh-budget replay summary so consumers can
  route input/kept/dropped candidate counts, invalid-limit reasons, and
  kept/dropped candidate IDs without mutating refresh state.
  Branch-generated refresh requests preserve direct and result-artifact-wrapped
  mission-state refresh-budget reports with wrapper-qualified request input
  paths and indexed embedded replay copies.
  Candidate-refresh operator-review packages also lift direct
  `source_freshness_report` / `freshness_report` stale or unknown summaries and
  direct `source_refresh_budget_report` / `refresh_budget_report`
  dropped-candidate or invalid-limit summaries into `freshness_review` and
  `refresh_budget_review` rows with `candidate_refresh.*` source paths, without
  mutating refresh state, approving imports, writing to Cadence, or regenerating
  candidates. The same operator-review handoff accepts freshness and
  refresh-budget reports preserved under candidate-refresh
  `source_result_artifact` / `result_artifact` wrappers while retaining
  wrapper-qualified source paths.

The same candidate-diff, provider-counteroffer reports,
provider-counteroffer import-readiness summaries, provider-counteroffer
plan-impact summaries, schema-validation,
operational-readiness, quality-gate, model-acceptance, freshness,
refresh-budget, station-reservation reports, station-reservation hold summaries,
station-reservation hold import-readiness summaries, and contact-contention
resolution summaries are accepted from mission-state `source_result_artifact` /
`result_artifact` wrappers while preserving nested source paths and inherited
wrapper trust boundaries in branch events and generated candidate-source audit
paths.
Strategy-derived branch refreshes can
be inspected with the candidate-diff replay summary to route diff reasons,
invalidated reasons, semantic-change reasons, changed fields, and
candidate/station routing without regenerating candidates. They can be
inspected with the candidate-rejection replay summary to route rejected,
reviewable, and invalid-input counts plus rejection reasons, required actions,
and candidate/station routing without importing rejected candidates. They can
be inspected with the provider-counteroffer replay summary to route reviewable
counteroffer counts, provider status/action maps, plan-impact evidence, and
trust-boundary pressure from direct and wrapper-extracted plan-impact summaries
without accepting offers or mutating schedules. They can
be inspected with the operational-readiness replay summary to route readiness,
import-classification, status, gate-count, review/import, resource-pressure,
and trust-boundary evidence without granting operator authority or Cadence
writes. They can
be inspected with the freshness replay summary to route freshness status,
stale/unknown reasons, source paths, and freshness pressure without mutating
candidates or approving imports. They can
be inspected with the refresh-budget replay summary to route input, kept,
dropped, and invalid-limit counts plus candidate ID routing without mutating
candidates or approving imports. They can
be inspected with the contact-filter replay summary to route suppressed
candidates, invalid contact inputs, suppression reasons, and station
suppression maps without mutating contact allocation or selecting candidates.
They can
be inspected with the resource-filter replay summary to route suppressed
candidates, invalid resource-summary inputs, suppression reasons, and
spacecraft/resource/blocking-dimension maps without mutating resource filtering
or selecting candidates. They can
be inspected with the resource-projection replay summary to route projected
resources, invalid projection inputs, pressure statuses/types/activity IDs, and
station/spacecraft maps from direct resource-projection reports plus direct and
wrapper-extracted resource-projection flow summaries without mutating resource
projection or selecting candidates. Candidate-refresh operator-review packages
also lift direct `source_resource_projection_flow_summary` /
`resource_projection_flow_summary` projected resources into
`resource_projection_review` rows with `candidate_refresh.*` source paths,
preserving flow-summary context without mutating resource projection or
selecting candidates. They can
be inspected with the link-capacity replay summary to route selected/actual
shortfall, capacity-adjusted throughput, selected/actual contact IDs, downlink
status, and station maps without mutating contact allocation or selecting
candidates. They can
be inspected with the contact-allocation replay summary to route
blocked/deferred allocation rows, allocation and capacity-pack status maps,
capacity-pack demand totals, and station/status maps without mutating contact
allocation or selecting candidates. They can
be inspected with the schema-validation replay summary to route validation
status, validated-contract, validation-mode, error, remediation, source-path,
and trust-boundary pressure without approving imports. They can
be inspected with the contact-intent replay summary to route station-feedback,
station-calendar, import-status, policy, capacity-pack, and trust-boundary
pressure without generating contacts or approving imports. They can also be
inspected with the station-reservation replay summary to route reservation
review, hold import-readiness, expiration, match-status, and provider-contention
pressure without reserving provider time, accepting holds, or mutating station
calendars.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
station-reservation hold import-readiness summaries with wrapper-qualified
request input paths and inherited trust-boundary evidence.
Planner pressure reconstruction reads `review_rows` only from reservation-review
and hold summaries and `import_readiness_rows` only from hold import-readiness
summaries. It derives branches only for the declared `affected_contact` and
`provider_calendar_contention_group` row types, so shadow collections or unknown
row kinds cannot become station-reservation decisions while canonical rows can
still recover from stale redundant aggregates.

Also surfaced:

- Branch-local refresh warnings as branch-scoped warning review/import rows.
- Branch-local `resource_projection_report.v1` rows.
- Branch repair realized-feedback rows from
  `source_timeline_feedback_report.v1`.
- Candidate-refresh operator-review packages lift direct
  `source_timeline_feedback_report.v1` rows into `realized_feedback` review
  rows without applying feedback, mutating timelines, approving imports, or
  writing to Cadence.
- Candidate-refresh operator-review packages lift direct
  `source_candidate_diff_report` / `candidate_diff_report` invalidated,
  reviewable-new, and changed-retained rows into `candidate_diff_review` rows
  with `candidate_refresh.*` source paths without mutating refresh state or
  selecting candidates.
- Branch-generated CandidateRefresh requests preserve direct mission-state and
  result-artifact-wrapped raw `source_candidate_rejection_report` /
  `candidate_rejection_report` inputs with wrapper-qualified request paths and
  indexed embedded replay copies, keeping rejection reasons, required-action
  maps, candidate/station routing, and inherited trust-boundary evidence visible
  at the branch provenance boundary.
- Branch-generated CandidateRefresh requests preserve direct mission-state and
  result-artifact-wrapped raw `source_candidate_diff_report` /
  `candidate_diff_report` inputs with wrapper-qualified request paths and
  indexed embedded replay copies, keeping diff/invalidated/semantic-change
  reasons, changed-field maps, candidate/station routing, and inherited
  trust-boundary evidence visible at the branch provenance boundary.
- Branch-generated CandidateRefresh requests preserve direct mission-state and
  result-artifact-wrapped raw `source_provider_counteroffer_report` /
  `provider_counteroffer_report` inputs with wrapper-qualified request paths and
  indexed embedded replay copies, keeping row-derived status/action maps,
  cost/timing/lock evidence, and inherited trust-boundary evidence visible at
  the branch provenance boundary.
- Candidate-refresh operator-review packages lift direct
  `source_provider_counteroffer_report.v1` rows into
  `provider_counteroffer_review` rows without accepting offers, mutating
  schedules, approving imports, or writing to Cadence.
- Candidate-refresh operator-review packages lift direct
  `source_station_reservation_report` / `station_reservation_report`
  affected-contact and provider-contention rows into
  `station_reservation_review` rows without reserving provider time or mutating
  station calendars. The same operator-review handoff accepts reservation
  reports preserved under candidate-refresh `source_result_artifact` /
  `result_artifact` wrappers while retaining wrapper-qualified source paths.
- Branch-generated candidate-refresh requests now carry direct and
  result-artifact-wrapped raw `source_station_reservation_report` /
  `station_reservation_report` inputs, preserving reservation review,
  direction, owner, match/status, expiration, provider-contention, and
  trust-boundary evidence in generated candidate-source provenance.

## V2 repair artifacts as V3 source input

When a V2 repair artifact is used as V3 source input, its
`source_timeline_feedback_report.operational_feedback` maps, plus
`timeline_feedback_report.v1` maps embedded in single or list-valued prior
`source_result_artifact` / `result_artifact` wrappers, are normalized into the
strategy `operational_feedback` input before explicit request overrides. This
lets repair-time contact, station-throughput, observation, command, maneuver,
and downlink-demand feedback drive branch scoring and refresh derivation
without callers resubmitting raw provider rows.

## Live mission-state operational-feedback replay

- Supplied `mission_state.operational_timeline_report` rows are now replayed
  through the same operational-feedback and derived-branch path as prior
  operational timeline rows, so live mission-state timeline exports can drive
  branch-local contact, station-throughput, command, and maneuver feedback
  before explicit mission/request feedback overrides.
- Mission-state `source_result_artifact` / `result_artifact` wrappers that
  embed `operational_feedback`, `timeline_feedback_report`, or
  `operational_timeline_report` now feed those same live operational-feedback
  paths while preserving wrapper or nested feedback trust boundaries.
- Branch-generated refresh requests also pass direct mission-state
  timeline-feedback and operational-timeline reports through as typed top-level
  `candidate_refresh.v1` `source_*` inputs, while wrapped
  `source_result_artifact` / `result_artifact` reports retain wrapper-qualified
  source paths, row counts, and trust-boundary evidence in generated candidate
  source provenance.

Candidate-refresh exposes a compact timeline-feedback replay summary over
preserved source-report provenance so branch-local consumers can route feedback
input keys, status, feedback-kind, match-strategy, station-reservation
evidence, and trust-boundary evidence without applying operational feedback,
mutating timelines, selecting candidates, approving imports, writing to
Cadence, or regenerating refresh candidates. Source timeline-feedback
operational-feedback provenance derives status, feedback-kind, match-strategy,
and Cadence-import status maps from rows when rows are present, preventing stale
top-level feedback aggregates from steering branch-local feedback pressure.
Candidate-refresh operator-review packages also lift direct
`source_timeline_feedback_report` / `timeline_feedback_report` rows and
timeline-feedback reports preserved in `source_result_artifact` /
`result_artifact` wrappers into `realized_feedback` rows with
`candidate_refresh.*` source paths, preserving the same no-feedback-application
and no-import-approval boundary.
Strategy-derived branch refreshes can be inspected through that replay summary
from V3 branch `candidate_source` metadata without applying operational
feedback, mutating timelines, approving imports, or writing to Cadence.

It also exposes a compact operational-timeline replay summary so consumers can
route contact, command, maneuver, observation, station-throughput, row-derived
operational-kind/status/action/import maps, integrity, station-reservation,
input-key, and trust-boundary evidence without applying operational feedback,
mutating timelines, selecting candidates, approving imports, writing to
Cadence, or regenerating refresh candidates. Operational-feedback provenance
for source operational-timeline reports also derives required-action maps from
rows when rows are present, preventing stale top-level required-action
aggregates from steering branch-local feedback pressure.
Strategy-derived branch refreshes can be inspected through that replay summary
from V3 branch `candidate_source` metadata without applying operational
feedback, mutating timelines, approving imports, or writing to Cadence.

### Command-window and maneuver-review replay

- Mission-state command-window and maneuver-review reports now replay through
  the same strategy operational-feedback and derived-branch paths as prior-plan
  reports.
- Generated branch refreshes keep those typed reports under
  `candidate_refresh.mission_state`, so command and maneuver feedback
  provenance records live report paths, weighted rows, and execution
  uncertainty counts.
- The same command-window and maneuver-review report classes are accepted from
  mission-state result-artifact wrappers while inheriting wrapper trust
  boundaries.
- Candidate-refresh exposes the command-window slice as a branch-local replay
  summary with row counts, command-feedback counts, input keys, trust-boundary
  evidence, and no-command-execution/no-selection/no-import boundaries.
  Source command-window operational-feedback provenance derives required-action
  maps from rows when rows are present, preventing stale top-level action maps
  from steering branch-local feedback pressure.
- Candidate-refresh exposes the maneuver-review slice as a branch-local replay
  summary with row counts, maneuver-success feedback counts,
  execution-uncertainty declared/missing counts, input keys, trust-boundary
  evidence, and no-maneuver-execution/no-selection/no-import boundaries.
  Source maneuver-review operational-feedback provenance derives required-action
  maps from rows when rows are present, preventing stale top-level action maps
  from steering branch-local feedback pressure.

Operational-feedback provenance for operational-timeline, timeline-diff,
command-window, and maneuver-review source reports now flows through a shared
compact replay boundary, preserving derived flags, paths, counts,
trust-boundary evidence, row-derived maps, and deterministic input-key merging
without changing the no-execution/no-selection/no-import artifact boundary.

### Resource-projection and resource-filter replay

Mission-state resource-projection and resource-filter reports now likewise
replay into branch-local resource pressure and generated refresh requests, so
live resource shortfalls or suppressions can regenerate candidate refreshes
with the same source labels, trust boundaries, resource summaries, and
suppression evidence as prior-plan report handoffs. Candidate-refresh also
exposes the resource-filter slice as a branch-local replay summary with
suppressed/invalid counts, suppression-reason maps, spacecraft/resource/
blocking-dimension maps, trust-boundary evidence, and no-filter/no-selection/
no-import boundaries, and exposes the resource-projection slice with
projected/invalid counts, resource-pressure status/type/activity maps,
station/spacecraft maps, trust-boundary evidence, and no-projection/
no-selection/no-import boundaries.
Candidate-refresh operator-review packages also lift direct
`source_resource_filter_report` / `resource_filter_report` suppressed candidate
rows and invalid resource-summary inputs into `resource_suppression` rows,
preserving source paths, spacecraft/resource context, policy evidence, and
source row payloads without mutating resource filtering or selecting
candidates.
They also lift the same resource-filter rows when reports are preserved under
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
retaining wrapper-qualified `candidate_refresh.*` source paths and indexed
list positions.
Branch-generated candidate-refresh requests also carry direct and
`source_result_artifact` / `result_artifact` wrapped
`source_resource_filter_summary` / `resource_filter_summary` inputs, preserving
compact summary contracts, review rows, invalid resource-summary inputs,
suppression maps, source paths, and trust-boundary evidence through branch-local
replay without rerunning resource filtering.
They also preserve direct and result-artifact-wrapped
`source_resource_filter_report` / `resource_filter_report` inputs with
wrapper-qualified request paths and indexed embedded replay copies.
Branch-generated CandidateRefresh requests preserve direct mission-state and
result-artifact-wrapped raw `source_resource_projection_report` /
`resource_projection_report` inputs with wrapper-qualified request paths and
indexed embedded replay copies, keeping projected-resource and invalid-input
counts, resource-pressure status/type/activity/station/spacecraft/direction
routing, source-window/station-calendar/provider-entry routing, and inherited
trust-boundary evidence visible at the branch provenance boundary.
They also lift direct `source_resource_projection_report` /
`resource_projection_report` projected-resource rows, invalid activity inputs,
and invalid resource-summary inputs into `resource_projection_review` rows,
preserving source paths, spacecraft/activity/resource-pressure context, policy
evidence, and source row payloads without mutating resource projection or
selecting candidates.
The same operator-review handoff now applies when resource-projection reports
or flow summaries are preserved under candidate-refresh `source_result_artifact`
/ `result_artifact` wrappers, retaining wrapper-qualified `candidate_refresh.*`
source paths and indexed list positions.

### Timeline-diff replay

Mission-state timeline-diff reports now replay removed observation/downlink
rows into target-revisit and downlink-completion branches. Mission-state
`source_result_artifact` / `result_artifact` wrappers that embed timeline-diff
or timeline-transition-application reports replay through those same
branch-local timeline pressure paths while inheriting wrapper trust boundaries.

Candidate-refresh exposes a compact timeline-diff replay summary over the
preserved source-report provenance so branch-local consumers can route source
paths, duplicate identity counts/maps, removed work, changed activity feedback,
status/action maps, trust-boundary evidence, and operator-review pressure
without mutating timelines, selecting candidates, approving imports, writing to
Cadence, or regenerating refresh candidates. Timeline-diff operational-feedback
provenance derives status/action maps from rows when rows are present, so stale
top-level timeline-diff aggregates cannot steer branch-local feedback pressure.
Candidate-refresh operator-review packages also lift direct
`source_timeline_diff_report` / `timeline_diff_report` review rows and
timeline-diff reports preserved in `source_result_artifact` /
`result_artifact` wrappers into `timeline_diff_review` rows with
`candidate_refresh.*` source paths, preserving the same no-timeline-mutation
and no-selection boundary.
Branch-generated candidate-refresh requests also carry direct and
`source_result_artifact` / `result_artifact` wrapped
`source_timeline_diff_report` / `timeline_diff_report` and
`source_timeline_diff_summary` / `timeline_diff_summary` inputs, preserving raw
row evidence, summary contracts, review rows, aggregate status/action maps,
source paths, and trust-boundary evidence through branch-local replay.
Timeline dependency-impact summaries now have the same branch-local replay
boundary: direct summaries plus operator-review and Cadence-import
dependency-impact rows preserve impacted source/dependency/exclusivity IDs,
dependent activity/timeline routing, source/replacement scope counts, and
operator-review pressure without mutating timelines, selecting candidates,
approving imports, writing to Cadence, or regenerating refresh candidates.
Branch-generated candidate-refresh requests also carry direct and
`source_result_artifact` / `result_artifact` wrapped
`source_timeline_dependency_impact_summary` /
`timeline_dependency_impact_summary` inputs, preserving wrapper-qualified source
paths, dependency/exclusivity impact routing, trust-boundary evidence, and
artifact-only no-mutation/no-import assumptions.
Branch-generated requests also carry direct and wrapped
`source_timeline_transition_application_summary` /
`timeline_transition_application_summary` inputs, preserving selected/review
application counts, transition decisions, required actions, timeline routing,
trust-boundary evidence, and artifact-only no-application/no-mutation
assumptions.
They also carry direct and wrapped `source_timeline_integrity_report` /
`timeline_integrity_report` inputs, preserving issue/review counts, dependency
and exclusivity routing, required actions, review activity/timeline IDs,
trust-boundary evidence, and artifact-only no-mutation/no-import assumptions.
Mission-state timeline lifecycle-state summaries also flow into branch-generated
candidate-refresh requests. Direct and `source_result_artifact` /
`result_artifact` wrapped `source_timeline_lifecycle_state_summary` /
`timeline_lifecycle_state_summary` inputs preserve source paths, lifecycle
review/recordable/preserved counts, transition action/status/approval maps,
review activity/timeline routing, and trust-boundary evidence on generated
candidate-source provenance so branch-local consumers can replay lifecycle-state
pressure without applying lifecycle transitions or mutating timelines. V3
branch pressure derives review, duplicate-identity, and invalid-input pressure
from row-local lifecycle evidence when rows are present, so stale top-level
summary aggregates cannot hide row-local lifecycle review pressure.
The same branch-refresh request source map carries direct and wrapped
`source_timeline_activity_state` / `timeline_activity_state` artifacts,
preserving single-activity state rows, activity/timeline identity, routing
pressure, trust-boundary evidence, and artifact-only no-mutation assumptions for
CandidateRefresh replay. It also carries direct and wrapped
`source_timeline_activity_status_state` /
`timeline_activity_status_state` artifacts, preserving single-activity status
transitions, record actions, import routing, activity/timeline identity, and
artifact-only no-mutation assumptions for CandidateRefresh replay. It also
carries direct and wrapped `source_timeline_activity_approval_state` /
`timeline_activity_approval_state` artifacts, preserving single-activity
approval transitions, review actions, import routing, activity/timeline
identity, trust-boundary evidence, and artifact-only no-operator-authority
assumptions. The source map also
carries direct and wrapped
`source_timeline_activity_lifecycle_state` /
`timeline_activity_lifecycle_state` artifacts, preserving single-activity
status/approval transitions, required actions, activity/timeline routing, and
artifact-only no-mutation assumptions for CandidateRefresh replay.

Generated candidate sources expose typed `source_report_input_paths`, so
objective-style source reports remain auditable even when they do not
contribute operational feedback provenance. The same audit path now covers the
expanded CandidateRefresh source-summary surface, including relay data path,
operational-readiness sub-summary, provider-counteroffer review,
station-reservation review, operational quality-gate summary,
timeline-precondition, timeline-preservation, and timeline-publication
families across direct, mission-state, and result-artifact-wrapped inputs.
Timeline-integrity risk rows contribute to
`timeline_integrity_pressure_penalty`, dependency-impact risk rows contribute
to `timeline_dependency_impact_pressure_penalty`, publication risk rows
contribute to `timeline_publication_pressure_penalty`, lifecycle-state risk
rows contribute to `timeline_lifecycle_pressure_penalty`, and
activity-precondition risk rows contribute to
`timeline_precondition_pressure_penalty`, and preservation risk rows contribute
to `timeline_preservation_pressure_penalty`, leaving the legacy
`timeline_pressure_penalty` as an empty compatibility term and the standard
strategy `risk_penalty` for unrelated risks while preserving the same
one-`risk_weight` total penalty per risk indicator. Score-term reports and
tradeoffs therefore expose
dependency/exclusivity integrity, dependency-impact, publication, lifecycle, and
precondition/preservation pressure separately without changing branch ranking
for fixed inputs.
Recommendation tradeoffs also expose `priority_commitment` so selected-branch
objective explanations retain the priority-commitment score contribution that
already affects branch ranking.
V3 branch pressure derives activity-precondition status, blocked/review counts,
and blocked/review type lists from precondition rows when row evidence is
present, so stale top-level aggregate status/count/type fields cannot hide
row-local blocked or review-required pressure.
Challenge coverage also verifies stale top-level preservation aggregates cannot
mask row-local preservation-required or review-change pressure in V3 score-term
reports.
Storage/downlink resource-pressure risks, including storage/downlink margin
pressure and projected storage overflow/downlink shortfall, similarly contribute
to `storage_downlink_pressure_penalty` so score-term reports can distinguish
fleet resource pressure from unrelated risk while preserving total score math.
Link-capacity-derived shortfall risks contribute to
`link_capacity_pressure_penalty`, leaving generic `risk_penalty` for unrelated
risks while preserving total branch score compatibility.
Contact-intent-derived review/import risks contribute to
`contact_intent_pressure_penalty`, leaving generic `risk_penalty` for unrelated
risks while preserving total branch score compatibility.
Contact-contention and contention-resolution risks contribute to
`contact_contention_pressure_penalty`, leaving generic `risk_penalty` for
unrelated risks while preserving total branch score compatibility.
Contact-allocation station-reservation conflicts contribute to
`station_reservation_conflict_pressure_penalty`, so overlapping reservation
pressure is visible separately from broader contact-allocation review pressure.
Contact-filter downlink suppression risks contribute to
`contact_filter_pressure_penalty`, leaving generic `risk_penalty` for unrelated
risks while preserving total branch score compatibility.
Resource-filter suppression risks contribute to
`resource_filter_pressure_penalty`, leaving broader resource-availability and
resource-margin pressure terms for non-filtered resource evidence while
preserving total branch score compatibility.
Resource-availability risks, including resource-projection payload/antenna
unavailability, degraded-payload, and activity-type suppression/incompatibility
pressure, contribute to `resource_availability_pressure_penalty`, leaving
generic `risk_penalty` for unrelated risks while resource-margin storage/downlink
pressure remains in `storage_downlink_pressure_penalty`.
Fuel, power, and thermal margin risks contribute to
`resource_margin_pressure_penalty`, leaving generic `risk_penalty` for
unrelated risks while storage/downlink margin pressure remains in
`storage_downlink_pressure_penalty`.
Resource-projection battery-depletion risks contribute to
`battery_depletion_pressure_penalty`, leaving generic `risk_penalty` for
unrelated risks while storage/downlink projection pressure remains in
`storage_downlink_pressure_penalty`.
Station-calendar pressure risks, including reserved, unavailable, and
reduced-capacity station feedback, contribute to
`station_calendar_pressure_penalty`, leaving generic `risk_penalty` for
unrelated risks while preserving the same total penalty per risk indicator.
Expired or missing station-reservation deadlines are split into
`station_reservation_expiration_pressure_penalty`, so hold-expiration pressure
from station-reservation review/import-readiness summaries is visible without
double-counting it as generic station-calendar score pressure.
Candidate-rejection pressure risks similarly contribute to
`candidate_rejection_pressure_penalty`, so rejected-candidate review evidence
from typed activity reports remains visible in score terms instead of blending
into generic risk.
Provider-counteroffer review risks contribute to
`provider_counteroffer_pressure_penalty`, keeping provider negotiation pressure
visible as its own score dimension without granting provider-write authority.
Provider-reservation request review risks contribute to
`provider_reservation_request_pressure_penalty`, keeping provider request
pressure visible as its own score dimension without allocating contacts or
writing provider reservations.
Relay data-path pressure risks contribute to
`relay_data_path_pressure_penalty`, keeping custody, latency, and route-risk
pressure visible as its own score dimension without scheduling relays, mutating
contacts, or writing provider reservations.
Contact-success, observation-success, station-throughput, command-success,
maneuver-success, and maneuver execution-uncertainty risks contribute to
`execution_feedback_pressure_penalty`, keeping execution-feedback pressure
visible as its own score dimension while preserving the existing feedback
adjustment score and without approving timeline changes.

### Constraint, objective, tradeoff, and score-term replay

- **Constraint reports** — Mission-state constraint reports now replay failed
  or warning resource-margin and routed downlink-shortfall rows through the
  same branch-local pressure path as prior-plan constraint reports, preserving
  live constraint source paths, trust boundaries, and generated refresh
  source-report input paths and provenance summary counts. The same constraint
  rows can replay from mission-state `source_result_artifact` /
  `result_artifact` wrappers while inheriting wrapper trust-boundary evidence,
  including list-valued embedded report keys that retain indexed
  candidate-source audit paths.
- **Objective-satisfaction reports** — Mission-state objective-satisfaction
  reports now replay unmet or partial downlink-completion rows into
  branch-local refresh pressure with the same candidate-source audit paths,
  without resubmitting the same source report as a duplicate refresh objective,
  and expose status/objective-type counts in source-report provenance.
- **Objective-tradeoff and score-term reports** — Mission-state
  objective-tradeoff and score-term reports now replay routed
  collection-latency and downlink-gap rows into the same branch-local refresh
  pressure paths as prior-plan reports while preserving live report source
  paths, trust boundaries, candidate-source audit evidence, and source-report
  provenance counts without duplicating them as raw refresh objectives,
  including when the reports are embedded in mission-state
  `source_result_artifact` / `result_artifact` wrappers and inherit wrapper
  trust-boundary evidence, with indexed source paths preserved for list-valued
  embedded report keys.

Candidate-refresh exposes a compact objective-gap replay summary over the
preserved objective-satisfaction, objective-tradeoff, and score-term
source-report provenance so branch-local consumers can route downlink, target,
collection-latency, status/type, score-term, station, target, collection, and
trust-boundary evidence without creating objectives, recalculating scores,
selecting candidates, approving imports, writing to Cadence, or regenerating
refresh candidates. Its contract list is derived from the source-report
families that are actually present, so a single-family replay summary does not
imply missing objective-gap report provenance.
Candidate-refresh operator-review packages also lift direct
`source_objective_satisfaction_report` / `objective_satisfaction_report`
non-passing rows and objective-satisfaction reports preserved in
`source_result_artifact` / `result_artifact` wrappers into
`objective_satisfaction_review` rows with `candidate_refresh.*` source paths,
preserving the same no-objective-creation, no-score-recalculation, and
no-selection boundary.
Branch-generated refresh requests now preserve those mission-state
result-artifact-wrapped objective-satisfaction reports with wrapper-qualified
request paths, indexed embedded replay copies, objective status/type and
downlink routing summaries, and inherited trust-boundary evidence.
They also lift direct `source_score_term_report` / `score_term_report` rows and
score-term reports preserved in `source_result_artifact` / `result_artifact`
wrappers into `score_term_review` rows with `candidate_refresh.*` source paths,
preserving the same no-score-recalculation and no-selection boundary.
Branch-generated refresh requests now preserve those mission-state
result-artifact-wrapped score-term reports with wrapper-qualified request paths,
indexed embedded replay copies, score-term key and downlink routing summaries,
and inherited trust-boundary evidence.
They also lift direct `source_objective_tradeoff_report` /
`objective_tradeoff_report` rows and objective-tradeoff reports preserved in
`source_result_artifact` / `result_artifact` wrappers into
`objective_tradeoff_review` rows with `candidate_refresh.*` source paths,
preserving the same no-score-recalculation and no-selection boundary.
Branch-generated refresh requests now preserve those mission-state
result-artifact-wrapped objective-tradeoff reports with wrapper-qualified
request paths, indexed embedded replay copies, tradeoff downlink and
collection-latency routing summaries, and inherited trust-boundary evidence.

It also exposes a compact constraint replay summary over preserved constraint
source-report provenance so branch-local consumers can route downlink-gap,
resource-margin, status, station, metric, resource, spacecraft, and
trust-boundary evidence without creating objectives, mutating resource state,
selecting candidates, approving imports, writing to Cadence, or regenerating
refresh candidates.
Candidate-refresh operator-review packages also lift direct
`source_constraint_report` / `constraint_report` non-passing rows and
constraint reports preserved in `source_result_artifact` / `result_artifact`
wrappers into `constraint_review` rows with `candidate_refresh.*` source paths,
preserving the same no-objective-creation and no-resource-mutation boundary.
Branch-generated refresh requests also preserve mission-state result-artifact
wrapped `source_constraint_report` and `constraint_report` inputs with
wrapper-qualified request paths, indexed embedded replay copies, constraint
routing summaries, and inherited trust-boundary evidence.

## Repair-generated candidate sources and refresh bundle discovery

Repair-generated candidate sources now also enumerate supplied canonical and
`source_*` `candidate_refresh` / accepted-state / mission-state source report
inputs for the same timeline-diff, constraint, objective, resource, contact,
station-calendar, station-reservation, freshness, budget,
operational-readiness, and candidate-diff report classes, so passive report
inputs stay auditable without forcing them into branch events.

Branch-generated refresh requests now build the
`candidate_refresh.mission_state` source-report bundle from wrapper-aware
mission-state report discovery, so communications, contact-contention,
resource, timeline-diff, command-window, maneuver-review, station-reservation,
freshness, budget, schema-validation, operational-readiness, quality-gate,
model-acceptance, and candidate-diff reports embedded under either canonical
report keys or `source_*_report` keys in live mission-state
`source_result_artifact` / `result_artifact` wrappers remain visible to branch
replay, CandidateRefresh provenance, and source-report summaries. Branch candidate-source audit preserves
candidate-diff reason maps, changed-field maps, candidate/station routing maps,
normalized wrapper source paths, and inherited wrapper trust-boundary evidence
without mutating provider state or changing branch selection.

Explicit branch events that cite mission-state source-report or source-summary
feedback paths also canonicalize those paths on `candidate_source`, so summary
families such as validation safety cases remain auditable even when the branch
does not generate a fresh candidate-refresh request.

Branch-generated candidate sources also record normalized review/import
container paths such as
`mission_state.source_operator_review_package.rows.source_schema_validation_report`
and
`mission_state.source_cadence_import_manifest.rows.source_schema_validation_report`
when those containers supply replayable source reports. Contact-intent
review/import rows in the same mission-state containers are likewise preserved
as
`mission_state.source_operator_review_package.rows.source_contact_intent[0]`
and
`mission_state.source_cadence_import_manifest.rows.source_contact_intent[0]`,
including request-derived contact-intent source-report summaries, without
granting operator authority or approving imports.

Objective-style constraint, satisfaction, tradeoff, and score reports remain
candidate-source audit evidence but are not resubmitted as branch-generated
refresh report inputs, avoiding duplicate refresh pressure.

Source-report summaries include source-report paths grouped by family,
contract, and trust-boundary status plus request-derived candidate-source path
metadata without reintroducing objective and constraint reports as duplicate
raw refresh objectives.
Timeline activity-precondition source summaries derive status, blocked/review
counts, and blocked/review type maps from precondition rows when row evidence
is present, so stale top-level aggregate fields cannot suppress branch-local
CandidateRefresh replay pressure.
Timeline lifecycle-state source summaries similarly derive review,
duplicate-identity, invalid-input, action, transition-category, and routing
pressure from lifecycle rows when row evidence is present.

CandidateRefresh now also preserves operational-timeline
dependency/exclusivity integrity issue counts in source-report and
operational-feedback provenance, and emits a refresh warning when those source
rows require timeline-integrity review.

## Communications and ground-network mission-state replay

### Link-capacity reports

Mission-state link-capacity reports now replay selected or actual downlink
shortfall rows into branch-local downlink-completion pressure and risk
evidence, and derive station-throughput feedback from realized throughput rows,
preserving source windows, source activity IDs, trust boundaries,
candidate-source audit paths, and source-report provenance summaries while
candidate insertion remains dependent on matching refreshed or supplied
downlink candidates. Candidate-refresh also exposes the link-capacity slice as
a branch-local replay summary with adjusted-throughput totals/maps,
selected/actual contact routing maps, downlink-status maps, trust-boundary
evidence, and no-allocation/no-selection/no-import boundaries.
Branch-generated CandidateRefresh requests preserve direct mission-state and
result-artifact-wrapped raw `source_link_capacity_report` /
`link_capacity_report` inputs with wrapper-qualified request paths and indexed
embedded replay copies, keeping capacity-adjusted throughput totals/maps,
selected/actual shortfall evidence, contact/station/provider routing, and
inherited trust-boundary evidence visible at the branch provenance boundary.
Candidate-refresh operator-review packages also lift direct
`source_link_capacity_report` / `link_capacity_report` rows into
`link_capacity_review` rows, preserving source paths, station identity,
throughput/shortfall/contact routing, policy evidence, and source row payloads
without mutating contact allocation or selecting candidates. The same
operator-review handoff applies when link-capacity reports are preserved under
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
retaining wrapper-qualified source paths and indexed list positions.
Branch-generated candidate-refresh requests now also carry direct and wrapped
`source_link_capacity_summary` / `link_capacity_summary` inputs, preserving
capacity-adjusted throughput totals, selected/actual shortfall evidence,
selected/actual contact routing, trust-boundary evidence, and artifact-only
no-allocation/no-selection assumptions in generated candidate-source
provenance. Compact summaries with embedded rows derive those throughput,
contact, source-window, station-calendar, and direction-routing maps from rows
before stale top-level aggregates are replayed into branch-local provenance.
They also carry direct, accepted-state, mission-state, and wrapped
`source_relay_data_path_summary` / `relay_data_path_summary` inputs as
link-capacity-family provenance, preserving relay/direct route counts, route
IDs, source and relay spacecraft IDs, ground downlink contact IDs,
custody/latency/risk status maps, wrapper-qualified paths, trust boundaries,
and artifact-only no-scheduling/no-allocation assumptions without selecting
candidates or mutating schedules. Compact relay summaries with embedded rows
derive those route/status maps and route/contact IDs from rows before stale
top-level aggregates are replayed into branch-local provenance.

### Contact-filter reports

Mission-state contact-filter reports now replay suppressed downlink rows into
the same branch-local contact-filter pressure path as prior-plan reports,
preserving nested station IDs, source windows, demand lineage, trust
boundaries, and `mission_state.source_contact_filter_report` candidate-source
audit paths. Candidate-refresh also exposes the contact-filter slice as a
branch-local replay summary with suppressed/invalid counts,
suppression-reason maps, station-suppression station/availability/status maps,
trust-boundary evidence, and no-allocation/no-selection/no-import boundaries.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
mission-state contact-filter reports with wrapper-qualified request input paths
and indexed embedded replay copies.
Candidate-refresh operator-review packages also lift direct
`source_contact_filter_report` / `contact_filter_report` suppressed candidate
rows into `contact_suppression` rows, preserving source paths,
station/reservation context, policy evidence, duplicate or invalid-row context,
and source row payloads without mutating contact allocation or selecting
candidates.
They also lift those contact-filter rows when reports are preserved under
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
retaining wrapper-qualified source paths and indexed list positions.

### Contact-allocation reports

Mission-state contact-allocation reports now replay deferred, blocked, or
policy-blocked downlink rows into the same branch-local allocation pressure
path as prior-plan reports. Station-block allocation rows for unavailable,
reserved, or zero-capacity station time replay as branch-local ground-network
state before regenerated contacts are filtered, preserving:

- allocation status/reason
- source windows
- demand lineage
- source allocation evidence on resulting contact-filter and allocation rows
- reduced-capacity policy decisions
- trust boundaries
- `mission_state.source_contact_allocation_report` candidate-source audit paths
  plus source-report provenance summaries

Candidate-refresh exposes a compact contact-allocation replay summary over
preserved source-report provenance so branch-local consumers can route
blocked/deferred counts, allocation status/reason maps, station pressure, and
capacity-pack required/selected/deferred demand without mutating contact
allocation, selecting candidates, or approving imports. Capacity-pack status
and contact-status maps come from allocation rows when present, preventing stale
top-level capacity-pack routing maps from steering branch-local pressure.
Branch-generated CandidateRefresh requests preserve direct and
result-artifact-wrapped `source_contact_allocation_report` /
`contact_allocation_report` inputs with wrapper-qualified request paths and
indexed embedded replay copies, keeping raw allocation rows, capacity-pack
demand/routing, direction routing, station pressure, and trust-boundary evidence
visible to branch-local replay.
Preserved compact contact-allocation direction routes are rebuilt from their
direction, station-pressure, reservation-conflict, and provider-reservation
field maps at flattened-source and replay boundaries. Explicit compact count
maps retain occurrence counts while stable ID lists remain de-duplicated, stale
route-only entries cannot create pressure, and compact schema validation rejects
a supplied route that differs from the canonical rebuild.
Base allocation direction counts and contact-ID lists are canonicalized after
raw merges and at compact replay boundaries. Lists require positive local counts
and cannot exceed those occurrence counts; count-only directions remain scalar
pressure without emitting identity routes, and schema validation enforces the
same correlation.
Branch-generated CandidateRefresh requests also carry mission-state
`source_contact_allocation_summary` / `contact_allocation_summary`,
	`source_contact_allocation_station_pressure_summary` /
	`contact_allocation_station_pressure_summary` and
	`source_contact_allocation_reservation_conflict_summary` /
	`contact_allocation_reservation_conflict_summary` and
	`source_contact_allocation_capacity_pack_summary` /
	`contact_allocation_capacity_pack_summary` and
	`source_contact_allocation_provider_reservation_request_summary` /
	`contact_allocation_provider_reservation_request_summary` inputs, including
	copies extracted from mission-state `source_result_artifact` /
	`result_artifact` wrappers.
CampaignPlanner maps each summary contract to its owned base and derived row
collections before producing allocation pressure. Cross-family shadow rows and
unsupported contracts cannot authorize branches; aggregate station/capacity
routing maps remain context attached to accepted contact-scoped rows.
When canonical `rows` is present, it is authoritative over derived subsets;
provider-request subset rows must also occur in the canonical collection.
Subset-only pressure remains available for older partial handoffs that omit the
base field rather than declaring an empty or contradictory base collection.
Candidate-source audit paths and generated request input paths retain the
wrapper-qualified summary path while the replay summary preserves the validated
allocation, station-pressure,
reservation-conflict, capacity-pack, and provider-reservation request summary
contracts, allocation status and contact-ID maps, station-pressure
counts/contact-ID maps, reservation conflict/expiration evidence, demand totals,
reduced-capacity pack groups, and provider-reservation request routing maps
without allocating contacts or creating provider reservations.
Candidate-refresh operator-review packages also lift direct
`source_contact_allocation_report` / `contact_allocation_report` rows and
reduced-capacity pack groups into `contact_allocation_review` and
`contact_allocation_capacity_pack_review` rows, preserving source paths,
allocation status/reason, station/resource/capacity evidence, source row
payloads, and allocation summary counts without selecting contacts or mutating
allocations. The same operator-review handoff applies when contact-allocation
reports are preserved under candidate-refresh `source_result_artifact` /
`result_artifact` wrappers, retaining wrapper-qualified source paths and
stable review IDs.

### Contact-contention-resolution reports

Mission-state contact-contention-resolution reports now replay deferred
downlink recommendations into the same branch-local contention pressure path as
prior-plan reports, preserving selected/deferred contact identity,
source-window lineage, selection reason, priority source, review status, trust
boundaries, and `mission_state.source_contact_contention_resolution_report`
candidate-source audit paths.
CampaignPlanner derives recommendation pressure only from
`contact_contention_resolution_report.v1` and conflict pressure only from
`contact_contention_report.v1`; wrong-contract shadow collections remain
provenance-only instead of authorizing branches across direct, wrapped, or
prior-plan inputs.
Resolution recommendations create branch pressure only when the selected and
deferred contact IDs are unique and exactly match their source candidate IDs;
substituted, missing, or self-deferred identities remain review evidence.
Conflict groups apply the same exact multiset rule whenever source candidates
are present, including an explicitly empty collection. Partial handoffs that
omit source candidates retain contact-ID fallback pressure.
Compact resolution-summary selected, deferred, review, and ambiguous maps are
group-lineage filtered during source aggregation and replay, so phantom group
keys cannot surface as branch pressure even when standalone validation is
bypassed. Their values are also filtered per report against the corresponding
flattened selected, deferred, review, or ambiguous contact-ID list, preventing a
valid group key from carrying borrowed identity across reports.
Resource-scope, selection-reason, and review-action routing maps are likewise
restricted to positive keys in their corresponding count maps during executable
validation, per-report aggregation, and preserved replay. Aggregation and replay
also constrain their values to the same report's selected, deferred, or review
contact IDs. Flattened contact IDs and aggregate counts remain available as
conservative review evidence when a categorical entry is rejected.
Station-routing values are constrained per report and during replay to the
summary's selected/deferred contact identity. Direction contact routing adds the
same identity constraint plus positive direction-count key correlation, and its
compact route map is reconstructed from the correlated counts and contact IDs;
count-only direction evidence and flattened IDs remain reviewable.
Capacity-source contact routing is likewise limited to positive source-count
keys and the same report's selected/deferred contact IDs during executable
validation, aggregation, and replay. Raw source counts remain conservative
review evidence when an unvalidated route entry is removed.
Capacity status maps accept only selected/deferred keys, and capacity
station/status numeric maps survive aggregation and replay only when they match
their corresponding scalar totals. A rejected map does not erase scalar demand
pressure or invent station authority.
Branch-generated CandidateRefresh requests preserve direct mission-state and
result-artifact-wrapped raw `source_contact_contention_resolution_report` /
`contact_contention_resolution_report` inputs with wrapper-qualified request
paths and indexed embedded replay copies, keeping recommendation/deferred
contact routing, direction maps, capacity-pack demand evidence, required-action
counts, and inherited trust-boundary evidence visible at the branch provenance
boundary.

Candidate-refresh exposes a compact contact-contention-resolution replay
summary over preserved source-report provenance so branch-local consumers can
route recommendation/deferred-contact counts, resolution status, selection
reasons, and capacity-pack required/selected/deferred demand without mutating
contact allocation, selecting candidates, or approving imports.
Candidate-refresh operator-review packages also lift direct
`source_contact_contention_resolution_report` /
`contact_contention_resolution_report` recommendations into
`contact_contention_recommendation` rows with `candidate_refresh.*` source
paths, preserving recommendation review pressure without mutating allocation,
selecting candidates, resolving contention, approving imports, or writing to
Cadence.
They also lift recommendations when resolution reports are preserved under
candidate-refresh `source_result_artifact` / `result_artifact` wrappers,
retaining wrapper-qualified source paths and indexed list positions.

Candidate-refresh also exposes a compact contact-contention replay summary over
preserved `contact_contention_report.v1` source-report provenance, so
branch-local consumers can route conflict-group counts, invalid-contact-input
counts, resource scopes, station/contact maps, and required actions without
mutating contact allocation, selecting candidates, or approving imports.
Preserved contention direction contact maps are limited to positive direction
counts and positive contention contact-ID counts, and direction routing is
rebuilt from those correlated fields at flattened-source and replay boundaries.
Raw direction counts with positive integer evidence remain conservative review
pressure.
Preserved invalid-input IDs likewise require a matching positive invalid-input
count at source aggregation, flattened-source, and replay boundaries. Compact
CandidateRefresh schema validation rejects count/list mismatches, while runtime
replay retains a mismatched positive count as pressure without carrying its IDs.
Compact contention required-action maps are limited to canonical conflict and
invalid-input review actions whose positive counts do not exceed the matching
scalar evidence. Unknown or over-counted action keys are rejected by compact
schema validation and cannot create replay review-action pressure.
Compact contention resource scopes are limited to positive `ground_station`
and `spacecraft` counts whose combined total is bounded by the conflict-group
scalar. Unknown or over-counted scopes are rejected by compact schema
validation and do not create replay contention pressure.
Compact contention ground-station maps require positive stable-ID counts whose
combined total is bounded by correlated `ground_station` scope evidence.
Malformed or over-counted station maps are rejected by compact schema
validation and cannot create replay station-specific pressure.
Compact contention contact-ID counts and direction contact lists are mutually
correlated. Contact IDs must appear in positive direction evidence, contact
totals cannot exceed positive direction counts, and raw direction counts remain
pressure when uncorrelated contact identities are removed. Zero and negative
direction entries are discarded at raw aggregation and compact replay
boundaries, so map presence without positive direction evidence cannot create
branch pressure.
Direction count and contact-list keys are canonicalized through the shared
provider alias rules before correlation. Equivalent compact keys such as
`Down Link`, `down`, and `downlink` merge into `downlink`; compact schema
validation requires canonical stable direction keys while allowing canonical
custom direction tokens.
Each correlated direction list is locally bounded by that direction's positive
count. CandidateRefresh removes over-cardinality lists instead of choosing
arbitrary contact identities, retains scalar direction pressure, and rejects the
same mismatch in compact schema validation.
Direction routes include only directions with retained correlated contact IDs;
count-only directions remain scalar pressure without becoming identity routes.
Replay boundaries rebuild routes, and compact schema validation rejects a
preserved route map that differs from the canonical count/list correlation.
Branch-generated CandidateRefresh requests preserve direct mission-state and
result-artifact-wrapped raw `source_contact_contention_report` /
`contact_contention_report` inputs with wrapper-qualified request paths and
indexed embedded replay copies, keeping conflict groups, invalid input routing,
direction/resource-scope maps, required-action counts, and inherited
trust-boundary evidence visible at the branch provenance boundary.
Candidate-refresh operator-review packages also lift direct
`source_contact_contention_report` / `contact_contention_report` conflict groups
and invalid-contact inputs into `contact_contention_review` rows with
`candidate_refresh.*` source paths, preserving that review pressure without
mutating contact allocation, selecting candidates, resolving contention, or
writing to Cadence.
They also lift contact-contention reports preserved under candidate-refresh
`source_result_artifact` / `result_artifact` wrappers, including nested
`contact_allocation_report.contact_contention_report` payloads, while retaining
wrapper-qualified source paths.

### Contact-intent artifacts

Mission-state contact-intent artifacts now replay blocked, invalid, or
missing-import downlink intent gates through the same branch-local
contact-intent pressure path as prior-plan intent rows, preserving policy,
reservation, timing, station-calendar, trust-boundary, and
`mission_state.source_contact_intent` feedback-source evidence. Branch-generated
refresh requests now carry those rows as `mission_state.source_contact_intents`
source inputs so generated refresh metadata preserves the request path and
contact-intent source-report summary. Candidate-refresh provenance summarizes
replayed contact-intent source paths, station feedback/status counts, Cadence
import status counts, policy classifications, and trust-boundary status under
`provenance.source_reports.contact_intent`. Candidate-refresh also exposes the
contact-intent slice as a branch-local replay summary with
station-feedback status/import/policy maps, capacity-pack demand totals/maps,
required-capacity source/contact routing maps, trust-boundary evidence, and
no-contact-generation/no-selection/no-import boundaries.
Candidate-refresh operator-review packages also lift review-required
direct/list-valued `source_contact_intent`, `source_contact_intents`, and
singular `contact_intent` inputs into `contact_intent_review` rows with
`candidate_refresh.*` source paths, while top-level refresh `contact_intents`
retain their primary `candidate_refresh.contact_intents` handoff path.
Contact-intent review evidence embedded in `source_operator_review_package`,
`source_cadence_import_manifest`, and nested `source_result_artifact` /
`result_artifact` containers is unpacked into the same review-row family with
container-qualified source paths.

Mission-state `source_result_artifact` / `result_artifact` wrappers can carry
those same `source_contact_intent`, `contact_intent`, `source_contact_intents`,
and `contact_intents` rows through the live contact-intent pressure path while
nested rows inherit wrapper trust boundaries when they do not declare their own.
Branch-generated refresh requests preserve direct and wrapped raw
`source_contact_intent`, `contact_intent`, `source_contact_intents`, and
`contact_intents` inputs, retaining wrapper-qualified request paths,
station/direction capacity maps, direction routing, all-contact contact-ID maps,
and inherited trust-boundary evidence for CandidateRefresh replay.
Branch-generated refresh requests also carry direct and wrapped
`source_contact_intent_summary` / `contact_intent_summary` inputs, preserving
compact summary source paths, row counts, station/direction capacity maps,
direction routing, trust-boundary evidence, and artifact-only no-generation /
no-allocation assumptions for CandidateRefresh replay. Compact summaries that
carry embedded contact-intent rows derive those station/direction capacity maps,
direction routing, and contact-ID maps from the rows before stale aggregate
fields are replayed into branch-local provenance.

### Station-calendar reports

Mission-state station-calendar reports now replay affected contacts and
provider-calendar contention groups into the same branch-local station-calendar
pressure path as prior-plan reports, preserving reservation ownership/status,
provider entry IDs, trust boundaries, and
`mission_state.source_station_calendar_report` candidate-source audit paths
even when the feedback event comes from a report subpath. Candidate-refresh
also exposes the station-calendar slice as a branch-local replay summary with
affected-contact/provider-contention counts, provider/station/status/
availability maps, trust-boundary evidence, and no-schedule-mutation/
no-selection/no-import boundaries.
Candidate-refresh operator-review packages now also surface direct
`source_station_calendar_report` / `station_calendar_report` affected-contact
and provider-contention rows as `station_calendar_review` rows with
`candidate_refresh.*` source paths, keeping the replay handoff artifact-only and
non-mutating.
They also lift station-calendar reports preserved under candidate-refresh
`source_result_artifact` / `result_artifact` wrappers while retaining
wrapper-qualified source paths.
Branch-generated candidate-refresh requests now carry direct and
result-artifact-wrapped raw `source_station_calendar_report` /
`station_calendar_report` inputs, preserving affected-contact and
provider-contention counts, direction routing, trust-boundary evidence, and
artifact-only no-calendar-mutation assumptions in generated candidate-source
provenance.
Branch-generated candidate-refresh requests now carry direct and wrapped
`source_station_calendar_precedence_summary` /
`station_calendar_precedence_summary` inputs, preserving applied/overlap
availability counts, reserved-under-higher-precedence contact routing,
trust-boundary evidence, and artifact-only no-calendar-mutation assumptions in
generated candidate-source provenance.

### Timeline-transition application reports

Mission-state timeline-transition application reports now feed the same
timeline-diff branch-local refresh path as prior-plan transition application
reports, preserving `application_status`, selected-activity context,
trust-boundary evidence, and
`mission_state.source_timeline_transition_application_report` candidate-source
audit paths from the `.applications` report subpath.

Candidate-refresh exposes a compact timeline-transition-application replay
summary over preserved source-report provenance so branch-local consumers can
route application, selected, review, preserved/replacement, withheld,
duplicate-identity, status/decision/action, trust-boundary, and operator-review
pressure without applying timeline transitions, mutating timelines, selecting
candidates, approving imports, writing to Cadence, or regenerating refresh
candidates. Application-row evidence takes precedence over stale top-level
transition aggregate maps, duplicate identity counts, and
selected/review/preservation scalar counts.
Candidate-refresh operator-review packages also lift direct
`source_timeline_transition_application_report` /
`timeline_transition_application_report` applications into `timeline_diff_review`
rows with `candidate_refresh.*` source paths, preserving the same no-transition-
application and no-timeline-mutation boundary.
Branch-generated candidate-refresh requests also preserve direct and
`source_result_artifact` / `result_artifact` wrapped
`source_timeline_transition_application_report` /
`timeline_transition_application_report` inputs, retaining wrapper-qualified
request paths, selected/review/duplicate row evidence, status/decision/action
maps, and inherited trust-boundary evidence through branch-local replay.

## Live operator-review and Cadence-import inputs

Live mission-state `source_operator_review_package` / `operator_review_package`
and `source_cadence_import_manifest` / `cadence_import_manifest` inputs now
preserve review/import rows through V3 request normalization, replaying the same
branch-local pressure and operational-feedback handoff paths as prior-plan
review artifacts, including timeline-diff handoff rows that derive downlink
recovery pressure, while retaining mission-state source paths and
package/manifest trust-boundary evidence.

Supplied `candidate_refresh.v1.operational_feedback` maps are also normalized
into the same strategy input, preserving the refresh artifact's feedback
provenance as the source evidence while leaving explicit request feedback as
the final override.

## Command-success and maneuver-success feedback derivation

### Command-window normalization

Prior `source_command_window_report` / `command_window_report` rows,
`command_window_report.v1` rows embedded in prior `source_result_artifact` /
`result_artifact` wrappers, and preserved command-window review/import rows from
prior `operator_review_package.v1` or `cadence_import_manifest.v1` handoffs with
command-success factors or provider command-result evidence are likewise
normalized into `operational_feedback.command_success_rate`, so low-confidence
command windows can derive command-success review branches, with weighted row
counts, feedback-weight source labels, and report or wrapper trust-boundary
evidence exposed in source provenance.
Candidate-refresh operator-review packages also lift direct
`source_command_window_report` / `command_window_report` rows and
command-window reports preserved in `source_result_artifact` /
`result_artifact` wrappers into `command_window_review` rows with
`candidate_refresh.*` source paths, preserving the same no-command-execution
and no-Cadence-write boundary.
Branch-generated candidate-refresh requests now carry direct and
result-artifact-wrapped raw `source_command_window_report` /
`command_window_report` inputs, preserving command-feedback counts, direction
routing, required-action maps, trust-boundary evidence, and artifact-only
no-command-execution assumptions in generated candidate-source provenance.

### Maneuver-review normalization

Prior `source_maneuver_review_report` / `maneuver_review_report` rows with
maneuver-success factors or provider maneuver-result evidence are normalized
into `operational_feedback.maneuver_success_rate`, so low-confidence maneuver
recommendations can derive maneuver-success review branches with the same
weighted source-provenance context.
Candidate-refresh operator-review packages also lift direct
`source_maneuver_review_report` / `maneuver_review_report` rows and
maneuver-review reports preserved in `source_result_artifact` /
`result_artifact` wrappers into `maneuver_review` rows with
`candidate_refresh.*` source paths, preserving the same no-maneuver-execution
and no-Cadence-write boundary.
Branch-generated candidate-refresh requests now carry direct and
result-artifact-wrapped raw `source_maneuver_review_report` /
`maneuver_review_report` inputs, preserving maneuver-success feedback,
execution-uncertainty counts, maneuver-ID maps, required-action maps,
trust-boundary evidence, and artifact-only no-maneuver-execution assumptions in
generated candidate-source provenance.

V3 also unwraps `source_result_artifact` / `result_artifact` maneuver review
reports and de-duplicates embedded `maneuver_recommendations` that are already
represented by authoritative review rows, so result-set artifacts can drive the
same branch-local maneuver feedback without double-counting samples.

### Maneuver execution uncertainty

- Those same maneuver-review report rows now replay declared/missing
  execution-uncertainty evidence into
  `operational_feedback.maneuver_execution_uncertainty` with declared/missing
  source counts.
- Timeline-feedback `operational_feedback.maneuver_execution_uncertainty`
  entries with missing or over-threshold timing / delta-v 3-sigma values derive
  branch-local `maneuver_execution_uncertainty_feedback` review branches.

### Preserved package/manifest review rows

Prior `operator_review_package.v1` command-window or maneuver-review rows, plus
`cadence_import_manifest.v1` review rows, including packages and manifests
embedded in prior `source_result_artifact` / `result_artifact` wrappers, that
preserve those source rows feed the same command/maneuver feedback and
branch-local review-pressure paths without requiring the original source
reports to be resubmitted.

## V2 repair artifacts as V3 prior plans

V2 repair artifacts used as V3 prior plans can also recover
`source_candidate_activities` / `candidate_activities` carried inside prior
`source_result_artifact` / `result_artifact` wrappers, preserving wrapper
trust-boundary evidence on replayed source candidates so branch repair does not
require callers to duplicate candidate arrays at the top level. Those replayed
candidates seed V3 planning context for station IDs, target IDs, target
priorities, realized-feedback matching, and prior-plan candidate source counts,
including the prior-candidate inputs used by branch-generated candidate-refresh
diff and freshness evidence.

- **Prior planned `activities`** — carried in those result-artifact wrappers
  likewise replay into V3 branch-event realized-state synthesis,
  command/maneuver feedback derivation, downlink/objective context, and
  realized-feedback matching.
- **Prior `proposed_contacts`** — in the same wrappers seed station-scoped
  feedback and realized-feedback matching without requiring duplicate top-level
  proposed-contact arrays.
- **Wrapper-carried `operational_feedback` maps** — also replay through the
  prior-plan feedback merge slot with source-path and trust-boundary
  provenance.

## Operational-timeline and realized-feedback uncertainty handoff

Operational timeline review and realized-feedback wrappers now carry maneuver
execution-uncertainty fields through the same handoff, and row-specific
operational-timeline branches preserve concrete uncertainty feedback events for
adapter review, including top-level `cadence_import_manifest.v1`
`review_operational_timeline` rows.
Candidate-refresh operator-review packages now also lift direct
`source_operational_timeline_report` / `operational_timeline_report` rows and
operational-timeline reports preserved in `source_result_artifact` /
`result_artifact` wrappers into `operational_timeline_review` rows, preserving
candidate-refresh source paths and source row payloads without applying
operational feedback or mutating timelines.
They also lift direct candidate-refresh `source_contact_allocation_report` /
`contact_allocation_report` rows and reduced-capacity pack groups into
`contact_allocation_review` and `contact_allocation_capacity_pack_review` rows,
preserving source paths and allocation summary evidence without selecting
contacts or mutating allocations.
Direct candidate-refresh `source_link_capacity_report` / `link_capacity_report`
rows are lifted into `link_capacity_review` rows, preserving source paths,
station identity, throughput/shortfall/contact routing, policy evidence, and
source row payloads without mutating contact allocation or selecting
candidates.
They also lift direct candidate-refresh `source_quality_gate_report` /
`quality_gate_report` rows into `quality_gate_review` rows, preserving source
paths, source row/report payloads, and resource reason context without
certifying gates or approving imports. Quality-gate reports wrapped in
`source_result_artifact` / `result_artifact` containers are lifted into the
same review-row family with wrapper-qualified `candidate_refresh.*` source
paths.
Direct candidate-refresh `source_schema_validation_report` /
`schema_validation_report` rows are lifted into `schema_validation_review` rows
with source paths, validation issue/remediation context, and source report
payloads preserved without approving imports or writing to Cadence. Preserved
schema-validation rows from `source_operator_review_package`,
`source_cadence_import_manifest`, and nested `source_result_artifact` /
`result_artifact` containers are unpacked into the same review-row family with
container-qualified `candidate_refresh.*.rows.source_schema_validation_report`
paths.
Branch-generated refresh requests preserve direct and result-artifact-wrapped
mission-state schema-validation reports with wrapper-qualified request input
paths and indexed embedded replay copies, so validation status, issue counts,
and remediation routing remain visible in CandidateRefresh replay metadata.

Realized-feedback maneuver rows also preserve row-specific uncertainty events
alongside maneuver-success feedback, including flattened top-level
Cadence-import realized-feedback rows. Direct maneuver-review source rows now
preserve row-specific uncertainty events, including uncertainty-only review
rows, while also deriving source-specific branch-local
`command_success_feedback` and `maneuver_success_feedback` branches from
preserved `source_command_window` and `source_maneuver_review` rows.

Command-window feedback branches preserve station-calendar provider IDs,
reservation IDs/statuses, direction, and reservation-match evidence, so branch
comparison can explain low-confidence command windows by the ground-network
constraint that produced the review.

Direct prior-plan or mission-state and result-artifact-embedded list-valued
operator-review packages and Cadence-import manifests replay through the same
command-window handoff with indexed source paths and direct or inherited
wrapper trust boundaries, with strategy-level operational-feedback provenance
retaining the aggregate merge source label while exposing indexed
`source_report_paths`.

Cadence import rows replay the same nested or top-level source-row handoff with
import-queue trust boundaries.

## Operational-timeline review rows into operational feedback

Prior `operator_review_package.v1` operational-timeline review rows that
preserve source timeline rows feed contact success, station throughput,
observation success, command success, and maneuver success into the same
`operational_feedback` handoff while preserving observation-quality
score/status/source, cloud-cover, and blur maps and honoring
feedback/confidence weight aliases from the preserved source timeline rows.

Matched, non-invalid `operator_review_package.v1` realized-feedback rows
likewise feed contact, station-throughput, downlink-demand shortfall,
observation, command, and maneuver confidence plus target-keyed
observation-quality maps into `operational_feedback`. Prior
`cadence_import_manifest.v1` rows that preserve those same realized-feedback
source review rows, or carry the realized-feedback review fields at the
import-row top level, now feed the same operational-feedback merge and
branch-local refresh derivation without requiring the original review package to
be resubmitted, including source-specific branch events that retain the
review/import source path and trust boundary.

Prior Cadence import rows that preserve `source_operational_feedback` from
strategy recommendation imports likewise seed later V3 operational-feedback
merges and branch-local feedback branches without reopening the original
strategy artifact. Nested `source_review_row` wrappers that preserve
`source_operational_feedback` replay through the same source path when the
top-level import row does not already carry it, inheriting manifest-level trust
boundaries when row-level trust is absent.

Direct or list-valued review/import handoffs keep the stable replay source label
and add indexed `source_report_paths` for the package row or nested Cadence
import source-review row that contributed the replayed feedback.

## Top-level Cadence import replay fields

Top-level Cadence import rows that preserve `source_objective_satisfaction`,
`source_objective_tradeoff`, `source_score_term`, or `source_constraint_row`,
plus:

- resource-projection including flattened resource-projection rows
- link-capacity including flattened link-capacity rows
- contact-allocation including flattened contact-allocation rows
- contact/resource suppression including flattened suppression rows

feed the same branch-local objective, tradeoff, score-term, constraint,
communications, and resource refresh derivation without a nested review row, and
inert nested `source_review_row` wrappers do not hide those top-level replay
fields.

Prior operator-review rows that preserve `source_operational_feedback` from
strategy recommendation review rows feed the same replay path, inheriting
package-level trust boundaries when row-level trust is absent, with direct
report-level or nested `source_operational_feedback_provenance` trust boundaries
and field-specific `feedback_trust_boundaries` contributing to provenance
classification and derived branch-event trust routing.

## Invalid and ambiguous feedback handling

Malformed replayed `source_operational_feedback` rows, including invalid
candidate-refresh warning handoffs from operator-review and Cadence import
artifacts, are preserved as invalid operational-feedback provenance evidence
without affecting branch scoring, while ambiguous or invalid feedback rows
remain review-only.

For provider-shaped review rows, `realized_status` is treated as the execution
status when the row's review `status` only says `matched`, so failed reviewed
downlinks still generate branch-local downlink demand and reviewed
observation/command/maneuver rows still produce confidence feedback even without
explicit success factors.

Top-level review-row feedback/confidence weight aliases are preserved before the
reviewed rows are folded into deterministic feedback averages, while
out-of-range or malformed unit-interval feedback factors on operator-review and
Cadence-import replay rows are preserved as invalid operational-feedback
provenance instead of being clamped into derived branches. Operator-review
source provenance exposes weighted row counts plus declared feedback-weight
source labels plus review-queue key counts, with executable validation
preventing weighted row counts from exceeding declared source row counts.

## Mission-state realized-activity and realized-state inputs

Mission-state standalone `source_realized_activity`, `realized_activity`,
`source_realized_activities`, `source_realized_state_snapshot`,
`realized_state_snapshot`, and `source_realized_state` inputs now replay
source-specific branch-local realized-feedback events with mission-state
provenance and inherited snapshot trust boundaries, without requiring callers to
flatten live realized artifacts into prior-plan reports. They now merge into
strategy-level `operational_feedback` with a `mission_state.realized_activity`
provenance source that summarizes source paths, activity-type, direction,
Cadence-import status, realized-status, feedback-weight, and trust-boundary
evidence.

Those realized rows can also arrive in mission-state `source_result_artifact` /
`result_artifact` wrappers, preserving wrapper source paths and inherited
trust-boundary evidence through the same branch-local realized-feedback replay.

### Weight aliases and telemetry normalization

Source-derived direct mission-state realized feedback also honors provider
nonnegative `feedback_weight`, `feedback_sample_weight`, `sample_weight`, and
`confidence_weight` aliases, including clean numeric strings, preserves invalid
realized feedback-weight aliases as invalid provenance instead of falling back
to default weighting, and normalizes clean numeric-string throughput,
downlink/data-volume, and clean unit-interval `completed_fraction` plus
observation-quality telemetry before producing branch-local success, throughput,
demand, maneuver, command, and target-priority factors.

Its V3 source provenance records weighted row count plus declared
feedback-weight source labels plus per-field/key `feedback_trust_boundaries`
derived from the realized rows that produced contact, throughput, demand,
command, maneuver, observation, and resource feedback. Malformed direct
realized-activity identity fields are excluded from derived scoring, and
out-of-range or malformed realized-row unit-interval telemetry plus negative or
malformed realized feedback weights are preserved as invalid
`mission_state.realized_activities` operational-feedback provenance instead of
leaking through default downlink/resource feedback keys.

### Standalone candidate-refresh realized-activity guards

Standalone candidate-refresh `operational_feedback.realized_activities` now
applies the same unit-interval and nonnegative feedback-weight guards before its
timeline-feedback handoff and carries the handoff's:

- contract/row-count identity
- trust-boundary summary
- positive weighted-row count
- feedback-weight source labels
- per-field/key feedback trust-boundary maps
- realized source-quality counts
- source row status/kind/match/import/protection counts
- execution-uncertainty declared/missing counts
- operational-feedback exclusion counts

Candidate-refresh requests can also consume standalone
`source_realized_activity`, `realized_activity`, `source_realized_activities`,
`realized_activities`, `source_realized_state_snapshot`,
`realized_state_snapshot`, `source_realized_state`, and `realized_state` rows
from the root request, accepted planning state, mission state, or
result-artifact wrappers, preserving source paths plus inherited snapshot or
wrapper trust boundaries while deriving the same contact, throughput,
observation-quality, command, and maneuver feedback maps through the
timeline-feedback handoff.

Operator-review-package `realized_feedback` rows and Cadence-import
`review_realized_feedback` / `record_realized_feedback` rows now feed that same
CandidateRefresh path directly, including nested
`source_review_row.source_feedback` handoffs, so reviewed execution evidence can
influence refresh scoring without first being flattened into
`operational_feedback.realized_activities`.

Counts in refresh provenance ensure that invalid completed-fraction,
image-quality, cloud-cover, blur, or weighting telemetry remains reviewable
without being clamped into effective refresh feedback.

## Source-derived downlink demand and request-feedback validation

Source-derived downlink demand can create a branch-local generated refresh with
required downlink evidence before candidate-budget selection.

Malformed non-object explicit request feedback, malformed nested feedback
sections, out-of-range unit-interval success, quality, and throughput feedback
factors, and negative or malformed downlink-demand or target-priority feedback
maps are ignored for branch scoring while remaining preserved as invalid
`request.operational_feedback` provenance evidence. Invalid operational-feedback
map keys are likewise dropped from effective branch behavior while remaining
reviewable in the same provenance.

## Operational-feedback provenance

Strategy artifacts also emit `operational_feedback_provenance` with:

- merge order
- input keys
- source count
- per-source trust-boundary status
- source-report counts and row counts
- timeline-feedback plus direct or result-artifact-embedded operator-review and
  Cadence-import source count maps, including review-type, review-queue, and
  review-action counts that fall back from `action` to
  `required_operator_action`

Explicit or mission-state operational-feedback maps can declare multiple
`trust_boundaries` plus per-field `feedback_trust_boundaries` for derived
branch-event trust routing. Prior direct or result-artifact-embedded
timeline-feedback reports now retain field/key trust routing for their own
derived `downlink_demand_mb`, `downlink_demand_sources`,
`resource_margin_overrides`, and `resource_availability_overrides` maps,
allowing V3 replay to route downlink-demand and resource-pressure branch events
back to the specific operational archive that produced those rows, with
validation rejecting contradictory zero-report/nonzero-row provenance.

This lets downstream review tools see whether feedback came from prior repair
reports, mission-state telemetry, mission-state embedded feedback, or request
overrides.

## Strategy recommendation feedback routing

Strategy recommendation operator-review rows and the selected
`import_strategy_recommendation` Cadence import row now carry that same feedback
provenance context as row-level `operational_feedback_*` fields and schema-typed
`source_operational_feedback_provenance`, including typed
`source_operational_feedback` maps, availability-override aliases, flattened
multi-source `operational_feedback_trust_boundaries`, and
`operational_feedback_field_trust_boundaries`, so adapter queues do not need to
reopen the full strategy artifact to route feedback-derived recommendations.

Selected recommendations also include:

- **`operational_feedback_driver` explanation rows** — when the recommended
  branch's score includes success-rate or station-throughput feedback
  adjustments, with observation-quality score/status/source, cloud-cover, and
  blur fields exposed when those quality maps drove the observation-success
  factor.
- **Risk-driver explanation rows** — preserve selected branch
  activity/scenario IDs, station/spacecraft/target IDs, and numeric-or-boolean
  values so command feedback risks remain routable without reopening branch
  internals.
- **`resource_pressure` explanation rows** — now also preserve first-pressure
  activity, direction, ground-station, station-calendar entry, provider,
  provider-entry, and availability-pressure status/type evidence so
  resource-pressure recommendations can be routed without reopening nested
  projection flow rows.
- **Contact-allocation pressure score terms** — split contact-allocation
  pressure risks into `contact_allocation_pressure_penalty`, leaving
  `risk_penalty` for non-contact-allocation risks so total branch score remains
  compatible while score-term reports expose contact pressure directly. Focused
  contact-allocation pressure fixtures now assert split branch math and
  score-term report rows through a shared helper.
- **Station-reservation conflict pressure score terms** — split
  contact-allocation reservation-conflict risks into
  `station_reservation_conflict_pressure_penalty`, leaving non-conflict
  allocation pressure on `contact_allocation_pressure_penalty`.
- **Provider-reservation request pressure score terms** — split
  provider-reservation request review risks into
  `provider_reservation_request_pressure_penalty`, leaving generic
  contact-allocation pressure and station-reservation conflicts on their own
  score terms.
- **Link-capacity pressure score terms** — split link-capacity shortfall risks
  into `link_capacity_pressure_penalty`, leaving `risk_penalty` for unrelated
  risks while preserving total branch score compatibility. Focused
  link-capacity pressure fixtures now assert split branch math and score-term
  report rows.
- **Contact-intent pressure score terms** — split contact-intent review/import
  risks into `contact_intent_pressure_penalty`, leaving `risk_penalty` for
  unrelated risks while preserving total branch score compatibility. Focused
  contact-intent pressure fixtures now assert split branch math and score-term
  report rows.
- **Contact-contention pressure score terms** — split contact-contention and
  contention-resolution risks into `contact_contention_pressure_penalty`,
  leaving `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused contention pressure fixtures now assert split branch
  math and score-term report rows.
- **Contact-filter pressure score terms** — split contact-filter downlink
  suppression risks into `contact_filter_pressure_penalty`, leaving
  `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused contact-filter pressure fixtures now assert split
  branch math and score-term report rows.
- **Resource-filter pressure score terms** — split resource-filter availability
  and margin suppression risks into `resource_filter_pressure_penalty`, leaving
  broader resource-availability and resource-margin pressure terms for
  non-filtered resource evidence while preserving total branch score
  compatibility. Focused resource-filter pressure fixtures now assert split
  branch math and score-term report rows.
- **Resource-availability pressure score terms** — split payload, antenna,
  spacecraft, degraded-payload, activity-type suppression/incompatibility, and
  generic resource unavailability risks into
  `resource_availability_pressure_penalty`, leaving `risk_penalty` for
  unrelated risks while preserving total branch score compatibility. Focused
  operational-feedback and resource-projection fixtures now assert split branch
  math and score-term report rows.
- **Resource-margin pressure score terms** — split fuel, power, and thermal
  margin risks into `resource_margin_pressure_penalty`, leaving `risk_penalty`
  for unrelated risks while preserving total branch score compatibility. Focused
  fuel-preservation and thermal resource-filter fixtures now assert split
  branch math and score-term report rows.
- **Battery-depletion pressure score terms** — split resource-projection
  battery-depletion risks into `battery_depletion_pressure_penalty`, leaving
  `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused projection-pressure fixtures now assert split branch
  math and score-term report rows.
- **Storage/downlink pressure score terms** — split storage/downlink
  resource-margin and projection risks into `storage_downlink_pressure_penalty`,
  leaving `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused storage/downlink pressure fixtures now assert split
  branch math and score-term report rows through a shared helper.
- **Station-calendar pressure score terms** — split station-calendar reserved,
  unavailable, reduced-capacity, and provider-contention risks into
  `station_calendar_pressure_penalty`, leaving `risk_penalty` for unrelated
  risks while preserving total branch score compatibility. Focused
  station-calendar pressure fixtures now assert split branch math and
  score-term report rows through a shared helper.
- **Station-reservation expiration pressure score terms** — split expired or
  missing station-reservation deadline risks into
  `station_reservation_expiration_pressure_penalty`, leaving ordinary
  station-calendar pressure on `station_calendar_pressure_penalty` and
  preserving one risk-weight penalty per risk indicator. Recommendation
  tradeoffs now expose the same `station_reservation_expiration_pressure`
  dimension as branch score reports.
- **Candidate-rejection pressure score terms** — split review-required
  candidate-rejection risks into `candidate_rejection_pressure_penalty`, leaving
  `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused candidate-rejection pressure fixtures now assert split
  branch math and score-term report rows through a shared helper.
- **Provider-counteroffer pressure score terms** — split review-required
  provider-counteroffer risks into `provider_counteroffer_pressure_penalty`,
  leaving `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused provider-counteroffer pressure fixtures now assert
  split branch math and score-term report rows through a shared helper.
- **Validation/refresh governance pressure score terms** — split
  schema-validation, model-acceptance, validation-safety-case, freshness, and
  refresh-budget risks into `validation_refresh_pressure_penalty`, leaving
  `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused validation/refresh governance pressure fixtures now
  assert split branch math and score-term report rows through a shared helper.
- **Relay data-path pressure score terms** — split relay data-path custody,
  latency, and route-risk indicators into `relay_data_path_pressure_penalty`,
  leaving `risk_penalty` for unrelated risks while preserving total branch score
  compatibility. Focused relay data-path pressure fixtures now assert split
  branch math and score-term report rows through a shared helper.
- **Execution-feedback pressure score terms** — split contact-success,
  observation-success, station-throughput, command-success, maneuver-success,
  and maneuver execution-uncertainty risks into
  `execution_feedback_pressure_penalty`, leaving `risk_penalty` for unrelated
  risks while preserving total branch score compatibility. Focused
  execution-feedback and operational-feedback fixtures now assert split branch
  math and score-term report rows through a shared helper.
- **Timeline-integrity pressure score terms** — split dependency/exclusivity
  integrity risks into `timeline_integrity_pressure_penalty`, leaving
  publication, lifecycle, precondition, and preservation pressure for their
  dedicated or broader timeline terms while preserving total branch score
  compatibility.
- **Timeline dependency-impact pressure score terms** — split changed-source
  dependency/exclusivity impact risks into
  `timeline_dependency_impact_pressure_penalty`, leaving publication,
  lifecycle, precondition, and preservation pressure for their dedicated or
  broader timeline terms while preserving total branch score compatibility.
  Focused dependency-impact pressure fixtures now assert split branch math,
  legacy compatibility term behavior, and score-term report rows through a
  shared helper.
- **Timeline-publication pressure score terms** — split publication and
  downstream-invalidation risks into `timeline_publication_pressure_penalty`,
  leaving lifecycle, precondition, and preservation pressure for their dedicated
  or broader timeline terms while preserving total branch score
  compatibility. Focused publication pressure fixtures now assert split branch
  math, legacy compatibility term behavior, and score-term report rows through a
  shared helper.
- **Timeline lifecycle-state pressure score terms** — split timeline and
  activity lifecycle-state review risks into
  `timeline_lifecycle_pressure_penalty`, leaving precondition and preservation
  pressure for their dedicated or broader timeline terms while preserving total
  branch score compatibility. Focused lifecycle-state pressure fixtures now
  assert split branch math, legacy compatibility term behavior, and score-term
  report rows through a shared helper.
- **Timeline-precondition pressure score terms** — split activity-precondition
  review risks into `timeline_precondition_pressure_penalty`, leaving
  preservation pressure for its dedicated timeline term while preserving total
  branch score compatibility. Focused activity-precondition pressure fixtures
  now assert split branch math, legacy compatibility term behavior, and
  score-term report rows through a shared helper. Stale aggregate challenge
  coverage also verifies row-local precondition evidence drives branch pressure
  status, counts, and type lists.
- **Timeline-preservation pressure score terms** — split lock/approval/executed
  preservation review risks into `timeline_preservation_pressure_penalty`,
  leaving the legacy `timeline_pressure_penalty` present as an empty
  compatibility term while preserving total branch score compatibility. Focused
  preservation pressure fixtures now assert split branch math, legacy
  compatibility term behavior, and score-term report rows through a shared
  helper.
- **Operational-readiness pressure score terms** — split readiness review,
  blocked, and analysis-only risks into
  `operational_readiness_pressure_penalty`, leaving broader approval-boundary
  and generic risk terms for unrelated risks while preserving total branch score
  compatibility. Focused operational-readiness pressure fixtures now assert the
  split branch math and score-term report rows through a shared helper.
- **Quality-gate pressure score terms** — split quality-gate review, blocked,
  analysis-only, unavailable-resource, schema-validation, and import-readiness
  risks into `quality_gate_pressure_penalty`, leaving broader
  approval-boundary and generic risk terms for unrelated risks while preserving
  total branch score compatibility. Focused quality-gate pressure fixtures now
  assert the split branch math and score-term report rows through a shared
  helper.
- **`operational_readiness_pressure` explanation rows** — preserve the selected
  branch's readiness report, source artifact, readiness/import/status counts,
  gate ID/status/classification/reason, required operator action, feedback
  source/scope/key, trust boundary, and operator-training context when a
  readiness-pressure branch is recommended.
- **`quality_gate_pressure` explanation rows** — preserve the selected branch's
  quality-gate report/readiness linkage, gate status/classification/reason,
  required operator action, feedback source/scope/key, trust boundary,
  operator-training context, and resource-availability pressure IDs/counts when
  a quality-gate pressure event drives the recommended branch.

Operational-readiness and quality-gate pressure events also emit branch risk
indicators with the same report, source-artifact, gate, required-action,
feedback, trust-boundary, operator-training, and resource-availability routing
context. Operational-readiness rows contribute to
`operational_readiness_pressure_penalty`, and quality-gate rows contribute to
`quality_gate_pressure_penalty`. Explicit approval-boundary pressure events
contribute to `approval_boundary_pressure_penalty`, leaving standard strategy
`risk_penalty` for unrelated risks. Otherwise equal branches with readiness,
quality-gate, or approval-boundary review pressure rank below pressure-free
alternatives when `risk_weight` applies while score-term reports isolate
readiness, quality-gate, and approval-boundary pressure. Branch comparison rows
expose the corresponding risk types.
Challenge coverage also verifies blocked or analysis-only readiness row statuses
remain score-visible through `operational_readiness_pressure_penalty` when
source classifications are missing or stale.

The corresponding strategy-recommendation operator-review row and Cadence import
gate flatten those same risk type and stable-ID arrays, plus resource-pressure
status/type lists and first-pressure kinds, for adapter routing. Selected
strategy recommendation review/import handoff rows also flatten
operational-readiness and quality-gate pressure report IDs, source artifact IDs,
readiness/import/status values, gate IDs/status/classifications, required
actions, feedback source/scope/key lists, trust boundaries, and
quality-gate resource-availability reason IDs so adapter queues can route
readiness pressure without reopening `source_recommendation.explanation`.

## Executable validation

The exported `campaign_strategy.v3` surface now declares every top-level field
emitted by the public V3 producer. Optional `source_repair_id`,
`score_term_report`, `objective_tradeoff_report`, `pareto_frontier_report`,
`operational_feedback_provenance`, and `cadence_import_manifest` fields preserve
older-strategy compatibility, while the four report fields embed their direct
V1 contracts instead of opaque object types. Runtime validation applies those
standalone report contracts at their strategy paths, validates optional repair
identity, and reconciles feedback-provenance source counts, source references,
and input keys with the effective operational-feedback map. The checked V3
artifact has no produced top-level keys outside the generated property surface.

Executable validation now enforces those operational-feedback number maps,
resource-margin overrides, and resource-availability override aliases across
top-level feedback and nested provenance source feedback instead of treating the
maps as opaque objects, and it validates malformed-feedback section rows,
source-report status counts, and declared source-count consistency inside
operational-feedback provenance.

## Status

- **partial** — branch derivation is deterministic but thin; combined futures
  are represented only as one opt-in aggregate branch, while robust strategy
  selection, resource dynamics, operational feedback learning, and persistent
  digital-twin state are not implemented.
- **near-term** — broaden branch-specific refresh derivation and add
  recommendation tests tied to operational product examples.
- **later** — persistent digital twin integration, robust planning across
  multiple simultaneous futures, fleet-level allocation, learned or calibrated
  operating models, and branch-tree simulation.
- **out of scope** — autonomous command execution and Cadence database/API
  implementation.
