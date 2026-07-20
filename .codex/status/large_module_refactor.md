# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move the strategy branch tradeoff/risk/recommendation/branch/event/explanation
builders and their private context assembler from the public `Schema` facade
into a new `StrategySchemaProviders` owner. Merge its six lazy providers into
the property context and pass document, policy, negotiation, and scoped-context
dependencies as callbacks.

Selection evidence:
- The public `Schema` facade remains 1,606 lines.
- Six strategy builders are referenced only by the property provider registry,
  and the context assembler is used only by branch/event within the cluster.
- Strategy-recommendation document construction can preserve recursive facade
  ownership through one explicit document callback.
- Policy, negotiation, and scoped-context dependencies can remain lazy through
  explicit callbacks.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Planning-analysis branch schema-provider expansion, selected in `2715158a` and
implemented in `08a9dcbf`. The public `Schema` facade moved from 1,619 to 1,606
lines.

Next candidate:
Implement and verify the selected strategy provider extraction, then re-rank
the remaining public-facade provider clusters.

Blocked:
No.
