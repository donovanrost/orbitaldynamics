# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation capability-context extraction.

Status:
Completed and pushed.

Selected boundary:
Extract schema-facing ContactAllocation capability lookups, model limits, and
five summary-assumptions builders into
`OrbitalDynamics.Schema.ContactAllocationCapabilityContext`.
Import the six focused internal APIs still needed by the Schema facade.
Keep contact-allocation row/capacity-pack schema construction, property
dispatch, validation routing, and public facades in `OrbitalDynamics.Schema`.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,326 lines.
- The contiguous cluster contains 15 repeated
  `ContactAllocation.capabilities/0` lookups, one model-limit projection, and
  five assumptions builders that consume only those lookups.
- The selected code has one responsibility: expose schema-facing
  ContactAllocation capability context for the report and its summary
  artifacts.
- Importing the model-limit and five assumptions APIs preserves existing
  unqualified call sites and evaluation order. Row/capacity-pack JSON Schema
  construction, property dispatch, validators, and other artifact families
  remain outside the boundary.
- Exact atom-to-string conversion, capability values and ordering, generated
  JSON Schema, validation results, and checked-in exports must remain
  unchanged.

Implementation:
Added `OrbitalDynamics.Schema.ContactAllocationCapabilityContext`, which now
owns the 15 ContactAllocation capability lookups, model-limit projection, and
five summary-assumptions builders. `OrbitalDynamics.Schema` imports only the
six focused APIs used by its existing row and property-dispatch composition.
`schema.ex` moved from 6,326 to 6,201 lines; the dedicated owner is 138 lines.

Verification:
- Strict focused contact-allocation/export baseline before extraction:
  25 passed.
- The same strict focused suite after extraction: 25 passed.
- Strict full schema-export task plus adjacent communications, fixture,
  Cadence-import, and validation coverage: 19 passed.
- `mix xref callers
  OrbitalDynamics.Schema.ContactAllocationCapabilityContext` reports only
  `lib/orbital_dynamics/schema.ex (export)`.
- `git diff --check` passed; no checked-in schema export changed.
- Strict forced compile passed across 4,055 files.
- Implementation commit `4e12f391` pushed to `main`.

Behavior/schema changes:
None. Public facades, atom-to-string conversion, capability ordering,
generated JSON Schema, validation behavior, and checked-in exports remain
unchanged.

Last completed slice:
Schema contact-allocation capability-context extraction, selected in
`906526ce` and implemented in `4e12f391`.
`schema.ex` moved from 6,326 to 6,201 lines; the dedicated
ContactAllocationCapabilityContext owner is 138 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
