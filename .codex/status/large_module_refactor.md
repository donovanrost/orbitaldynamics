# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Candidate-refresh JSON-property family extraction.

Status:
Implemented and verified.

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
- Added a 53-line `CandidateRefreshPropertyRouter` with the three mechanically
  moved clause bodies spanning eight related candidate-refresh contracts.
- Kept all three original parent clause heads, including both guarded lists, in
  place as ordered delegations.
- The parent router moved from 1,264 to 1,241 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all three moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the three intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,097 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Candidate-refresh JSON-property family extraction, selected in `e7af4d89` and
implemented in `f37766cb`. The parent router moved from 1,264 to 1,241 lines.

Next candidate:
Re-rank the adjacent campaign artifact and timeline-report families against a
cohesive facade provider extraction, preserving recursive parent routing where
campaign repair depends on timeline-transition properties.

Blocked:
No.
