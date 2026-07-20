# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operational-readiness schema-provider extraction.

Status:
Completed and verified.

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
Selected in `7ceaedd3` and implemented in `11b69418`. Added the 95-line
`OperationalReadinessSchemaProviders` owner with six lazy readiness/evidence
providers, merged its registry context, and passed shared closures to
source-evidence and cadence-review owners. The public `Schema` facade moved
from 959 to 947 lines.

Verification:
- Exact comparison passed for all six readiness-provider keys and outputs using
  sentinel approval/rule schemas.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` ->
  `OperationalReadinessSchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,127 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Operational-readiness schema-provider extraction, selected in `7ceaedd3` and
implemented in `11b69418`. The public `Schema` facade moved from 959 to 947
lines.

Next candidate:
Re-rank the remaining public-facade clusters and select the next bounded
extraction.

Blocked:
No.
