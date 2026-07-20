# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema timeline capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract schema-facing timeline capability/model-limit access into
`OrbitalDynamics.Schema.TimelineCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,525 lines.
- Nine private helpers repeatedly normalize Timeline/TimelineFeedback
  capabilities into model limits, rejection reasons/actions, transition
  decisions, integrity issue types, precondition statuses, and required
  operator actions.
- The selected code has one responsibility: expose schema-facing timeline
  capability context with stable string/atom/list ordering.
- Importing those internal APIs preserves the existing unqualified call sites
  and evaluation order. Property-dispatch composition, other
  artifact-family validation, JSON Schema generation, and all public routing
  remain outside the boundary.
- Exact model-limit conversion, capability values and ordering, validation
  results, generated JSON Schema, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema optional-readiness validation routing cleanup, selected in `af32df23`
and implemented in `37099809`.
`schema.ex` moved from 6,535 to 6,525 lines, leaving no readiness validation
pass-through wrappers.

Next candidate:
After this slice, re-rank the remaining schema capability/model-limit
responsibility clusters.

Blocked:
No.
