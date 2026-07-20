# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Planning-analysis branch schema-provider expansion.

Status:
Completed and pushed.

Selected boundary:
Move the branch-comparison row/source, score-term row, and branch-scoped
context builders from the public `Schema` facade into the existing
`PlanningAnalysisSchemaProviders` owner. Add the two registry providers and
route the strategy/review-table shared helper captures to public owner
functions.

Selection evidence:
- The public `Schema` facade remains 1,619 lines.
- Branch comparison and score term are planning-analysis registry providers
  already aligned with the existing owner.
- Branch-comparison source rows are shared only by the three review tables;
  branch-scoped context is shared only by strategy explanation and the three
  review property-provider tables.
- The entire cluster depends only on the stable-ID pattern and common schema
  primitives, so no facade callback is required.

Implementation:
Selected in `2715158a` and implemented in `08a9dcbf`.
`PlanningAnalysisSchemaProviders.build/1` now returns eight lazy providers,
adding branch-comparison and score-term rows, and exposes branch-comparison
source-row and branch-scoped-context helpers. `Schema` removes the four private
builders and two registry-local captures, then points strategy explanation and
all six review-table captures at the existing owner.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed both new provider outputs and both shared helper
  outputs exactly match the original builders.
- Xref reports the provider-map edge plus seven expected strategy/review-table
  helper edges from `Schema` to the expanded owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,115 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,619 to 1,606 lines; the focused
  owner grew from 68 to 112 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Planning-analysis branch schema-provider expansion, selected in `2715158a` and
implemented in `08a9dcbf`. The public `Schema` facade moved from 1,619 to 1,606
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
