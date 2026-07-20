# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema operational-readiness validation routing cleanup.

Status:
Selected; implementation not started.

Selected boundary:
Complete the existing
`OrbitalDynamics.Schema.OperationalReadinessValidation` extraction by routing
schema contract clauses and callback tables directly to that owner and
removing facade pass-through wrappers.
Preserve all `OrbitalDynamics.Schema` public facades and validation output.

Selection evidence:
- Live hotspot refresh places `schema.ex` at 6,764 lines with 600 private
  functions, by far the largest remaining primary-goal module.
- Operational-readiness validation logic already has a focused owner, but the
  facade retains twelve one-hop wrappers used by contract clauses and callback
  tables.
- The selected code has one responsibility: route readiness reports,
  summaries, quality-gate rows, and embedded readiness contexts to the existing
  validation owner.
- Contract lookup, required-field checks, callback-table composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact issue ordering, paths, messages, required-field behavior, callback
  wiring, public validation results, and schema exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
RecommendationRiskContext resource-filter extraction, selected in `acd03893`
and implemented in `461abe2f`.
`recommendation_risk_context.ex` moved from 374 to 246 lines; the dedicated
ResourceFilter owner is 131 lines.

Next candidate:
After this slice, continue re-ranking `schema.ex` private responsibility
clusters before returning to smaller facades.

Blocked:
No.
