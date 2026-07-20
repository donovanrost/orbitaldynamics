# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Resource-planning schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the resource-projection row/flow, suppressed-candidate, and
resource-summary-row provider builders plus the private suppression-reason
combiner from the public `Schema` facade into a new
`ResourcePlanningSchemaProviders` owner. Merge its lazy provider map into the
existing property context.

Selection evidence:
- The public `Schema` facade remains 1,768 lines.
- The four schema builders are referenced only by the property provider
  registry; the suppression-reason combiner is used only inside this cluster.
- They form a cohesive resource planning/filtering boundary spanning
  projection, flow, suppression, and summary rows.
- Source-window, approval/policy, and filter-reason dependencies can remain
  lazy through explicit callbacks.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `aedaf961` and implemented in `b981188a`.
The new `ResourcePlanningSchemaProviders.build/2` returns four lazy provider
closures for resource projection, projection flow, suppressed candidate, and
resource summary rows, and owns suppression-reason normalization. `Schema`
removes the four registry-local captures and five private builders, then
passes source-window, policy, and filter-reason dependencies as callbacks.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact four
  keys and produces outputs exactly equal to the original helper composition,
  including lazy flow wiring and normalized suppression reasons.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,112 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,768 to 1,729 lines; the new focused
  owner is 77 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Resource-planning schema-provider extraction, selected in `aedaf961` and
implemented in `b981188a`. The public `Schema` facade moved from 1,768 to 1,729
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
