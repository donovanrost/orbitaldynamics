# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Strategy schema-provider extraction.

Status:
Completed and verified.

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
Selected in `a27dfb35` and implemented in `5aa56ba5`. Added the 63-line
`StrategySchemaProviders` owner, merged its six lazy providers into the schema
property context, and retained recursive strategy-recommendation document
construction plus policy, negotiation, and scoped-context dependencies behind
explicit callbacks. The public `Schema` facade moved from 1,606 to 1,559 lines.

Verification:
- Exact comparison passed for all six provider keys and outputs, including
  callback-sensitive branch/event inputs and recursive recommendation output.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `StrategySchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,116 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Strategy schema-provider extraction, selected in `a27dfb35` and implemented in
`5aa56ba5`. The public `Schema` facade moved from 1,606 to 1,559 lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
