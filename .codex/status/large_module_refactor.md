# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema link-capacity capability-context extraction.

Status:
Completed and pushed.

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
Added `OrbitalDynamics.Schema.LinkCapacityCapabilityContext`, which now owns
the five LinkCapacity capability lookups and the parameterized assumptions
schema assembly. `OrbitalDynamics.Schema` imports the single assumptions
builder used by its existing property-dispatch paths.
`schema.ex` moved from 6,361 to 6,326 lines; the dedicated owner is 41 lines.

Verification:
- Strict focused schema/communications baseline before extraction: 27 passed.
- Strict focused schema/communications suite after extraction: 27 passed.
- Strict full schema-export task plus adjacent validation fixtures: 12 passed.
- `mix xref callers OrbitalDynamics.Schema.LinkCapacityCapabilityContext`
  reports only `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed.
- Strict forced compile passed across 4,054 files.
- Implementation commit `03fdb865` pushed to `main`.

Behavior/schema changes:
None. Public facades, capability ordering, generated JSON Schema, validation
behavior, and checked-in exports remain unchanged.

Last completed slice:
Schema link-capacity capability-context extraction, selected in `af6d00c6`
and implemented in `03fdb865`.
`schema.ex` moved from 6,361 to 6,326 lines; the dedicated
LinkCapacityCapabilityContext owner is 41 lines.

Next candidate:
Inspect and rank the remaining contact-allocation capability/model-limit
responsibility cluster against other bounded Schema facade extractions.

Blocked:
No.
