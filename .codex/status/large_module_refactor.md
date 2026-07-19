# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
TimelineFeedback throughput reconciliation ownership extraction.

Status:
Completed and pushed in `86340697`.

Selected boundary:
Move reconciliation throughput and data-volume evidence, denominator
selection, deltas, completion fractions, and required downlink assembly into
the existing `OrbitalDynamics.TimelineFeedback.Throughput` owner. Preserve the
existing report and row assembly facade.

Selection evidence:
- Live re-ranking places `timeline_feedback.ex` at 4,099 lines, behind Timeline
  and MissionPlan.Activity but ahead of the remaining Manifest facade.
- The selected reconciliation-row fields form one planned-versus-realized
  throughput responsibility and depend only on planned and realized row maps.
- The fraction helper has no consumers outside this boundary. Generic delta
  math remains in the facade for thermal and maneuver comparisons, while
  maneuver evidence, success outcomes, execution uncertainty, operational-
  feedback exclusion, and report aggregation remain with their current owners.
- Existing public report APIs and artifact row shapes remain unchanged.

Verification:
- Strict test-environment compile passed with warnings as errors across 3,898
  files.
- Focused TimelineFeedback coverage passed: 73 tests.
- Adjacent operator-review, Cadence import, and contact-feedback contract
  coverage passed: 79 tests.
- Exact public old/new comparison against selection commit `cfd577ed` passed
  for five reports covering matched, mismatched, planned-only, realized-only,
  and mixed rows with divergent throughput and data-volume evidence.
- `mix xref callers` reports only the TimelineFeedback facade as a runtime
  caller of the Throughput owner.
- Static ownership checks confirm denominator selection, deltas, and completion
  fractions live in Throughput while generic delta math remains in the facade.
- `git diff --check` passed.

Behavior/schema changes:
None. This is a facade-preserving production ownership extraction.

Last completed slice:
TimelineFeedback throughput reconciliation ownership extraction, selected in
`cfd577ed` and implemented in `86340697`.
`timeline_feedback.ex` moved from 4,099 to 4,070 lines; the Throughput owner
moved from 221 to 263 lines.

Next candidate:
Re-rank the live largest-module set and select the next cohesive ownership
boundary.

Blocked:
No.
