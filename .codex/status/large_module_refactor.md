# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-artifact JSON-property extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the realized-state-snapshot, realized-activity, and
maneuver-recommendation property bodies from `JsonSchemaPropertyRouter` into a
new `ExecutionArtifactPropertyRouter`. Keep the parent router's exact literal
clause heads/order as delegations.

Selection evidence:
- Only eight domain property bodies remain inline in the 615-line parent
  router, excluding its global lighting special case and fallback.
- These three bodies form a roughly 55-line realized-execution/maneuver
  artifact boundary.
- A dedicated owner needs only the shared provider/context/fallback support.
- No recursive parent callback, embedded-schema callback, or cross-family
  property lookup is required.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Contact-planning JSON-property extraction, selected in `eebf7804` and
implemented in `fd610981`. The parent router moved from 641 to 615 lines.

Next candidate:
Implement and verify the selected execution-artifact extraction, then re-rank
the remaining inline router routes against the public `Schema` facade's
provider-helper boundaries.

Blocked:
No.
