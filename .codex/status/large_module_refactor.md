# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback activity-state artifact extraction.

Status:
Completed and pushed in `0e23963f`.

Selected boundary:
Extract compact activity-state artifact assembly, primary-row selection,
status/count summaries, review evidence, and realized trust-boundary
derivation into `OrbitalDynamics.TimelineFeedback.ActivityState`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,606 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of ContactAllocation,
  RecommendationRiskContext, OrbitalDynamics, Manifest, LinkCapacity,
  StationCalendar, and ResourceProjection.
- The selected family owns one public artifact responsibility: reducing a
  reconciled planned/realized activity pair into its compact activity-state
  contract and review/trust-boundary evidence.
- Reconciliation, realized-input normalization, lifecycle-state derivation,
  operational-feedback aggregation, evidence extraction, and row construction
  remain outside this boundary.
- Existing input validation, reconciliation semantics, artifact fields,
  omission behavior, counts, review rules, and deterministic output remain
  unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,923
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent Timeline coverage passed: 109 tests.
- Adjacent activity-state operator-review, schema-contract,
  candidate-refresh, and campaign-planner coverage passed: 25 tests.
- Exact public old/new comparison against selection commit `3575f21a` passed
  for six output scenarios covering matched, approval-regression, unmatched,
  planned-only, realized-only, and timing-threshold states, plus all three
  public error paths.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted activity-state owner.
- Static ownership checks confirm artifact assembly, primary-row selection,
  counts, review evidence, and trust-boundary derivation live in the dedicated
  owner while validation, reconciliation, and lifecycle derivation remain in
  the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback activity-state artifact extraction, selected in `3575f21a`
and implemented in `0e23963f`.
`timeline_feedback.ex` moved from 3,606 to 3,452 lines; the dedicated
activity-state owner is 183 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
