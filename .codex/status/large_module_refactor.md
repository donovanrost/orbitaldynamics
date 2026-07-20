# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity capability-context extraction.

Status:
Selected; implementation not started.

Selected boundary:
Extract schema-facing link-capacity capability and assumptions access into
`OrbitalDynamics.Schema.LinkCapacityCapabilityContext` and import its focused
internal API into the Schema facade.
Preserve all `OrbitalDynamics.Schema` public facades, JSON Schema output, and
validation behavior.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,361 lines.
- Six private helpers repeatedly query LinkCapacity capabilities for station
  availability aliases/precedence, provider directions, station capacity
  paths, and source capacity paths, then assemble report/summary assumptions.
- The selected code has one responsibility: expose schema-facing
  link-capacity capability context and parameterized assumptions.
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
Schema resource-filter capability-context extraction, selected in `20626595`
and implemented in `4c1eab32`.
`schema.ex` moved from 6,451 to 6,361 lines; the dedicated
ResourceFilterCapabilityContext owner is 99 lines.

Next candidate:
Re-rank the remaining schema capability/model-limit responsibility clusters.

Blocked:
No.
