# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report base schema-provider extraction.

Status:
Completed and verified.

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
Selected in `149a346a` and implemented in `f2a24879`. Added the 89-line
`TimelineReportSchemaProviders` owner with five lazy base providers and public
focused helpers, merged its registry context, and routed downstream base
dependencies through the owner. The public `Schema` facade moved from 1,126 to
1,106 lines.

Verification:
- Exact comparison passed for all five timeline-report base provider keys and
  outputs.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export regenerated with no diff.
- Runtime xref shows one direct `Schema` -> `TimelineReportSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,126 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report base schema-provider extraction, selected in `149a346a` and
implemented in `f2a24879`. The public `Schema` facade moved from 1,126 to 1,106
lines.

Next candidate:
Expand the timeline-report owner with the remaining lifecycle/summary graph.

Blocked:
No.
