# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection activity delivery evidence extraction.

Status:
Completed and pushed in `d80e997a`.

Selected boundary:
Extract collection/delivery timestamps, planned and actual latency, latency
requirement margin and status, basis selection, and normalized completion
fraction into `OrbitalDynamics.ResourceProjection.ActivityDeliveryEvidence`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,827 lines, fourth
  behind Schema, Timeline, and MissionPlan.Activity and ahead of
  StationCalendar, ContactAllocation, TimelineFeedback, and
  RecommendationRiskContext.
- The selected helper family owns one activity delivery/progress evidence
  responsibility used during resource-flow row projection.
- Resource flow roll-forward, pressure classification, approval policy,
  contact allocation, station-capacity evidence, and report aggregation remain
  outside this boundary.
- Existing public APIs, row fields, numeric-string acceptance, omission
  behavior, ordering, and report/schema artifacts remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,910
  files.
- Focused ResourceProjection coverage passed: 49 tests.
- Adjacent operator-review and validation-fixture coverage passed: 7 tests.
- Exact public old/new comparison against selection commit `299d93df` passed
  for six report and flow-summary artifacts covering direct and metadata
  aliases, numeric strings, derived latency, actual/planned basis selection,
  margins, status, and completion fraction.
- `mix xref callers` reports only the ResourceProjection facade as a runtime
  caller of the extracted evidence owner.
- Static ownership checks confirm activity delivery/progress projection and
  helper calculations live in the dedicated owner while resource roll-forward
  remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection activity delivery evidence extraction, selected in
`299d93df` and implemented in `d80e997a`.
`resource_projection.ex` moved from 3,827 to 3,720 lines; the dedicated
evidence owner is 117 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
