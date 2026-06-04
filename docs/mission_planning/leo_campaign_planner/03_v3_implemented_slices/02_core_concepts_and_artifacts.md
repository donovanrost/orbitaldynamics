# Core Concepts and Artifacts

The V3 concepts live with the planner:

- `MissionState`: current constellation state snapshot.
- `WhatIfScenario`: branch input with probability, events, and policy overrides.
- `PlanBranch`: branch result containing a candidate plan, V2 repair result,
  operational timeline rows with required operator actions, score terms,
  resource impacts, warnings, risks, assumptions, and provenance.
- `StrategyRecommendation`: selected branch, ranked alternatives, tradeoffs,
  remaining risks, and approval requirements.
- `OperatorReview` packages: artifact-only rows that normalize approvals,
  warnings, risk explanations, strategy recommendations, recommendation
  tradeoff dimensions, branch ranking/Pareto comparisons, branch
  contact/resource suppressions, contact allocations, branch command-window
  reviews with station-calendar reservation evidence, and branch resource
  projections for downstream operator
  review/import tooling without Cadence API writes. V2 plan-delta review rows
  additionally flatten
  source/replacement Cadence import status, type, external ID, contract, and
  presence flags from activity context so an import queue can see whether a
  repaired replacement is already import-ready; the preserved `source_delta`
  evidence itself is exported as nested `plan_delta.v1` and validated on
  operator-review rows, Cadence import rows, and preserved `source_review_row`
  copies. Approval review/import rows apply the same pattern to preserved
  `source_requirement` evidence through nested `approval_requirement.v1`
  schema and executable validation, and preserved source policy decision or
  escalation evidence is executable-validated for classification and routing
  identity before adapter handoff. Contact and resource suppression source
  objects are likewise exported and validated as suppressed-candidate evidence,
  preserving source-window and station identity checks across review/import
  queues. Review/import `source_*` snapshots are preserved as source evidence
  rather than required to be complete nested artifacts, while stable-ID-bearing
  fields such as source activity, timeline, station, maneuver, provider, and
  calendar identifiers plus timeline diff status remain schema-visible and
  executable-validated. Cadence import rows and their embedded
  `source_review_row` copies apply the same lightweight source-evidence checks
  before adapter handoff.
- `CadenceImport` manifests: artifact-only import tables that turn V1 proposed
  contacts plus embedded operational-timeline review gates, V2 plan-delta
  review rows, and V3 strategy branch recommendations plus strategy
  operator-review rows, timeline feedback, station-contention, command-window,
  station-calendar, link-capacity, resource-projection, and policy-escalation record/review rows into
  deterministic adapter-facing actions and status counts. Standalone prior-plan
  `planned_activity.v1` rows and direct operational-timeline rows can also
  replay command/contact/observation/attitude/maneuver feedback into V3 branch-local
  refresh, preserving source path and trust boundary without requiring a review
  wrapper first. Remaining
  operator-review row families are carried as generic review manifest rows with
  `source_review_row` preserved while the review/approval boundary remains
  outside the artifact.
  Command-window review/import rows preserve dependency and exclusivity
  stable-ID arrays from their source activity so command prerequisites and
  mutually exclusive windows remain visible to adapter gates.
  Timeline-feedback review/import rows preserve the planned timeline identity,
  dependency/exclusivity stable-ID arrays, and source planned/realized activity
  rows so adapter gates can correlate provider feedback without reopening the
  source schedule.
  Direct operational-timeline rows and operational-timeline review/import rows
  with dependency or exclusivity integrity issues also replay into V3
  `timeline_integrity_feedback` branch events, giving strategy comparison an
  explicit risk signal for broken prerequisites, cycles, ordering violations,
  and mutually exclusive schedule overlaps. Branch-comparison rows, strategy
  operator-review rows, and Cadence strategy import rows flatten those affected
  activity/timeline IDs and exclusivity groups so adapters can route the issue
  without reopening raw branch events. Maneuver execution-uncertainty branches
  expose the same style of strategy handoff rollups for affected
  activity/timeline/maneuver IDs, uncertainty status/source, typed nested
  uncertainty fields, and max timing or delta-v 3-sigma evidence, while
  recommendation risk rows preserve the threshold, source, and trust-boundary
  evidence that triggered the review.
- `StrategicScoringPolicy`: campaign-level objective weights for mission value,
  coverage, revisit, latency, downlink completion, fuel preservation, schedule
  stability, asset balancing, priority commitments, risk, approval load, and
  branch probability. Branch comparison rows expose `raw_score`,
  `branch_probability`, `expected_score`, feedback score adjustment, feedback
  risk types, and contact/observation/maneuver/command/station-throughput
  feedback factors, where branch probability is an independent likelihood or
  confidence multiplier in `[0, 1]`.
- `ApprovalPolicy`: classifies branch recommendations as `auto_approvable`,
  `operator_review_required`, or `blocked_by_policy`, with backward-compatible
  coarse limits plus action-specific rules.
- `OperationalFeedback`: thin planned-vs-realized calibration inputs for future
  contact, observation, maneuver, command/health-check, and station-throughput
  tuning.
