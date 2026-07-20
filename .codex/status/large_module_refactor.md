# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation capability-context extraction.

Status:
Selected; implementation not started.

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
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema link-capacity capability-context extraction, selected in `af6d00c6`
and implemented in `03fdb865`.
`schema.ex` moved from 6,361 to 6,326 lines; the dedicated
LinkCapacityCapabilityContext owner is 41 lines.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
