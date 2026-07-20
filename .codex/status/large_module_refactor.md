# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report base schema-provider extraction.

Status:
Selected; implementation pending.

Selected boundary:
Move operational-timeline row, candidate-rejection source, timeline
precondition, integrity-issue, and timeline-diff row builders from the public
`Schema` facade into a new `TimelineReportSchemaProviders` owner. Merge its lazy
providers, keep core dependencies direct, and pass the shared timeline
capability callback once.

Selection evidence:
- The public `Schema` facade remains 1,126 lines.
- Three builders are registry providers and the rejection/integrity helpers
  feed only timeline/report composition.
- The five builders share one timeline capability callback and otherwise depend
  only on common fragments and the extracted timeline core owner.
- Public focused helpers can preserve lazy callback timing for the remaining
  lifecycle/summary layer.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline core schema-provider extraction, selected in `34f8879f` and
implemented in `a9fa9e71`. Nine builders moved to the focused owner while the
public `Schema` facade remained 1,126 lines due to explicit callback wiring.

Next candidate:
Implement and verify the selected timeline report base extraction, then move
the remaining lifecycle/summary graph into the same owner.

Blocked:
No.
