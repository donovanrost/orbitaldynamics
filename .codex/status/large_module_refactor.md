# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Execution-state schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the spacecraft-state-estimate, maneuver-execution-delta, realized
spacecraft-state, and realized-snapshot-metadata provider builders from the
public `Schema` facade into a new `ExecutionStateSchemaProviders` owner. Merge
its lazy provider map into the existing property context.

Selection evidence:
- The public `Schema` facade remains 1,813 lines.
- These four builders are referenced only by the property provider registry.
- They form a cohesive accepted/realized execution-state boundary spanning
  estimate, maneuver delta, realized state, and snapshot metadata schemas.
- They depend only on the stable-ID pattern and common numeric/string-array
  primitives, so no facade callback is required.
- A provider-map owner preserves lazy evaluation and removes both registry
  entries and implementation details from the public facade.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Station-calendar schema-provider extraction, selected in `5ec99bb8` and
implemented in `9b22678f`. The public `Schema` facade moved from 1,887 to 1,813
lines.

Next candidate:
Implement and verify the selected execution-state provider extraction, then
re-rank the remaining public-facade provider clusters.

Blocked:
No.
