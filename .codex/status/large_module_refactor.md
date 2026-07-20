# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-diff schema-provider extraction.

Status:
Completed and pushed.

Selected boundary:
Move the candidate-refresh scoped-context, source-window-lineage, invalidated
candidate, and candidate-diff-row builders from the public `Schema` facade
into a new `CandidateDiffSchemaProviders` owner. Merge its four lazy registry
providers into the property context and route the three review-table lineage
captures to the new owner.

Selection evidence:
- The public `Schema` facade remains 1,648 lines.
- These four builders form one candidate-diff/scoped-context dependency chain
  and all four are property-registry providers.
- Source-window lineage is additionally captured by each review-row provider
  table; it can become one public owner function.
- The entire cluster depends only on the stable-ID pattern, so no facade
  callback is required.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Selected in `5fe7d9ee` and implemented in `36b93af7`.
The new `CandidateDiffSchemaProviders.build/1` returns four lazy provider
closures for candidate-refresh scoped context, source-window lineage,
invalidated candidate, and candidate-diff row schemas. `Schema` removes the
four registry-local captures and private builders, merges the provider map,
and points all three review tables at the owner's public lineage helper.

Verification:
- Strict focused schema/validation baseline and post-change suites both passed:
  359 tests, 0 failures.
- Direct comparison confirmed the extracted provider map has the exact four
  keys and produces outputs exactly equal to the original helper composition;
  the shared lineage helper output also matches exactly.
- Xref reports the provider-map edge plus three expected review-table lineage
  edges from `Schema` to the new owner.
- Schema export regenerated 121 schemas plus the bundle with no checked-in
  artifact diff.
- Strict full compile passed for 4,114 files with warnings as errors.
- Formatting, diff checks, and bounded two-file review passed.
- The public `Schema` facade shrank from 1,648 to 1,629 lines; the new focused
  owner is 45 lines.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-diff schema-provider extraction, selected in `5fe7d9ee` and
implemented in `36b93af7`. The public `Schema` facade moved from 1,648 to 1,629
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters.

Blocked:
No.
