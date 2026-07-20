# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Filter/resource/contention JSON-property family extraction.

Status:
Implemented and verified.

Selected boundary:
Extract the three contiguous contact/resource filter, resource projection, and
contact contention clauses from `JsonSchemaPropertyRouter` into a
filter/resource/contention family owner. Keep the parent router's exact guarded
clause heads/order as delegations.

Selection evidence:
- The parent router remains 914 lines across 76 contract-family clauses.
- Three adjacent clauses form a roughly 70-line operational filtering/resource
  boundary covering seven related contracts.
- The bodies already delegate through focused filter, projection, and
  contention dispatchers with shared lazy providers/context/fallback.
- No recursive parent callback or cross-family property lookup is required;
  resource projection additionally uses the existing validation owner.

Implementation:
- Added an 80-line `FilterResourcePropertyRouter` with three mechanically moved
  filter/resource/contention clause bodies spanning seven contracts.
- Kept all guarded parent clause heads in place as ordered delegations.
- Reused shared lazy provider/context/fallback support and moved the
  resource-validation alias with its owning route.
- The parent router moved from 914 to 864 lines.

Verification:
- Strict pre-change baseline and post-change schema/validation suite: 359 tests
  passed in each run.
- AST comparison confirmed all three moved bodies are exact and all 76 parent
  clause heads remain in their original order.
- Full schema export regenerated 121 contract schemas and the bundle with no
  checked-in schema diff.
- `mix xref trace` confirms the three intended family edges.
- Formatting, `git diff --check`, and bounded source/schema diff review passed.
- Strict compile passed for 4,104 files with warnings as errors.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Filter/resource/contention JSON-property family extraction, selected in
`dc58ba33` and implemented in `054c5eb0`. The parent router moved from 914 to
864 lines.

Next candidate:
Fold the adjacent objective/optimizer clauses into the existing
`StrategyPlanningPropertyRouter`, preserving parent clause order.

Blocked:
No.
