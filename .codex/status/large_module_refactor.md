# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Validation/schema-lifecycle JSON-property family extraction.

Status:
Implemented and verified.

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
- Added a 116-line `ValidationPropertyRouter` with the five mechanically moved
  validation/schema-lifecycle clause bodies spanning twelve contracts.
- Kept all literal and guarded parent clause heads in place as ordered
  delegations.
- Reused shared lazy provider/context/fallback support without a parent
  callback.
- The parent router moved from 1,146 to 1,071 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all five moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the five intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,101 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Validation/schema-lifecycle JSON-property family extraction, selected in
`28e22361` and implemented in `5e2b8c72`. The parent router moved from 1,146 to
1,071 lines.

Next candidate:
Re-rank the adjacent strategy/planning-analysis and communications cohorts,
preferring another broad mechanical family boundary.

Blocked:
No.
