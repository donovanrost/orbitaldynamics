# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Reference/policy JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the six leading activity-template, policy bundle/decision, capability
catalog, accepted-state, and manifest-field-reference clauses from
`JsonSchemaPropertyRouter` into a reference/policy family owner. Extract the
router's provider lookup, context lookup, and fallback mechanics into shared
internal support so later family splits do not couple back to private router
state. Keep the parent router's exact clause heads and order as delegating
facade clauses.

Selection evidence:
- The original target facades are now 164 to 524 lines and the split target
  tests are no longer monolithic; `schema.ex` is 1,959 lines.
- The new 1,326-line property router is cohesive but spans 76 unrelated
  contract families, making family-level navigation the next target-area risk.
- Its first six clauses form a contiguous reference/policy boundary and depend
  only on shared context/fallback mechanics plus existing focused dispatchers.
- A small shared support owner makes the family extraction one-way and provides
  a reusable boundary for later router splits.

Implementation:
- Added a 68-line `ReferencePolicyPropertyRouter` with the six mechanically
  moved clause bodies.
- Added a 29-line `JsonSchemaPropertySupport` owner for lazy provider lookup,
  context values, and field-hint/stable-ID fallback.
- Kept all six original parent clause heads in place as ordered delegations.
- The parent router moved from 1,326 to 1,264 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all six moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the six intended family edges and shared support
  edges from the parent router.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,096 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Reference/policy JSON-property family extraction, selected in `44cfeda6` and
implemented in `bbc8fc3e`. The parent router moved from 1,326 to 1,264 lines.

Next candidate:
Re-rank the contiguous candidate-refresh/timeline clauses against a cohesive
facade provider-family extraction, reusing `JsonSchemaPropertySupport` without
changing parent clause order.

Blocked:
No.
