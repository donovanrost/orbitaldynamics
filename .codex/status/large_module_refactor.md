# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema resource-filter capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract schema-facing resource-filter capability and assumptions access into
`OrbitalDynamics.Schema.ResourceFilterCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,451 lines.
- Sixteen private helpers repeatedly query ResourceFilter capabilities for
  model limits, policy/margin/availability aliases, direction metadata,
  identity fields, suppression/review statuses, then assemble the assumptions
  schema.
- The selected code has one responsibility: expose schema-facing
  resource-filter capability context and assumptions with stable ordering.
- The only generic schema dependency is already public as
  `CommonJsonSchema.string_array/0`.
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
Schema contact-filter capability-context extraction, selected in `262e24ae`
and implemented in `817355a0`.
`schema.ex` moved from 6,498 to 6,451 lines; the dedicated
ContactFilterCapabilityContext owner is 56 lines.

Next candidate:
Re-rank the remaining schema capability/model-limit responsibility clusters.

Blocked:
No.
