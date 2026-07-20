# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-diff schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network schema-provider extraction, selected in `721cb8f6` and
implemented in `440e5739`. The public `Schema` facade moved from 1,729 to 1,648
lines.

Next candidate:
Implement and verify the selected candidate-diff provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
