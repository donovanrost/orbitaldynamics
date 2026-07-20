# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation batch schema-provider expansion.

Status:
Completed and verified.

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
Selected in `f595c7b7` and implemented in `08b4a9b0`. Expanded the existing
`ValidationSchemaProviders` owner from four to five lazy providers and retained
recursive validation-report document construction behind one explicit
callback. The public `Schema` facade moved from 1,513 to 1,511 lines.

Verification:
- Exact comparison passed for all five validation provider keys and outputs,
  including the callback-built batch entry.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `ValidationSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,118 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation batch schema-provider expansion, selected in `f595c7b7` and
implemented in `08b4a9b0`. The public `Schema` facade moved from 1,513 to 1,511
lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
