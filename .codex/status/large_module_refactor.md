# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-filter capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract schema-facing contact-filter capability and assumptions access into
`OrbitalDynamics.Schema.ContactFilterCapabilityContext` and import its focused
internal APIs into the Schema facade.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,498 lines.
- Nine private helpers repeatedly query ContactFilter capabilities for model
  limits, suppression metadata, station/capacity precedence and aliases, then
  assemble the report assumptions schema.
- The selected code has one responsibility: expose schema-facing
  contact-filter capability context and assumptions with stable ordering.
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
Schema timeline capability-context extraction, selected in `cefcd8d6` and
implemented in `dd182ce7`.
`schema.ex` moved from 6,525 to 6,498 lines; the dedicated
TimelineCapabilityContext owner is 34 lines.

Next candidate:
After this slice, re-rank the remaining schema capability/model-limit
responsibility clusters.

Blocked:
No.
