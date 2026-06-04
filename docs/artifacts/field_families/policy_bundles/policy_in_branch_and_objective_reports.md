# Policy in Branch and Objective Reports

## Branch Comparison Report

`branch_comparison_report.v1` exports a nested row schema for branch IDs,
ranking, scores, raw/probability/expected score fields, approval status, risk
and approval counts, score terms, flattened priority-commitment,
downlink-completion, coverage, revisit, and collection-latency objective
satisfaction fields, including priority-commitment required/planned/missing
observation counts and ratio, optional resource projection summary fields, V2
repair score-term summaries, flattened resource margin and availability fields
including antenna availability, branch-event station/calendar/provider and
reservation summary arrays, branch-event status-transition type/category/reason
summaries with operator-review requirement counts, and repaired
downlink-capacity summaries including required downlink volume, selected
shortfall, and requirement status.
Resource projection summaries include unavailable-spacecraft, payload-unavailable,
degraded-payload, and antenna-unavailable counts and stable ID arrays plus
first-pressure direction, ground-station, station-calendar entry, and
station-calendar directions so branch-review queues can identify
spacecraft-health, payload, antenna, or station-calendar pressure without
opening nested projection rows.
Strategy recommendation risk-driver explanations preserve the same stable
station, spacecraft, and target IDs plus numeric-or-boolean risk values as the
underlying branch risks, so review adapters do not have to reopen branch risk
arrays to route scoped availability or station evidence. Selected strategy
recommendation review and Cadence import rows also aggregate risk-driver
direction, station-calendar entry IDs, and station-calendar directions from
remaining risks for adapter queue routing.
Downlink-completion objective-satisfaction rows and flattened branch-comparison
fields use the same objective data-identity selectors as branch candidate
matching, so unrelated collection/product/payload/instrument contacts do not
inflate scoped completion evidence. When a strategy request carries multiple
downlink-completion objectives, the flattened completion ratio is the aggregate
of objective-level ratios rather than the status of only the first objective.
`strategy_branch.v1` executable validation checks branch risk indicators against
the same typed risk-row contract used by strategy recommendation risks, including
boolean risk values for availability evidence that operator-review and import
rows preserve without coercing to numeric placeholders. Its branch-event schema
and executable validation expose `objective_id`, collection/product, payload,
instrument, source activity, source window, station, target, and combined-branch
lineage identifiers as stable fields for scoped downlink-completion and
collection-latency branch events, while score-term maps remain numeric and
success/throughput factors stay unit-interval bounded. Planner matching
respects explicitly declared downlink data identity when evaluating
objective-derived downlink gaps and latency windows.
Standalone branch-comparison reports can be normalized into
`operator_review_package.v1` strategy-tradeoff rows for artifact-only review
workflows, and those rows plus Cadence import strategy-tradeoff gates preserve
top-level `risk_count`, `risk_types`, and `high_risk_types` alongside the
resource-pressure status/type, first-pressure activity, station, calendar, and
direction context plus repaired link-capacity requirement evidence for adapter
review.
Executable validation treats branch-comparison branch totals, row ranks, row
count summaries, and contact-count summaries as integers while branch
probability, scores, margins, ratios, throughput, volume, and shortfall fields
remain numeric. It also cross-checks `branch_count` against emitted rows and
requires `recommended_branch_id` to exist as exactly the selected branch row, so
strategy review/import adapters can trust selected-branch routing metadata.
Executable validation also checks report-level `model_limits` against
`CampaignPlanner.branch_comparison_model_limits/0`.
Selected-branch `strategy_recommendation.v1` explanations also surface repaired
link-capacity shortfall evidence when selected adjusted throughput remains below
required downlink volume, and executable validation checks those explanation
rows for stable IDs, numeric shortfall fields, typed requirement status,
branch-event counts/types, and combined source branch ID lists.
The checked standalone fixture keeps that selected-versus-alternative ranking
surface lintable without loading a full strategy artifact.

## Objective Satisfaction Report

`objective_satisfaction_report.v1` rows with partial, unmet,
candidate-available, or no-candidate-window statuses can be normalized into
`objective_satisfaction_review` operator-review rows and typed
`review_objective_satisfaction` Cadence import gates. Met, selected, and
no-requirement rows remain report evidence and are not added to review queues.
V1 campaign embedded objective-satisfaction reports use the same review/import
surface for non-passing objective rows with campaign-source provenance.
Executable validation checks report-level `model_limits` against
`CampaignPlanner.objective_satisfaction_model_limits/0`. The
report also emits top-level `model_limits` that mark it as a selected
planned-activity summary, not an executed-outcome or solver artifact.
Executable validation derives `objective_count` from the emitted objective rows.

## Objective Satisfaction Report Validation

`objective_satisfaction_report.v1` exports a nested row schema for selected
campaign objectives, including objective status, target IDs, required/candidate/
selected/satisfied counts, downlink-completion MB totals, and selected
candidate/contact/activity ID lists. Downlink-completion rows aggregate multiple
explicit objectives and match scoped station/scenario/time/data-volume
selectors before counting candidate or selected contacts; when an objective
declares both required contacts and required downlink volume, both dimensions
must be satisfied before the row reports `met`. The report schema includes
schema-visible `model_limits` for the planned, deterministic summary boundary.
Executable validation treats objective and target/activity/contact counts as
integers while leaving downlink MB totals numeric.

## Objective Tradeoff Report (V1)

`objective_tradeoff_report.v1` exports a nested tradeoff row schema for ranked
timeline comparison rows: scenario ID, score, score delta from the selected
timeline, activity count, optional selected observation/contact counts, score
terms, activity ID lists, and typed score-term key arrays. Standalone reports
can be normalized into `objective_tradeoff_review` operator-review rows and
typed `review_objective_tradeoff` Cadence import gates while preserving the
source tradeoff row. Executable validation treats optimizer candidate/selection
counts plus objective-tradeoff ranking, row rank, and activity/contact counts as
integers while objective scores and score deltas remain numeric, and checks
report-level `model_limits` against `CampaignPlanner.score_report_model_limits/0`.

## Objective Tradeoff Report (V3 Strategy)

`objective_tradeoff_report.v1` is embedded in V3 strategy artifacts over
branch-local score terms. Those rows preserve `branch_id`, selected status,
activity IDs, score deltas from the recommended branch, and the source
score-term map through `objective_tradeoff_review` and
`review_objective_tradeoff` handoff rows. Validation ties `ranking_count` to the
tradeoff row count, ties each row's `activity_count` to `activity_ids`, and
derives score-term keys from row score-term maps. Exported JSON Schema now
types those score-term maps as numeric `additionalProperties`, matching
executable validation and keeping quantitative tradeoff evidence visible to
schema-driven review tooling. V1 campaign embedded tradeoff reports also
promote ranked-timeline score deltas through the same handoff rows with
`campaign_plan.objective_tradeoff_report.tradeoffs` provenance.

## Ranking Comparison and Pareto Frontier Reports

`ranking_comparison_report.v1` exports pairwise ranked-scenario comparison rows
for search and what-if review: scenario ID, match/left-only/right-only status,
left/right ranks, rank delta, left/right objective values, value delta, and
winner-change metadata. It is an explainable comparison artifact, not an
external optimizer or solver result, and its top-level `model_limits` make that
no-solver boundary machine-readable. Executable validation treats left/right
ranks and signed rank deltas as integers while objective values and value deltas
remain numeric, and it now derives row count plus matched, left-only, right-only,
left, and right totals from emitted rows so stale comparison summaries fail
schema validation. Ranking input values accept clean numeric strings before
report emission, while malformed numeric strings remain missing numeric
evidence; validation also checks report-level `model_limits` against
`Optimizer.ranking_comparison_model_limits/0`. Ranking comparison reports can also be
normalized into `operator_review_package.v1` `ranking_comparison_review` rows so
import gates can review persisted search-result deltas without invoking a
solver. Cadence import manifests preserve those rows as typed
`review_ranking_comparison` gates with reason/source context, left and right
rank/value evidence, rank/value deltas, and the original
`source_ranking_comparison` row.
`pareto_frontier_report.v1` exports an explainable dominance summary for
already-supplied objective vectors: frontier IDs, dominated IDs, objective
directions, per-alternative objective values, and dominance links. It does not
run local search, generate alternatives, or wrap an external solver result; the
top-level `model_limits` declare those boundaries for import gates.
Executable validation derives alternative, frontier, and dominated totals plus
frontier/dominated ID lists from rows, validates dominance ID lists as stable
IDs, and derives `objective_count` from `objective_directions`; objective-vector
input maps accept clean numeric strings before report emission while malformed
numeric strings remain missing objective evidence, and emitted row
`objective_values` validate as numeric maps; it also checks report-level
`model_limits` against
`Optimizer.pareto_frontier_model_limits/0`.
Pareto frontier reports can be normalized into `operator_review_package.v1`
`pareto_frontier_review` rows so import gates can review branch dominance
context without invoking a solver. Cadence import manifests preserve the
frontier/dominated reason, source path, objective vector, dominance links, and
original `source_pareto_frontier` row as typed `review_pareto_frontier` gates.

## Score Term Report

`score_term_report.v1` exports nested score-term rows plus typed score-term key
arrays for deterministic scoring vocabulary review, with top-level
`model_limits` for the deterministic explainability and request-supplied-policy
boundary. Executable validation derives `row_count` and `score_term_keys` from
rows and checks report-level `model_limits` against
`CampaignPlanner.score_report_model_limits/0`. V3 strategy artifacts embed the same report over branch-local score
terms and carry `branch_id` through `score_term_review` and
`review_score_term` handoff rows. Standalone reports can be normalized into
`score_term_review` operator-review rows and typed `review_score_term` Cadence
import gates while preserving the source score-term row. V1 campaign embedded
score-term reports use the same review/import surface with
`campaign_plan.score_term_report.rows` provenance.

## Score Term Report Validation

`score_term_report.v1` exports a nested row schema for deterministic score-term
rows: stable row and scenario IDs, rank, term key, value, timeline score, and
selected status.
Executable validation treats ranking-comparison, Pareto-frontier, constraint,
and score-term summary counts plus score-term row ranks as integers while
leaving objective values, scores, thresholds, and deltas numeric.

## Constraint Report

`constraint_report.v1` exports a nested row schema for scenario constraint
checks: constraint ID, scenario ID, metric, operator, threshold, optional value
and score, violation severity, pass/fail/warning status, and schema-visible
`model_limits` copied from the producing constraint capability. Artifact metric
constraints can declare `severity: "warning"` so numeric threshold violations
become warning gates; missing or nil metric values remain failures. Campaign
and repair-local constraint reports are produced by
`OrbitalDynamics.Constraints.CampaignLocal` and can evaluate planning-grade
resource projection margin thresholds (`min_projected_storage_margin`,
`min_projected_downlink_margin`, and `min_projected_power_margin`) when a
`resource_projection_report.v1` is available, preserving spacecraft/resource
pressure context on warning or failed rows without treating the projection as a
high-fidelity resource simulator. They can likewise evaluate aggregate
fixed-rate link-capacity thresholds (`min_selected_capacity_utilization_fraction`,
`max_selected_downlink_shortfall_mb`, and `min_actual_completion_fraction`) from
`link_capacity_report.v1` without treating the report as a link-budget model.
The standalone
`study_results/constraint_report_v1.json` fixture covers deterministic
pass/fail/warning counts and the missing-value assumption used by artifact
metric constraints. Failed and warning rows can now be normalized into
`constraint_review` operator-review rows and typed `review_constraint` Cadence
import gates; passing rows are omitted from review/import queues. Executable
validation derives row count, aggregate status, and status counts from rows
while accepting explicit zero-valued status buckets in embedded campaign
reports. It also validates `model_limits` against the known limits of the
declared constraint report model for artifact-metric and campaign-local reports.
Artifact-metric constraint specs and campaign-local constraint maps accept clean
numeric-string thresholds before report generation, including nested
`value`/`threshold` forms; malformed artifact-metric thresholds remain invalid
constraint specs, while malformed campaign-local threshold strings remain
not-evaluated local constraints.
Campaign-local report inputs also normalize atom-keyed candidate, timeline,
resource-projection, and link-capacity rows and parse clean numeric-string row
metrics before evaluating the local constraint rows.
The exported `constraint_report.v1` JSON Schema mirrors that boundary with
conditional exact `model_limits` constraints for the known
`artifact_metric_threshold`, `campaign_planner_local_constraint_summary`, and
`campaign_repair_local_constraint_summary` models while leaving future
constraint models extensible.
`OrbitalDynamics.evaluate_artifact_metric_constraints/2` and
`OrbitalDynamics.artifact_metric_constraint_report/2` expose the same
artifact-only constraint behavior through the top-level public API.
`OrbitalDynamics.campaign_local_constraint_report/6` does the same for the
campaign-local row model, so callers do not need to depend on campaign planner
internals. For embedded campaign artifacts, `constraint_count` remains the
declared/evaluated constraint-set count and is not reduced to unique row IDs.
