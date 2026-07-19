# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ContactAllocation reduced-capacity packing extraction.

Status:
Completed and pushed in `54011624`.

Selected boundary:
Extract default capacity-requirement policy normalization, reduced-station
capacity group packing, fractional-fit decisions, row promotion/deferral, and
capacity-requirement evidence into
`OrbitalDynamics.Communications.ContactAllocation.CapacityPacking`.
Preserve the existing ContactAllocation public API facade.

Selection evidence:
- Live re-ranking places `contact_allocation.ex` at 3,593 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of
  RecommendationRiskContext, OrbitalDynamics, Manifest, LinkCapacity,
  StationCalendar, TimelineFeedback, and ResourceProjection.
- The selected family owns one deterministic allocation-policy responsibility:
  fitting contention-ordered contacts within declared reduced station capacity
  and recording the resulting row/group evidence.
- Contact normalization, station filtering, contention resolution, approval
  policy, provider counteroffers, report summaries, and returned-contact
  assembly remain outside this boundary.
- Existing option precedence and validation, contact ordering, fractional-fit
  tolerance, row status/reason transitions, evidence fields, omission behavior,
  and deterministic output remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,924
  files.
- Focused ContactAllocation coverage passed: 70 tests.
- Adjacent campaign-planner and candidate-refresh capacity-pack coverage
  passed: 8 tests.
- Exact public old/new comparison against selection commit `75c6e6fe` passed
  for five allocation states and three public outputs per state: allocation,
  allocation summary, and capacity-pack summary; the invalid-default error path
  also matched.
- `mix xref callers` reports only the ContactAllocation facade as a runtime
  caller of the extracted capacity-packing owner.
- Static ownership checks confirm option normalization, group fitting,
  row decisions, promotion/deferral, and requirement evidence live in the
  dedicated owner while allocation orchestration and report assembly remain in
  the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ContactAllocation reduced-capacity packing extraction, selected in `75c6e6fe`
and implemented in `54011624`.
`contact_allocation.ex` moved from 3,593 to 3,308 lines; the dedicated
capacity-packing owner is 304 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
