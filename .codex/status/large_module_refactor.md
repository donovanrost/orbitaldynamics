# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move operational-readiness gate/evidence, quality-gate row, cadence readiness
and resource-projection evidence properties, and battery-handoff property
builders from the public `Schema` facade into a new
`OperationalReadinessSchemaProviders` owner. Build one lazy readiness context
and pass shared closures to source-evidence and cadence-review owners.

Selection evidence:
- The public `Schema` facade remains 959 lines.
- Three builders are registry providers and the remaining three feed only
  extracted source-evidence/cadence-review owners.
- The cluster shares readiness capability and stable-ID/common fragments.
- Approval and policy-rule dependencies can preserve laziness through explicit
  callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report lifecycle/summary expansion, selected in `d0512f10` and
implemented in `8ad4a5c6`. The public `Schema` facade moved from 1,106 to 959
lines.

Next candidate:
Implement and verify the selected readiness provider extraction, then re-rank
the remaining facade clusters.

Blocked:
No.
