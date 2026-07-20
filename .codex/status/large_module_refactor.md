# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy schema-provider extraction.

Status:
Completed and verified.

Selected boundary:
Move policy action-rule, decision, decision-evidence, rule-match, escalation,
and scoped-downlink schema builders from the public `Schema` facade into a new
`PolicySchemaProviders` owner. Build one lazy policy context, merge its registry
providers, and pass shared closures to downstream owners while retaining
recursive top-level policy-document construction as one facade callback.

Selection evidence:
- The public `Schema` facade remains 1,176 lines.
- Five policy/scoped builders are registry providers and the decision-evidence
  builder is consumed only by extracted row-provider owners.
- Rule-match, escalation, action-rule, evidence, and scoped shapes already have
  focused direct owners and share the stable-ID pattern.
- Recursive policy-decision document construction can remain facade-owned and
  lazy through one explicit callback.

Implementation:
Selected in `33e14d05` and implemented in `a90c0166`. Added the 53-line
`PolicySchemaProviders` owner with six lazy policy/scoped closures, merged its
registry providers, and passed shared closures to downstream owners while
retaining recursive policy-decision document construction as one facade
callback. The public `Schema` facade moved from 1,176 to 1,161 lines.

Verification:
- Exact comparison passed for all six policy-provider keys and outputs using a
  sentinel policy-decision document.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `PolicySchemaProviders` edge.
- Strict forced compile passed with warnings as errors: 4,123 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Policy schema-provider extraction, selected in `33e14d05` and implemented in
`a90c0166`. The public `Schema` facade moved from 1,176 to 1,161 lines.

Next candidate:
Re-rank the remaining public-facade provider clusters and select the next
bounded extraction.

Blocked:
No.
