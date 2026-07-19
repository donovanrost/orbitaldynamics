# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback outcome-value interpretation extraction.

Status:
Completed and pushed in `67cc2a83`.

Selected boundary:
Extract contact, station-throughput, observation, image-quality, maneuver, and
command feedback value interpretation plus weighted-average semantics into
`OrbitalDynamics.TimelineFeedback.OutcomeValue`.
Preserve the existing TimelineFeedback public API facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 3,776 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  RecommendationRiskContext, StationCalendar, LinkCapacity,
  ResourceProjection, and ContactAllocation.
- The selected helper family owns one normalized-row outcome interpretation
  responsibility used by feedback aggregates and model updates.
- Reconciliation, matching, grouping, demand, resource, target-priority,
  uncertainty, and artifact assembly remain outside this boundary.
- Existing public APIs, fallback precedence, terminal-status semantics,
  weighting, clamping, omission behavior, and deterministic output remain
  unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,913
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `886f98ea` passed
  for seven reconciliation reports plus operational-feedback outcomes covering
  every extracted value family, weighting, completion, and terminal status.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the extracted outcome owner.
- Static ownership checks confirm normalized-row outcome interpretation and
  weighted-average semantics live in the dedicated owner while grouping and
  artifact assembly remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback outcome-value interpretation extraction, selected in
`886f98ea` and implemented in `67cc2a83`.
`timeline_feedback.ex` moved from 3,776 to 3,675 lines; the dedicated outcome
owner is 204 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
