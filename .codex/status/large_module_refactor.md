# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceProjection pressure classification extraction.

Status:
Completed and pushed in `b034086a`.

Selected boundary:
Extract projection/flow pressure-type derivation, availability pressure
classification, status selection, first-pressure event metadata, and per-row
pressure kinds into
`OrbitalDynamics.ResourceProjection.PressureClassification`.
Preserve the existing ResourceProjection public API facade.

Selection evidence:
- Live re-ranking places `resource_projection.ex` at 3,629 lines, fourth behind
  Schema, Timeline, and MissionPlan.Activity and ahead of TimelineFeedback,
  ContactAllocation, RecommendationRiskContext, OrbitalDynamics, Manifest,
  LinkCapacity, and StationCalendar.
- The selected family owns one interpretation responsibility reused by report
  summaries, routing maps, warnings, policy risks, and row metadata:
  deterministic classification of numerical and availability pressure.
- Projection math, activity resource effects, risk-row construction, policy
  decisions, provenance, and artifact assembly remain outside this boundary.
- Existing pressure vocabulary, sorting/deduplication, status precedence,
  first-event field selection, omission behavior, and deterministic output
  remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,922
  files.
- Focused ResourceProjection coverage passed: 49 tests.
- Adjacent operator-review ResourceProjection coverage passed: 9 tests.
- Exact public old/new comparison against selection commit `bab45b76` passed
  for eight resource states and three public outputs per state: report, flow
  report, and flow summary.
- `mix xref callers` reports only the ResourceProjection facade as a runtime
  caller of the extracted pressure-classification owner.
- Static ownership checks confirm pressure vocabulary, type derivation, status
  precedence, first-event selection, and per-row pressure kinds live in the
  dedicated owner while projection math and artifact assembly remain in the
  facade.
- Strict compilation proved an unchanged private fallback clause unreachable
  from its only call site; removing that dead clause restored the
  warnings-as-errors gate without changing reachable behavior.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
ResourceProjection pressure classification extraction, selected in `bab45b76`
and implemented in `b034086a`.
`resource_projection.ex` moved from 3,629 to 3,447 lines; the dedicated
pressure-classification owner is 192 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
