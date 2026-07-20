# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Filter/resource/contention JSON-property family extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Ground-network communications JSON-property family extraction, selected in
`eef80e1a` and implemented in `7a87bb6f`. The parent router moved from 1,021 to
914 lines.

Next candidate:
Implement and verify the selected filter/resource/contention split, then fold
the adjacent objective/optimizer clauses into the planning family.

Blocked:
No.
