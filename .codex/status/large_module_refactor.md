# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report lifecycle/summary expansion.

Status:
Selected; implementation pending.

Selected boundary:
Move lifecycle-state/activity-state sources, precondition/diff/dependency/
publication summaries, transition row/summary, and dependency-impact row
builders from the public `Schema` facade into the existing
`TimelineReportSchemaProviders` owner. Expand its lazy provider map while
passing registry/default-property/capability metadata as explicit callbacks.

Selection evidence:
- The public `Schema` facade remains 1,106 lines.
- Four builders are registry providers and six are consumed only by extracted
  operator/cadence row owners or other members of this graph.
- The graph shares timeline capability/model metadata, registry contracts,
  default-property fallback, and focused core/base providers.
- All cross-node recursion can remain lazy within one owner map.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report base schema-provider extraction, selected in `149a346a` and
implemented in `f2a24879`. The public `Schema` facade moved from 1,126 to 1,106
lines.

Next candidate:
Implement and verify the selected timeline-report lifecycle/summary expansion,
then re-rank the remaining facade clusters.

Blocked:
No.
