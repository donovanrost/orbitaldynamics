# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Provider-counteroffer JSON-property family routing.

Status:
Selected; implementation pending.

Selected boundary:
Move the four-contract provider-counteroffer property body from
`JsonSchemaPropertyRouter` into the existing
`GroundNetworkPropertyRouter`. Keep the parent router's exact guarded clause
head/order as a delegation.

Selection evidence:
- Only three domain property bodies remain inline in the 581-line parent
  router, excluding its global lighting special case and fallback.
- The roughly 25-line counteroffer body covers report, review, import
  readiness, and plan-impact contracts tied to provider/ground-network
  operations.
- It fits the existing ground-network owner and its shared
  provider/context/fallback support.
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
Execution-artifact JSON-property extraction, selected in `94e3e7b8` and
implemented in `b3ee5b97`. The parent router moved from 615 to 581 lines.

Next candidate:
Implement and verify the selected counteroffer family move, then re-rank the
approval and callback-bearing candidate-refresh bodies against the public
`Schema` facade's provider-helper boundaries.

Blocked:
No.
