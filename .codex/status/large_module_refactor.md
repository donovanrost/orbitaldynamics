# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Policy schema-provider extraction.

Status:
Selected; implementation pending.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Source-evidence schema-provider extraction, selected in `b9b5302f` and
implemented in `30b37935`. The public `Schema` facade moved from 1,216 to 1,176
lines.

Next candidate:
Implement and verify the selected policy provider extraction, then re-rank the
remaining public-facade clusters.

Blocked:
No.
