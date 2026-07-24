# 9. Constraints and Scoring

Status: **implemented** (core), with **partial**, **near-term**, **later**, and **out of scope** items called out below.

## Implemented

### Core building blocks

- `Constraint` behaviour, `Constraints.ArtifactMetric`, report rankings, campaign scoring policies, V2 churn penalties, V3 strategic scoring weights, risk indicators, approval-load scoring, and recommendation explanations.
- Artifact metric constraints declare their supported metrics, operators, and artifact-only evaluation limits.

### Constraint reports

- Result artifacts emit schema-validated `constraint_report.v1` rows with:
  - deterministic pass/fail/warning counts;
  - per-scenario constraint rows;
  - explicit missing-value assumptions;
  - schema-visible model limits checked against the declared report model's capability metadata;
  - row-derived status/count validation;
  - exported JSON Schema conditional exact `model_limits` constraints for known artifact-metric and campaign-local constraint models;
  - a checked-in standalone constraint-report fixture for compatibility checks.

### Top-level public APIs

- `OrbitalDynamics.evaluate_artifact_metric_constraints/2`, `OrbitalDynamics.artifact_metric_constraint_report/2`, and `OrbitalDynamics.campaign_local_constraint_report/6` expose the reusable artifact-metric and campaign-local constraint behavior through top-level public APIs.

### Campaign-local (V1/V2 planner) constraints

- `Constraints.CampaignLocal` declares the supported campaign constraint keys and known limits behind V1/V2 planner constraint rows.
- V1/V2 planner-local constraints include:
  - max-timeline-activity;
  - minimum-duration;
  - eclipse-avoidance;
  - planning-grade resource projection margin constraints: `min_projected_storage_margin`, `min_projected_downlink_margin`, `min_projected_power_margin`;
  - aggregate fixed-rate link-capacity constraints: `min_selected_capacity_utilization_fraction`, `max_selected_downlink_shortfall_mb`, `min_actual_completion_fraction`.
- These accept legacy scalar or boolean values plus `{value, severity}`, `{threshold, severity}`, or `{enabled, severity}` maps, so local violations can route as warning rows with:
  - spacecraft/resource-pressure context preserved from `resource_projection_report.v1`;
  - link-capacity context preserved from `link_capacity_report.v1`.

### Review and import routing

- Failed and warning constraint-report rows normalize into `constraint_review` operator-review rows and typed `review_constraint` Cadence import gates, while passing rows stay out of the review queue.

### Score-term reports

- V1 campaign artifacts emit `score_term_report.v1` rows that flatten ranked timeline score terms into reusable schema-validated score-term rows, and now lift embedded score-term and objective-tradeoff rows into `score_term_review`, `objective_tradeoff_review`, `review_score_term`, and `review_objective_tradeoff` queues with campaign-source provenance, with executable `model_limits` validation against `CampaignPlanner.score_report_model_limits/0`.
- `campaign_plan.v1` declares both `score_term_report.v1` and
  `objective_tradeoff_report.v1` as optional direct nested contracts, so schema
  consumers can discover the same explainability reports enforced at runtime.
- V2 repair artifacts emit the same `score_term_report.v1` and `objective_tradeoff_report.v1` contracts over repaired activity score, churn, and schedule-move terms.
- V3 strategy artifacts now emit branch-level `score_term_report.v1` rows for expected score, mission value, resource, feedback, risk, approval-load, and schedule-stability terms, carrying `branch_id` through operator-review and Cadence-import handoff, plus `objective_tradeoff_report.v1` rows that compare branch scores against the recommended branch while preserving the same branch ID and score-term map.
- Standalone score-term and objective-tradeoff reports normalize into `score_term_review` and `objective_tradeoff_review` operator-review rows plus typed `review_score_term` and `review_objective_tradeoff` Cadence import gates, while preserving source scoring rows.
- Derived score-term pressure recommendation rows preserve source-exact risk,
  objective, target, scenario, branch, and ground-station routing plus the
  latency-objective flag and collection, product, payload, and instrument
  identity; start/end bounds; contact and downlink demand; and maximum/planned
  latency across operator review, direct Cadence import, and review-derived
  import copies. Missing or stale derived routing, timing, or demand is rejected
  while paired legacy omission remains compatible; the evidence cannot approve
  an import, write to Cadence, or execute a schedule.

### Objective-tradeoff reports

- V1 campaign artifacts emit `objective_tradeoff_report.v1` rows that expose ranked-timeline score-term deltas and selected activity IDs.

### Objective-satisfaction reports

- V1 `target_commitments` are typed inline campaign rows whose target IDs,
  candidate/selected counts and durations, selected activity IDs, and status are
  reconciled with candidate activities, selected activities, and matching
  objective-satisfaction target rows.
- `objective_satisfaction_report.v1` rows summarize target coverage, downlink completion, and per-target commitment status from selected activities, with:
  - downlink-completion rows aggregating multiple scoped station/scenario/time/data-volume objectives instead of reporting only the first objective;
  - contact-count plus data-volume requirements treated as conjunctive when both are declared.
- Partial, unmet, candidate-available, and no-candidate-window objective rows normalize into `objective_satisfaction_review` rows and typed `review_objective_satisfaction` Cadence import gates, while satisfied rows stay out of the review queue.
- The report exposes schema-visible `model_limits` for its selected planned-activity summary boundary, with executable validation against `CampaignPlanner.objective_satisfaction_model_limits/0`.

### Strategy recommendations (V3)

- V3 embedded and standalone `strategy_recommendation.v1` artifacts now expose schema-visible `status` plus deterministic tradeoff deltas for coverage, revisit, latency, downlink completion, fuel preservation, asset balance, resource score, feedback adjustment, risk, approval load, and schedule stability, alongside expected score and mission value.
- Selected recommendation explanation rows now mirror the branch-local objective-satisfaction evidence for priority commitments, downlink completion, coverage, revisit, and collection latency, including stable target ID lists and deterministic count/ratio fields.
- Executable validation now checks strategy-recommendation tradeoff, risk, approval, and explanation row contents, including stable IDs, numeric-or-boolean risk values, and the repaired link-capacity shortfall fields.
- Branch-level `risk_indicators` are now validated against the same typed risk-row contract before recommendation selection.

### Explainability model limits

- Score-term, objective-tradeoff, branch-comparison, ranking-comparison, and Pareto-frontier reports now emit schema-visible `model_limits` arrays for their deterministic explainability and no-solver/no-autonomous-execution boundaries.
- Result-artifact `scenario_rankings` now expose `ResultSet.Report` model-limit metadata for artifact-only ranking.

### Branch-comparison feedback

- Branch-comparison rows expose contact, observation, maneuver, command, and station-throughput feedback factors plus feedback risk types when those factors affect branch scoring, with executable validation enforcing integer branch totals, row ranks, and row count summaries separately from numeric score/margin fields.

### Recommendation explanations

- Recommendation explanations now name the selected branch's first resource-projection pressure activity with peak storage-overflow and downlink-shortfall context, or name `spacecraft_unavailable` pressure with spacecraft and resource-pressure status/type evidence when availability suppresses projected activity effects, plus the repair reason for selected strategic additions, and distinguish data-volume downlink gaps from contact-count downlink gaps in branch risk explanations.
- When the recommended branch's repaired link-capacity report still has a downlink-volume shortfall, recommendation explanations also include required downlink volume, selected adjusted throughput, shortfall, requirement status, and selected contact IDs.
- Recommendation risk-driver explanations now preserve stable station, spacecraft, and target IDs plus numeric-or-boolean risk values, so availability and scoped policy evidence remains visible without unpacking branch risks.

## Partial

- Constraints now have reusable artifact-level result reports with explicit violation severity.
- V1/V2 planner-local constraints are owned by a reusable campaign-local constraint module that can emit warning rows, so numeric threshold violations can be routed as warnings while missing/nil metric values remain failures.
- Artifact-metric and campaign-local constraint thresholds also normalize clean numeric strings before deterministic evaluation, while malformed artifact-metric thresholds stay invalid and malformed campaign-local thresholds stay not evaluated.
- Campaign-local candidate, timeline, resource-projection, and link-capacity row inputs are atom/string-key tolerant and parse clean numeric-string metrics at the constraint boundary.
- They also have:
  - fail/warning review/import gates;
  - objective-satisfaction review/import gates;
  - score-term and objective-tradeoff review/import gates;
  - V1/V2/V3 score-term rows;
  - V2/V3 objective tradeoff rows;
  - V3 recommendation tradeoffs over the main strategic score dimensions.
- Cadence import rows that preserve top-level `source_objective_satisfaction`, `source_objective_tradeoff`, `source_score_term`, `source_constraint_row`, or communications/resource source pressure rows replay the same branch pressure without nested review rows.
- **Caveat** — score-term records are still not shared across every workflow.

## Near-term

- Broaden scored-objective explanation rows across branch-local repair contexts.
- Continue extracting any new planner constraint types into reusable report modules instead of private planner-only maps.

## Later

- Constraint dependency graphs.
- Soft/hard constraint composition.
- Multi-objective Pareto summaries.
- Policy libraries.
- Calibration from operational outcomes.

## Out of scope

- Hiding policy decisions in unexplainable optimizer weights.
