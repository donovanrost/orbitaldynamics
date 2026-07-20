# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-allocation capability callback routing.

Status:
Selected; implementation not started.

Selected boundary:
Add a whole-capability accessor to the existing
`OrbitalDynamics.Schema.ContactAllocationCapabilityContext` and route the
contact-allocation property-dispatch callback through it.
Keep contact-allocation property dispatch, row/capacity-pack schema
construction, assumptions composition, validation, and all public facades in
their current owners.

Selection evidence:
- `schema.ex` remains the dominant hotspot at 6,188 lines.
- One lazy property-dispatch callback still queries
  `ContactAllocation.capabilities/0` directly even though all capability
  projections and assumptions already live in ContactAllocationCapabilityContext.
- A focused accessor and function capture complete that family's schema-facing
  capability ownership while preserving callback timing and per-call
  evaluation.
- Exact capability values and ordering, generated JSON Schema, validation
  results, and checked-in exports must remain unchanged.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended.

Last completed slice:
Schema filter suppression-capability routing, selected in `e2eb0cfb` and
implemented in `f659fc87`.
`schema.ex` moved from 6,187 to 6,188 lines and no longer directly queries
ContactFilter or ResourceFilter capabilities.

Next candidate:
Re-rank the remaining Schema capability/model-limit responsibility clusters.

Blocked:
No.
