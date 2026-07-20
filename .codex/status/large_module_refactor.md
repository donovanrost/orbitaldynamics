# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation batch schema-provider expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move the schema-validation batch-entry builder from the public `Schema` facade
into the existing `ValidationSchemaProviders` owner. Expand its lazy provider
map and pass the recursively constructed validation-report document as one
explicit callback.

Selection evidence:
- The public `Schema` facade remains 1,513 lines.
- The batch-entry builder is referenced only by the property provider registry
  and belongs with the four validation providers already extracted.
- `SchemaValidationReportJsonSchema` already owns the batch-entry shape.
- Recursive top-level document construction can remain facade-owned and lazy
  through one explicit callback.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Execution-review row schema-provider extraction, selected in `0037d37c` and
implemented in `6477c809`. The public `Schema` facade moved from 1,524 to 1,513
lines.

Next candidate:
Implement and verify the selected validation-provider expansion, then re-rank
the remaining public-facade provider clusters.

Blocked:
No.
