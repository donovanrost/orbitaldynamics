# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Planning-analysis schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the six objective-satisfaction, objective-tradeoff, ranking-row,
ranking-winner, Pareto-row, and constraint-row provider builders from the
public `Schema` facade into a new `PlanningAnalysisSchemaProviders` owner.
Merge its lazy provider map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,959 lines after the property-routing
  extraction lane completed.
- These six contiguous, roughly 45-line private builders are referenced only
  by the property provider registry.
- They form a cohesive planning-analysis boundary and depend only on the
  stable-ID pattern plus common JSON-schema primitives.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `bb50e34c` and implemented in `e765efdb`.
The new `PlanningAnalysisSchemaProviders.build/1` returns six lazy provider
closures for objective, ranking, Pareto, and constraint rows. `Schema` removes
the six registry-local captures and private builders, then merges the focused
provider map into its existing property context without changing the public
facade.

Verification:
- Strict focused schema/validation baseline and final post-change suites both
  passed: 359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact six
  keys and produces outputs exactly equal to the original builders.
- Xref reports one runtime edge from `Schema` to the new provider owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,108 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,959 to 1,917 lines; the new focused
  owner is 68 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Planning-analysis schema-provider extraction, selected in `bb50e34c` and
implemented in `e765efdb`. The public `Schema` facade moved from 1,959 to 1,917
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
