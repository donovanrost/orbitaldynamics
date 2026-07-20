# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the contiguous candidate-diff report, candidate-diff family, and
candidate-refresh auxiliary clauses from `JsonSchemaPropertyRouter` into a
candidate-refresh family owner. Keep the parent router's three exact clause
heads and order as delegating facade clauses, and reuse
`JsonSchemaPropertySupport` for lazy providers, context values, and fallback.

Selection evidence:
- The parent router remains 1,264 lines across 76 contract-family clauses.
- The next three clauses are a contiguous 47-line candidate-refresh boundary
  covering nine related contracts through one existing focused dispatcher.
- They have no recursion or cross-family owner calls and depend only on
  `JsonSchemaPropertySupport` plus existing candidate-refresh model limits.
- The split can therefore be mechanical while preserving the parent route table
  and its precedence.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Reference/policy JSON-property family extraction, selected in `44cfeda6` and
implemented in `bbc8fc3e`. The parent router moved from 1,326 to 1,264 lines.

Next candidate:
Implement and verify the selected candidate-refresh family split, then re-rank
the adjacent campaign/timeline families against facade provider extraction.

Blocked:
No.
