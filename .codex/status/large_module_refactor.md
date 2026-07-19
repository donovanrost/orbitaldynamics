# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection margin and warning extraction.

Status:
Completed and pushed in `24a8fe53`.

Selected boundary:
Extract starting storage/battery interpretation, storage/downlink/battery
projection math, battery roll-forward, and deterministic projection warnings
into `OrbitalDynamics.ResourceProjection.MarginProjection`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,720 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  LinkCapacity, StationCalendar, Manifest, ContactAllocation, and
  RecommendationRiskContext.
- The selected family owns one numerical interpretation responsibility reused
  by aggregate and per-activity projections: initial resource state, bounded
  margins, overflow/shortfall/overuse values, and their ordered warnings.
- Activity normalization, delivery evidence, resource-effect eligibility,
  capacity-source resolution, pressure classification, policy decisions, and
  artifact assembly remain outside this boundary.
- Existing numeric guards, fallback margins, clamping, warning text/order,
  omission behavior, and deterministic output remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,917
  files.
- Focused ResourceProjection coverage passed: 49 tests.
- Adjacent resource-projection operator-review coverage passed: 9 tests.
- Exact public old/new comparison against selection commit `28bb1c49` passed
  for report, flow-report, and flow-summary outputs across four resource states
  covering nominal projection, overflow/shortfall/overuse, fallback margins,
  unavailable resources, suppressed/incompatible activities, and thermal
  pressure.
- `mix xref callers` reports only the ResourceProjection facade as a runtime
  caller of the extracted margin-projection owner.
- Static ownership checks confirm initial-state interpretation, margin math,
  battery roll-forward, and warning semantics live in the dedicated owner
  while activity and artifact responsibilities remain in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection margin and warning extraction, selected in `28bb1c49` and
implemented in `24a8fe53`.
`resource_projection.ex` moved from 3,720 to 3,629 lines; the dedicated
margin-projection owner is 170 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
