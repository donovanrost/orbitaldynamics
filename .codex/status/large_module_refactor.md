# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Timeline report lifecycle/summary expansion.

Status:
Completed and verified.

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
Selected in `d0512f10` and implemented in `8ad4a5c6`. Expanded
`TimelineReportSchemaProviders` from five to 17 lazy providers, moving the
lifecycle/summary graph and three timeline handoff-property builders into the
owner while retaining registry/default-property/capability metadata as
explicit callbacks. The public `Schema` facade moved from 1,106 to 959 lines.

Verification:
- Provider registration contains the expected 17 timeline-report keys and does
  not invoke callbacks during context construction.
- Focused schema/validation suite passed: 359 tests.
- Full checked-in schema export, including the recursive timeline summaries,
  regenerated with no diff.
- Runtime xref retains one direct `Schema` -> `TimelineReportSchemaProviders`
  edge.
- Strict forced compile passed with warnings as errors: 4,126 files.
- `JsonSchemaPropertyRouter` remains an ordered 76-head facade.

Behavior/schema changes:
None intended. Parent clause heads/order, dispatch-owner calls, provider
laziness, field-hint fallback, stable-ID decoration, public `Schema`, and
checked-in exports must remain unchanged.

Last completed slice:
Timeline report lifecycle/summary expansion, selected in `d0512f10` and
implemented in `8ad4a5c6`. The public `Schema` facade moved from 1,106 to 959
lines.

Next candidate:
Re-rank the remaining public-facade clusters and select the next bounded
extraction.

Blocked:
No.
