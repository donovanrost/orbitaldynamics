# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation/schema-lifecycle JSON-property family extraction.

Status:
Selected; implementation pending.

Selected boundary:
Extract the five contiguous validation evidence, validation assessment, schema
validation, schema migration, and lint-report clauses from
`JsonSchemaPropertyRouter` into a validation/schema-lifecycle family owner.
Keep the parent router's exact guarded and literal clause heads/order as
delegations.

Selection evidence:
- The parent router remains 1,146 lines across 76 contract-family clauses.
- Five adjacent clauses form a roughly 110-line validation/schema-lifecycle
  boundary covering twelve related contracts.
- The bodies already delegate through focused validation, schema, and lint
  dispatchers and share only lazy providers, stable-ID context, and fallback.
- No recursive parent callback or cross-family property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Result artifact JSON-property family extraction, selected in `13b52e7b` and
implemented in `13fa8422`. Result-family ownership moved into a 55-line module.

Next candidate:
Implement and verify the selected validation/schema-lifecycle split, then
re-rank strategy/planning-analysis or communications cohorts.

Blocked:
No.
