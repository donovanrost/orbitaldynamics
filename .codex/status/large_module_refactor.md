# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Reference/policy JSON-property family extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Schema JSON-property router extraction, selected in `db973fb7` and implemented
in `b7196e25`. `schema.ex` moved from 3,194 to 1,959 lines.

Next candidate:
Implement and verify the selected reference/policy family split, then re-rank
the next cohesive property-router family against facade provider extraction.

Blocked:
No.
