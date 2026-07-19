# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback operational-feedback grouping extraction.

Status:
Completed and pushed in `06f6111d`.

Selected boundary:
Extract operational-feedback row eligibility, stable grouping-key
normalization, weighted numeric grouping, and deterministic text grouping into
`OrbitalDynamics.TimelineFeedback.FeedbackAggregation`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,675 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of LinkCapacity,
  StationCalendar, Manifest, ResourceProjection, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one aggregation-boundary responsibility shared by
  operational-feedback outputs: identity-gated row eligibility and
  deterministic keyed numeric/text reduction.
- Reconciliation, outcome interpretation, downlink demand, target priority,
  resource overrides, uncertainty, provenance, and artifact assembly remain
  outside this boundary.
- Existing exclusion semantics, stable-ID rules, feedback weights, clamping,
  duplicate text selection, key ordering, and empty-map behavior remain
  unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,918
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence-import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `25f2362c` passed
  for seven operational-feedback samples covering weighted averages, clamping,
  deterministic text selection, atom/string keys, input-order changes, zero
  weights, explicit exclusions, and malformed identities.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted feedback-aggregation owner.
- Static ownership checks confirm identity-gated eligibility, stable grouping
  keys, and numeric/text aggregation live in the dedicated owner while outcome
  and domain-specific feedback responsibilities remain outside it.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback operational-feedback grouping extraction, selected in
`25f2362c` and implemented in `06f6111d`.
`timeline_feedback.ex` moved from 3,675 to 3,606 lines; the dedicated
feedback-aggregation owner is 86 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
